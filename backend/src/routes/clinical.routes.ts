import { Router } from 'express';
import { authMiddleware } from '../middleware/auth.middleware';
import {
  startRecording,
  analyzeIncremental,
  generateSummary,
  updateTranscript,
  getConsultations,
  getConsultation,
  processAudioChunk,
} from '../controllers/clinical.controller';

const router = Router();

router.use(authMiddleware);

router.post('/start-recording', startRecording);
router.post('/process-chunk', processAudioChunk);
router.post('/analyze-incremental', analyzeIncremental);
router.post('/generate-summary', generateSummary);
router.post('/update-transcript', updateTranscript);
router.get('/consultations', getConsultations);
router.get('/consultations/:id', getConsultation);

export default router;

