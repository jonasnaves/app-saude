import { Request, Response } from 'express';
import { AppDataSource } from '../config/database';
import { Consultation } from '../models/Consultation';
import { MedicalRecord } from '../models/MedicalRecord';
import { geminiService } from '../services/gemini.service';
import { audioService } from '../services/audio.service';
import { authMiddleware, AuthRequest } from '../middleware/auth.middleware';
import { z } from 'zod';

const analyzeIncrementalSchema = z.object({
  transcript: z.string(),
  previousInsights: z.string().optional(),
});

const generateSummarySchema = z.object({
  consultationId: z.string().uuid(),
});

export const startRecording = async (req: AuthRequest, res: Response) => {
  try {
    const consultationRepository = AppDataSource.getRepository(Consultation);
    const consultation = consultationRepository.create({
      userId: req.user!.id,
      startedAt: new Date(),
    });

    await consultationRepository.save(consultation);

    res.json({ consultationId: consultation.id });
  } catch (error) {
    res.status(500).json({ error: 'Erro ao iniciar gravação' });
  }
};

export const analyzeIncremental = async (req: AuthRequest, res: Response) => {
  try {
    const data = analyzeIncrementalSchema.parse(req.body);
    const analysis = await geminiService.getIncrementalAnalysis(
      data.transcript,
      data.previousInsights || ''
    );

    res.json(analysis);
  } catch (error) {
    if (error instanceof z.ZodError) {
      return res.status(400).json({ error: 'Dados inválidos' });
    }
    res.status(500).json({ error: 'Erro ao analisar transcrição' });
  }
};

export const generateSummary = async (req: AuthRequest, res: Response) => {
  try {
    const data = generateSummarySchema.parse(req.body);
    const consultationRepository = AppDataSource.getRepository(Consultation);
    const medicalRecordRepository = AppDataSource.getRepository(MedicalRecord);

    const consultation = await consultationRepository.findOne({
      where: { id: data.consultationId, userId: req.user!.id },
    });

    if (!consultation) {
      return res.status(404).json({ error: 'Consulta não encontrada' });
    }

    if (!consultation.transcript) {
      return res.status(400).json({ error: 'Transcrição não disponível' });
    }

    const summary = await geminiService.getClinicalSummary(consultation.transcript);

    const medicalRecord = medicalRecordRepository.create({
      consultationId: consultation.id,
      anamnesis: summary.anamnesis,
      physicalExam: summary.physicalExam,
      diagnosisSuggestions: summary.diagnosisSuggestions,
      conduct: summary.conduct,
    });

    await medicalRecordRepository.save(medicalRecord);

    consultation.endedAt = new Date();
    await consultationRepository.save(consultation);

    res.json({
      medicalRecord: {
        id: medicalRecord.id,
        anamnesis: medicalRecord.anamnesis,
        physicalExam: medicalRecord.physicalExam,
        diagnosisSuggestions: medicalRecord.diagnosisSuggestions,
        conduct: medicalRecord.conduct,
      },
    });
  } catch (error) {
    if (error instanceof z.ZodError) {
      return res.status(400).json({ error: 'Dados inválidos' });
    }
    res.status(500).json({ error: 'Erro ao gerar resumo' });
  }
};

export const updateTranscript = async (req: AuthRequest, res: Response) => {
  try {
    const { consultationId, transcript } = req.body;

    if (!consultationId || !transcript) {
      return res.status(400).json({ error: 'consultationId e transcript são obrigatórios' });
    }

    const consultationRepository = AppDataSource.getRepository(Consultation);
    const consultation = await consultationRepository.findOne({
      where: { id: consultationId, userId: req.user!.id },
    });

    if (!consultation) {
      return res.status(404).json({ error: 'Consulta não encontrada' });
    }

    consultation.transcript = transcript;
    await consultationRepository.save(consultation);

    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: 'Erro ao atualizar transcrição' });
  }
};

export const getConsultations = async (req: AuthRequest, res: Response) => {
  try {
    const consultationRepository = AppDataSource.getRepository(Consultation);
    const consultations = await consultationRepository.find({
      where: { userId: req.user!.id },
      relations: ['medicalRecord'],
      order: { createdAt: 'DESC' },
    });

    res.json(consultations);
  } catch (error) {
    res.status(500).json({ error: 'Erro ao buscar consultas' });
  }
};

export const getConsultation = async (req: AuthRequest, res: Response) => {
  try {
    const { id } = req.params;
    const consultationRepository = AppDataSource.getRepository(Consultation);
    const consultation = await consultationRepository.findOne({
      where: { id, userId: req.user!.id },
      relations: ['medicalRecord'],
    });

    if (!consultation) {
      return res.status(404).json({ error: 'Consulta não encontrada' });
    }

    res.json(consultation);
  } catch (error) {
    res.status(500).json({ error: 'Erro ao buscar consulta' });
  }
};

export const processAudioChunk = async (req: AuthRequest, res: Response) => {
  try {
    const { consultationId, audioData, textChunk } = req.body;

    if (!consultationId) {
      return res.status(400).json({ error: 'consultationId é obrigatório' });
    }

    const consultationRepository = AppDataSource.getRepository(Consultation);
    const consultation = await consultationRepository.findOne({
      where: { id: consultationId, userId: req.user!.id },
    });

    if (!consultation) {
      return res.status(404).json({ error: 'Consulta não encontrada' });
    }

    let transcript = '';

    if (audioData) {
      // Processar chunk de áudio
      transcript = await audioService.processAudioChunk(
        {
          data: audioData,
          mimeType: 'audio/pcm;rate=16000',
          timestamp: Date.now(),
        },
        consultationId
      );
    } else if (textChunk) {
      // Processar chunk de texto (transcrição já feita no cliente)
      transcript = await audioService.processTextChunk(textChunk);
    } else {
      return res.status(400).json({ error: 'audioData ou textChunk é obrigatório' });
    }

    // Atualizar transcrição no banco
    consultation.transcript = transcript;
    await consultationRepository.save(consultation);

    // Verificar se deve fazer análise incremental
    const shouldAnalyze = audioService.shouldTriggerAnalysis(transcript.length);
    let analysis = null;

    if (shouldAnalyze) {
      try {
        analysis = await geminiService.getIncrementalAnalysis(transcript, '');
      } catch (error) {
        console.error('Error in incremental analysis:', error);
      }
    }

    res.json({
      transcript,
      analysis,
      shouldAnalyze,
    });
  } catch (error) {
    console.error('Error processing audio chunk:', error);
    res.status(500).json({ error: 'Erro ao processar chunk de áudio' });
  }
};

