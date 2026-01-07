import { Router } from 'express';
import multer from 'multer';
import * as patientController from '../controllers/patient.controller';
import { authMiddleware } from '../middleware/auth.middleware';

const router = Router();

// Configurar multer para upload de arquivos em memória
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 50 * 1024 * 1024, // 50MB
  },
});

// Aplicar middleware de autenticação em todas as rotas
router.use(authMiddleware);

// Rotas CRUD
router.get('/', patientController.getPatients);
router.get('/:id', patientController.getPatient);
router.post('/', patientController.createPatient);
router.put('/:id', patientController.updatePatient);
router.delete('/:id', patientController.deletePatient);

// Rotas de upload de fotos
router.post('/:id/photos', upload.single('photo'), patientController.uploadPhoto);
router.delete('/:id/photos/:photoId', patientController.deletePhoto);

// Rotas de upload de documentos
router.post('/:id/documents', upload.single('document'), patientController.uploadDocument);
router.delete('/:id/documents/:docId', patientController.deleteDocument);

export default router;

