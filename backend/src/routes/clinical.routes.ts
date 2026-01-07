import { Router } from 'express';
import * as clinicalController from '../controllers/clinical.controller';
import { authMiddleware } from '../middleware/auth.middleware';

const router = Router();

// Aplicar middleware de autenticação em todas as rotas
router.use(authMiddleware);

// Endpoint para iniciar gravação
router.post('/start-recording', clinicalController.startRecording);

// Endpoint para transcrever chunk de áudio
router.post('/transcribe-chunk', clinicalController.transcribeChunk);

// Endpoint para análise incremental
router.post('/analyze-incremental', clinicalController.analyzeIncremental);

// Endpoint para gerar resumo clínico
router.post('/generate-summary', clinicalController.generateSummary);

// Endpoint para obter transcrição completa
router.get('/transcript/:consultationId', clinicalController.getTranscript);

// Endpoint para listar consultas
router.get('/consultations', clinicalController.listConsultations);

// Endpoint para obter consulta completa
router.get('/consultations/:consultationId', clinicalController.getConsultation);

// Endpoint para obter API key da OpenAI (temporário)
router.get('/openai-key', clinicalController.getOpenAIKey);

// Endpoint para processar cascata de agentes
router.post('/process-cascade', clinicalController.processCascade);

// Endpoint para chat com IA
router.post('/chat', clinicalController.chatWithIA);

// Endpoint para salvar prontuário parcial (salvamento automático)
router.post('/save-medical-record', clinicalController.saveMedicalRecord);

// Endpoint para finalizar consulta
router.post('/finish-consultation', clinicalController.finishConsultation);

// Endpoint para retomar consulta
router.post('/resume-consultation', clinicalController.resumeConsultation);

export default router;

