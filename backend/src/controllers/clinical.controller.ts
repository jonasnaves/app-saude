import { Request, Response } from 'express';
import { WhisperService } from '../services/whisper.service';
import { OpenAIService } from '../services/openai.service';
import { ConsultationDBService } from '../services/consultation-db.service';
import { PatientDBService } from '../services/patient-db.service';

const whisperService = new WhisperService();
const openaiService = new OpenAIService();
const consultationDB = new ConsultationDBService();
const patientDB = new PatientDBService();

/**
 * POST /api/clinical/transcribe-chunk
 * Recebe um chunk de áudio e retorna a transcrição incremental
 */
export const transcribeChunk = async (req: Request, res: Response) => {
  try {
    const { audioData, format, consultationId } = req.body;

    if (!audioData) {
      return res.status(400).json({ error: 'audioData é obrigatório' });
    }

    if (!consultationId) {
      return res.status(400).json({ error: 'consultationId é obrigatório' });
    }

    // Transcrever chunk usando Whisper
    const transcribedText = await whisperService.transcribeFromBase64(
      audioData,
      format || 'webm'
    );

    // Buscar transcrição atual do banco
    const consultation = await consultationDB.getConsultationById(consultationId);
    if (!consultation) {
      return res.status(404).json({ error: 'Consulta não encontrada' });
    }

    // Acumular transcrição
    const previousTranscript = consultation.transcript || '';
    const fullTranscript = previousTranscript
      ? `${previousTranscript} ${transcribedText}`
      : transcribedText;
    
    // Atualizar transcrição no banco
    await consultationDB.updateTranscript(consultationId, fullTranscript);

    res.json({
      transcript: transcribedText,
      fullTranscript: fullTranscript,
    });
  } catch (error: any) {
    console.error('Erro ao transcrever chunk:', error);
    res.status(500).json({
      error: 'Erro ao transcrever áudio',
      message: error.message,
    });
  }
};

/**
 * POST /api/clinical/analyze-incremental
 * Analisa a transcrição e retorna anamnese, prescrição e perguntas sugeridas
 */
export const analyzeIncremental = async (req: Request, res: Response) => {
  try {
    const { transcript, previousInsights, consultationId } = req.body;

    if (!transcript) {
      return res.status(400).json({ error: 'transcript é obrigatório' });
    }

    // Atualizar transcrição completa no banco se consultationId fornecido
    if (consultationId) {
      await consultationDB.updateTranscript(consultationId, transcript);
    }

    // Analisar usando OpenAI
    const analysis = await openaiService.analyzeIncremental(
      transcript,
      previousInsights
    );

    res.json(analysis);
  } catch (error: any) {
    console.error('Erro ao analisar incrementalmente:', error);
    res.status(500).json({
      error: 'Erro ao analisar transcrição',
      message: error.message,
    });
  }
};

/**
 * POST /api/clinical/generate-summary
 * Gera resumo clínico completo da consulta
 */
export const generateSummary = async (req: Request, res: Response) => {
  try {
    const { consultationId, transcript } = req.body;

    let finalTranscript = transcript;

    // Se consultationId fornecido, usar transcrição acumulada do banco
    if (consultationId && !transcript) {
      const consultation = await consultationDB.getConsultationById(consultationId);
      finalTranscript = consultation?.transcript || '';
    }

    if (!finalTranscript) {
      return res
        .status(400)
        .json({ error: 'transcript ou consultationId é obrigatório' });
    }

    const summary = await openaiService.generateClinicalSummary(
      finalTranscript
    );

    res.json({
      medicalRecord: summary,
    });
  } catch (error: any) {
    console.error('Erro ao gerar resumo:', error);
    res.status(500).json({
      error: 'Erro ao gerar resumo clínico',
      message: error.message,
    });
  }
};

/**
 * GET /api/clinical/transcript/:consultationId
 * Retorna a transcrição completa de uma consulta
 */
export const getTranscript = async (req: Request, res: Response) => {
  try {
    const { consultationId } = req.params;
    const consultation = await consultationDB.getConsultationById(consultationId);

    if (!consultation) {
      return res.status(404).json({ error: 'Consulta não encontrada' });
    }

    res.json({
      transcript: consultation.transcript || '',
      consultation: consultation,
    });
  } catch (error: any) {
    console.error('Erro ao obter transcrição:', error);
    res.status(500).json({
      error: 'Erro ao obter transcrição',
      message: error.message,
    });
  }
};

/**
 * GET /api/clinical/consultations
 * Lista todas as consultas (com paginação opcional)
 */
export const listConsultations = async (req: Request, res: Response) => {
  try {
    const { patientId, page, limit } = req.query;
    const userId = req.userId; // Do middleware de autenticação

    console.log('[ClinicalController] listConsultations chamado:', {
      patientId,
      page,
      limit,
      userId,
    });

    const pageNumber = page ? parseInt(page as string, 10) : 1;
    const limitNumber = limit ? parseInt(limit as string, 10) : 50;

    const result = await consultationDB.getConsultations(
      patientId as string | undefined,
      pageNumber,
      limitNumber,
      userId
    );

    console.log('[ClinicalController] Consultas encontradas:', {
      total: result.total,
      count: result.consultations.length,
      page: result.page,
      limit: result.limit,
    });

    res.json(result);
  } catch (error: any) {
    console.error('[ClinicalController] Erro ao listar consultas:', {
      error: error.message,
      stack: error.stack,
    });
    res.status(500).json({
      error: 'Erro ao listar consultas',
      message: error.message,
    });
  }
};

/**
 * GET /api/clinical/consultations/:consultationId
 * Retorna uma consulta completa por ID
 */
export const getConsultation = async (req: Request, res: Response) => {
  try {
    const { consultationId } = req.params;
    console.log('[ClinicalController] getConsultation chamado:', { consultationId });
    
    if (!consultationId) {
      return res.status(400).json({ error: 'consultationId é obrigatório' });
    }

    const consultation = await consultationDB.getConsultationById(consultationId);

    if (!consultation) {
      console.log('[ClinicalController] Consulta não encontrada:', consultationId);
      return res.status(404).json({ error: 'Consulta não encontrada' });
    }

    console.log('[ClinicalController] Consulta encontrada:', {
      id: consultation.id,
      hasPatientId: !!consultation.patientId,
      hasPatientName: !!consultation.patientName,
      transcriptLength: consultation.transcript?.length || 0,
    });

    res.json(consultation);
  } catch (error: any) {
    console.error('[ClinicalController] Erro ao obter consulta:', {
      consultationId: req.params?.consultationId,
      error: error.message,
      stack: error.stack,
    });
    res.status(500).json({
      error: 'Erro ao obter consulta',
      message: error.message,
    });
  }
};

/**
 * POST /api/clinical/start-recording
 * Inicia uma nova gravação/consulta
 */
export const startRecording = async (req: Request, res: Response) => {
  try {
    const { patientId, anonymousPatientName } = req.body;
    const userId = req.userId; // Do middleware de autenticação

    console.log('[ClinicalController] startRecording chamado:', {
      patientId,
      anonymousPatientName,
      hasPatientId: !!patientId,
      hasAnonymousName: !!anonymousPatientName,
    });

    // Se patientId foi fornecido mas não tem patientName, buscar nome do paciente
    let finalPatientName = anonymousPatientName;
    if (patientId && !anonymousPatientName) {
      try {
        const patient = await patientDB.getPatientById(patientId);
        if (patient) {
          finalPatientName = patient.name;
          console.log('[ClinicalController] Nome do paciente obtido da tabela patients:', finalPatientName);
        } else {
          console.warn('[ClinicalController] Paciente não encontrado com ID:', patientId);
        }
      } catch (patientError: any) {
        console.error('[ClinicalController] Erro ao buscar paciente:', patientError.message);
        // Continuar mesmo se não conseguir buscar o nome
      }
    }

    // Criar registro de consulta no banco de dados
    const consultation = await consultationDB.createConsultation(
      patientId || undefined,
      finalPatientName || undefined,
      userId
    );

    console.log('[ClinicalController] Consulta criada:', {
      consultationId: consultation.id,
      patientId: consultation.patientId,
      patientName: consultation.patientName,
    });

    res.json({
      consultationId: consultation.id,
      patientId: consultation.patientId || null,
      patientName: consultation.patientName || null,
    });
  } catch (error: any) {
    console.error('[ClinicalController] Erro ao iniciar gravação:', error);
    res.status(500).json({
      error: 'Erro ao iniciar gravação',
      message: error.message,
    });
  }
};

/**
 * GET /api/clinical/openai-key
 * Retorna a API key da OpenAI (temporário - em produção usar autenticação adequada)
 */
export const getOpenAIKey = async (req: Request, res: Response) => {
  try {
    const apiKey = process.env.OPENAI_API_KEY;
    if (!apiKey) {
      return res.status(503).json({
        error: 'OPENAI_API_KEY não configurada no servidor',
      });
    }
    // Em produção, isso deve ser protegido por autenticação
    res.json({ apiKey });
  } catch (error: any) {
    console.error('Erro ao obter API key:', error);
    res.status(500).json({
      error: 'Erro ao obter API key',
      message: error.message,
    });
  }
};

/**
 * POST /api/clinical/process-cascade
 * Processa a transcrição através de todos os agentes em cascata
 * Retorna: summary, anamnesis, prescription, suggestedQuestions
 */
export const processCascade = async (req: Request, res: Response) => {
  try {
    const { transcript, doctorNotes, consultationId } = req.body;

    console.log('[ClinicalController] processCascade chamado:', {
      hasTranscript: !!transcript,
      transcriptLength: transcript?.length || 0,
      hasDoctorNotes: !!doctorNotes,
      hasConsultationId: !!consultationId,
    });

    // Validação de entrada
    if (!transcript || typeof transcript !== 'string') {
      console.error('[ClinicalController] transcript inválido:', typeof transcript);
      return res.status(400).json({ 
        error: 'transcript é obrigatório e deve ser uma string',
        received: typeof transcript,
      });
    }

    if (transcript.trim().length === 0) {
      console.warn('[ClinicalController] transcript está vazio');
      return res.status(400).json({ error: 'transcript não pode estar vazio' });
    }

    // Buscar dados do paciente se consultationId fornecido
    let patientData = null;
    if (consultationId) {
      try {
        const consultation = await consultationDB.getConsultationById(consultationId);
        if (consultation && consultation.patientId) {
          console.log('[ClinicalController] Buscando dados do paciente:', consultation.patientId);
          patientData = await patientDB.getPatientById(consultation.patientId);
          if (patientData) {
            console.log('[ClinicalController] Dados do paciente encontrados:', patientData.name);
          } else {
            console.warn('[ClinicalController] Paciente não encontrado:', consultation.patientId);
          }
        }
      } catch (patientError: any) {
        console.error('[ClinicalController] Erro ao buscar dados do paciente:', patientError.message);
        // Continuar sem dados do paciente se houver erro
      }
    }

    // Processar através de todos os agentes em cascata (incluindo notas do médico e dados do paciente)
    console.log('[ClinicalController] Iniciando processamento em cascata...');
    const result = await openaiService.processCascade(transcript, doctorNotes, patientData);
    
    console.log('[ClinicalController] Resultado da cascata:', {
      hasSummary: !!result.summary,
      summaryLength: result.summary?.length || 0,
      hasAnamnesis: !!result.anamnesis,
      anamnesisLength: result.anamnesis?.length || 0,
      hasPrescription: result.prescription !== null && result.prescription !== undefined,
      prescriptionLength: result.prescription?.length || 0,
      hasSuggestedMedications: result.suggestedMedications !== null && result.suggestedMedications !== undefined,
      suggestedMedicationsLength: result.suggestedMedications?.length || 0,
      hasSuggestedQuestions: Array.isArray(result.suggestedQuestions),
      suggestedQuestionsCount: result.suggestedQuestions?.length || 0,
    });

    // Atualizar no banco de dados se consultationId fornecido
    if (consultationId) {
      if (typeof consultationId !== 'string' || consultationId.trim().length === 0) {
        console.error('[ClinicalController] consultationId inválido:', consultationId);
        return res.status(400).json({ error: 'consultationId inválido' });
      }

      try {
        console.log('[ClinicalController] Atualizando transcrição no banco...');
        await consultationDB.updateTranscript(consultationId, transcript);
        console.log('[ClinicalController] Transcrição atualizada com sucesso');

        console.log('[ClinicalController] Atualizando análise em cascata no banco...');
        await consultationDB.updateCascadeAnalysis(consultationId, {
          summary: result.summary || undefined,
          anamnesis: result.anamnesis || undefined,
          prescription: result.prescription ?? null, // Garantir que null seja tratado corretamente
          suggestedMedications: result.suggestedMedications ?? null,
          suggestedQuestions: Array.isArray(result.suggestedQuestions) 
            ? result.suggestedQuestions 
            : [],
        });
        console.log('[ClinicalController] Análise em cascata atualizada com sucesso');

        if (doctorNotes && typeof doctorNotes === 'string' && doctorNotes.trim().length > 0) {
          console.log('[ClinicalController] Atualizando notas do médico...');
          await consultationDB.updateDoctorNotes(consultationId, doctorNotes);
          console.log('[ClinicalController] Notas do médico atualizadas com sucesso');
        }
      } catch (dbError: any) {
        console.error('[ClinicalController] Erro ao salvar no banco de dados:', {
          consultationId,
          error: dbError.message,
          stack: dbError.stack,
        });
        // Continuar mesmo se houver erro ao salvar, mas retornar aviso
        return res.status(500).json({
          error: 'Erro ao salvar no banco de dados',
          message: dbError.message,
          cascadeResult: result, // Retornar resultado mesmo com erro de salvamento
        });
      }
    } else {
      console.warn('[ClinicalController] consultationId não fornecido, dados não serão salvos no banco');
    }

    console.log('[ClinicalController] processCascade concluído com sucesso');
    res.json(result);
  } catch (error: any) {
    console.error('[ClinicalController] Erro ao processar cascata:', {
      error: error.message,
      stack: error.stack,
      body: req.body,
    });
    res.status(500).json({
      error: 'Erro ao processar cascata de agentes',
      message: error.message,
    });
  }
};

/**
 * POST /api/clinical/chat
 * Chat com IA usando contexto completo do atendimento
 */
export const chatWithIA = async (req: Request, res: Response) => {
  try {
    const { message, context } = req.body;

    if (!message) {
      return res.status(400).json({ error: 'message é obrigatório' });
    }

    if (!context) {
      return res.status(400).json({ error: 'context é obrigatório' });
    }

    // Chat com IA usando contexto completo
    const response = await openaiService.chatWithContext(message, context);

    res.json({ response });
  } catch (error: any) {
    console.error('Erro no chat com IA:', error);
    res.status(500).json({
      error: 'Erro ao processar chat',
      message: error.message,
    });
  }
};

/**
 * POST /api/clinical/save-medical-record
 * Salva campos parciais do prontuário médico (salvamento automático)
 * Aceita qualquer combinação de campos, permitindo null para limpar campos
 */
export const saveMedicalRecord = async (req: Request, res: Response) => {
  try {
    const {
      consultationId,
      patientId,
      transcript,
      summary,
      anamnesis,
      prescription,
      suggestedMedications,
      suggestedQuestions,
      doctorNotes,
      chatMessages,
    } = req.body;

    console.log('[ClinicalController] saveMedicalRecord chamado:', {
      consultationId,
      hasPatientId: patientId !== undefined,
      patientId: patientId,
      hasTranscript: transcript !== undefined,
      hasSummary: summary !== undefined,
      hasAnamnesis: anamnesis !== undefined,
      hasPrescription: prescription !== undefined,
      hasSuggestedMedications: suggestedMedications !== undefined,
      hasSuggestedQuestions: suggestedQuestions !== undefined,
      hasDoctorNotes: doctorNotes !== undefined,
      hasChatMessages: chatMessages !== undefined,
    });

    // Validação obrigatória
    if (!consultationId) {
      console.error('[ClinicalController] consultationId não fornecido');
      return res.status(400).json({ error: 'consultationId é obrigatório' });
    }

    // Verificar se a consulta existe
    const existingConsultation = await consultationDB.getConsultationById(consultationId);
    if (!existingConsultation) {
      console.error('[ClinicalController] Consulta não encontrada:', consultationId);
      return res.status(404).json({ error: 'Consulta não encontrada' });
    }

    // Preparar dados para atualização (apenas campos fornecidos)
    const updateData: {
      patientId?: string | null;
      transcript?: string | null;
      summary?: string | null;
      anamnesis?: string | null;
      prescription?: string | null;
      suggestedMedications?: string | null;
      suggestedQuestions?: string[] | null;
      doctorNotes?: string | null;
      chatMessages?: any[] | null;
    } = {};

    // Adicionar apenas campos que foram fornecidos (incluindo null)
    if (patientId !== undefined) {
      updateData.patientId = patientId === null || patientId === '' ? null : String(patientId);
      console.log('[ClinicalController] patientId será atualizado:', {
        originalValue: patientId,
        processedValue: updateData.patientId,
        existingPatientId: existingConsultation.patientId,
        willChange: existingConsultation.patientId !== updateData.patientId,
      });
    } else {
      console.log('[ClinicalController] patientId não foi fornecido no request (undefined)');
    }
    if (transcript !== undefined) {
      updateData.transcript = transcript === null || transcript === '' ? null : String(transcript);
    }
    if (summary !== undefined) {
      updateData.summary = summary === null || summary === '' ? null : String(summary);
    }
    if (anamnesis !== undefined) {
      updateData.anamnesis = anamnesis === null || anamnesis === '' ? null : String(anamnesis);
    }
    if (prescription !== undefined) {
      updateData.prescription = prescription === null || prescription === '' ? null : String(prescription);
    }
    if (suggestedMedications !== undefined) {
      updateData.suggestedMedications = suggestedMedications === null || suggestedMedications === '' ? null : String(suggestedMedications);
    }
    if (suggestedQuestions !== undefined) {
      updateData.suggestedQuestions = suggestedQuestions === null ? null : (Array.isArray(suggestedQuestions) ? suggestedQuestions : []);
    }
    if (doctorNotes !== undefined) {
      updateData.doctorNotes = doctorNotes === null || doctorNotes === '' ? null : String(doctorNotes);
    }
    if (chatMessages !== undefined) {
      updateData.chatMessages = chatMessages === null ? null : (Array.isArray(chatMessages) ? chatMessages : []);
    }

    console.log('[ClinicalController] Campos para atualizar:', {
      fields: Object.keys(updateData),
      updateData: updateData,
      existingPatientId: existingConsultation.patientId,
      existingPatientName: existingConsultation.patientName,
    });

    // Se não há campos para atualizar, retornar sucesso (nada a fazer)
    if (Object.keys(updateData).length === 0) {
      console.log('[ClinicalController] Nenhum campo para atualizar, retornando consulta atual');
      return res.json({
        success: true,
        consultation: existingConsultation,
      });
    }

    // Atualizar no banco
    console.log('[ClinicalController] Chamando updateMedicalRecordPartial...');
    const updatedConsultation = await consultationDB.updateMedicalRecordPartial(
      consultationId,
      updateData
    );

    if (!updatedConsultation) {
      console.error('[ClinicalController] Erro ao atualizar prontuário - updatedConsultation é null');
      return res.status(500).json({ error: 'Erro ao atualizar prontuário' });
    }

    console.log('[ClinicalController] Prontuário atualizado com sucesso:', {
      consultationId: updatedConsultation.id,
      patientId: updatedConsultation.patientId,
      patientName: updatedConsultation.patientName,
      hasPatientId: !!updatedConsultation.patientId,
      hasPatientName: !!updatedConsultation.patientName,
    });
    res.json({
      success: true,
      consultation: updatedConsultation,
    });
  } catch (error: any) {
    console.error('[ClinicalController] Erro ao salvar prontuário:', {
      error: error.message,
      stack: error.stack,
      consultationId: req.body?.consultationId,
    });
    res.status(500).json({
      error: 'Erro ao salvar prontuário',
      message: error.message,
    });
  }
};

/**
 * POST /api/clinical/finish-consultation
 * Finaliza uma consulta (marca ended_at)
 */
export const finishConsultation = async (req: Request, res: Response) => {
  try {
    const { consultationId } = req.body;

    if (!consultationId) {
      return res.status(400).json({ error: 'consultationId é obrigatório' });
    }

    // Verificar se a consulta existe
    const existingConsultation = await consultationDB.getConsultationById(consultationId);
    if (!existingConsultation) {
      return res.status(404).json({ error: 'Consulta não encontrada' });
    }

    // Finalizar consulta
    const finishedConsultation = await consultationDB.endConsultation(consultationId);
    if (!finishedConsultation) {
      return res.status(500).json({ error: 'Erro ao finalizar consulta' });
    }

    console.log('[ClinicalController] Consulta finalizada:', consultationId);
    res.json({
      success: true,
      consultation: finishedConsultation,
    });
  } catch (error: any) {
    console.error('[ClinicalController] Erro ao finalizar consulta:', error);
    res.status(500).json({
      error: 'Erro ao finalizar consulta',
      message: error.message,
    });
  }
};

/**
 * POST /api/clinical/resume-consultation
 * Retoma uma consulta (remove ended_at para permitir continuar)
 */
export const resumeConsultation = async (req: Request, res: Response) => {
  try {
    const { consultationId } = req.body;

    if (!consultationId) {
      return res.status(400).json({ error: 'consultationId é obrigatório' });
    }

    // Verificar se a consulta existe
    const existingConsultation = await consultationDB.getConsultationById(consultationId);
    if (!existingConsultation) {
      return res.status(404).json({ error: 'Consulta não encontrada' });
    }

    // Retomar consulta
    const resumedConsultation = await consultationDB.resumeConsultation(consultationId);
    if (!resumedConsultation) {
      return res.status(500).json({ error: 'Erro ao retomar consulta' });
    }

    console.log('[ClinicalController] Consulta retomada:', consultationId);
    res.json({
      success: true,
      consultation: resumedConsultation,
    });
  } catch (error: any) {
    console.error('[ClinicalController] Erro ao retomar consulta:', error);
    res.status(500).json({
      error: 'Erro ao retomar consulta',
      message: error.message,
    });
  }
};

