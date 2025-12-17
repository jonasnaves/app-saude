import { Server } from 'http';
import { WebSocketServer, WebSocket } from 'ws';
import jwt from 'jsonwebtoken';
import { AppDataSource } from '../config/database';
import { User } from '../models/User';
import { audioService } from './audio.service';
import { geminiService } from './gemini.service';
import { Consultation } from '../models/Consultation';

interface WebSocketMessage {
  type: string;
  consultationId?: string;
  audioData?: string;
  textChunk?: string;
  token?: string;
}

export const setupWebSocket = (server: Server) => {
  const wss = new WebSocketServer({ server, path: '/api/clinical/ws' });

  wss.on('connection', async (ws: WebSocket, req) => {
    console.log('New WebSocket connection');

    let userId: string | null = null;
    let consultationId: string | null = null;

    ws.on('message', async (message: Buffer) => {
      try {
        const data: WebSocketMessage = JSON.parse(message.toString());

        // Autenticação inicial
        if (data.type === 'auth' && data.token) {
          try {
            const decoded = jwt.verify(data.token, process.env.JWT_SECRET!) as { userId: string };
            const userRepository = AppDataSource.getRepository(User);
            const user = await userRepository.findOne({ where: { id: decoded.userId } });

            if (user) {
              userId = user.id;
              ws.send(JSON.stringify({ type: 'auth', success: true }));
            } else {
              ws.send(JSON.stringify({ type: 'auth', success: false, error: 'User not found' }));
              ws.close();
            }
          } catch (error) {
            ws.send(JSON.stringify({ type: 'auth', success: false, error: 'Invalid token' }));
            ws.close();
          }
          return;
        }

        if (!userId) {
          ws.send(JSON.stringify({ type: 'error', message: 'Not authenticated' }));
          return;
        }

        // Iniciar gravação
        if (data.type === 'start') {
          const consultationRepository = AppDataSource.getRepository(Consultation);
          const consultation = consultationRepository.create({
            userId,
            startedAt: new Date(),
          });
          await consultationRepository.save(consultation);
          consultationId = consultation.id;
          audioService.reset(consultationId);
          ws.send(JSON.stringify({ type: 'started', consultationId }));
          return;
        }

        if (!consultationId) {
          ws.send(JSON.stringify({ type: 'error', message: 'Recording not started' }));
          return;
        }

        // Processar chunk de áudio/texto
        if (data.type === 'chunk') {
          let transcript = '';

          if (data.audioData) {
            transcript = await audioService.processAudioChunk(
              {
                data: data.audioData,
                mimeType: 'audio/pcm;rate=16000',
                timestamp: Date.now(),
              },
              consultationId
            );
          } else if (data.textChunk) {
            transcript = await audioService.processTextChunk(data.textChunk);
          }

          // Atualizar transcrição no banco
          const consultationRepository = AppDataSource.getRepository(Consultation);
          const consultation = await consultationRepository.findOne({
            where: { id: consultationId, userId },
          });

          if (consultation) {
            consultation.transcript = transcript;
            await consultationRepository.save(consultation);
          }

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

          ws.send(
            JSON.stringify({
              type: 'transcript',
              transcript,
              analysis,
              shouldAnalyze,
            })
          );
        }

        // Finalizar gravação
        if (data.type === 'stop') {
          const consultationRepository = AppDataSource.getRepository(Consultation);
          const consultation = await consultationRepository.findOne({
            where: { id: consultationId, userId },
          });

          if (consultation) {
            consultation.endedAt = new Date();
            await consultationRepository.save(consultation);
          }

          ws.send(JSON.stringify({ type: 'stopped', consultationId }));
          audioService.reset();
        }
      } catch (error) {
        console.error('WebSocket error:', error);
        ws.send(JSON.stringify({ type: 'error', message: 'Internal server error' }));
      }
    });

    ws.on('close', () => {
      console.log('WebSocket connection closed');
      if (consultationId) {
        audioService.reset();
      }
    });

    ws.on('error', (error) => {
      console.error('WebSocket error:', error);
    });
  });

  console.log('WebSocket server initialized');
};

