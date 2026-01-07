import { Request, Response } from 'express';
import { PatientDBService } from '../services/patient-db.service';
import { FileUploadService } from '../services/file-upload.service';
import { Patient, PatientDocument } from '../models/Patient';
import { v4 as uuidv4 } from 'uuid';

const patientDB = new PatientDBService();
const fileUploadService = new FileUploadService();

/**
 * GET /api/patients
 * Lista pacientes com busca e paginação
 */
export const getPatients = async (req: Request, res: Response) => {
  try {
    const search = req.query.search as string | undefined;
    const page = parseInt(req.query.page as string) || 1;
    const limit = parseInt(req.query.limit as string) || 50;
    const userId = req.userId; // Do middleware de autenticação

    console.log('[PatientController] getPatients chamado:', {
      search,
      page,
      limit,
      userId,
    });

    const result = await patientDB.getPatients(search, page, limit, userId);

    console.log('[PatientController] Pacientes encontrados:', {
      total: result.total,
      count: result.patients.length,
    });

    res.json(result);
  } catch (error: any) {
    console.error('[PatientController] Erro ao listar pacientes:', {
      error: error.message,
      stack: error.stack,
      name: error.name,
    });
    res.status(500).json({
      error: 'Erro ao listar pacientes',
      message: error.message || 'Erro desconhecido',
    });
  }
};

/**
 * GET /api/patients/:id
 * Obtém um paciente por ID
 */
export const getPatient = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const patient = await patientDB.getPatientById(id);

    if (!patient) {
      return res.status(404).json({ error: 'Paciente não encontrado' });
    }

    res.json(patient);
  } catch (error: any) {
    console.error('Erro ao obter paciente:', error);
    res.status(500).json({
      error: 'Erro ao obter paciente',
      message: error.message,
    });
  }
};

/**
 * POST /api/patients
 * Cria um novo paciente
 */
export const createPatient = async (req: Request, res: Response) => {
  try {
    console.log('[PatientController] createPatient chamado');
    console.log('[PatientController] Request body:', JSON.stringify(req.body, null, 2));
    console.log('[PatientController] Content-Type:', req.headers['content-type']);
    console.log('[PatientController] Body type:', typeof req.body);
    console.log('[PatientController] Body keys:', req.body ? Object.keys(req.body) : 'null');

    // Verificar se o body está vazio ou undefined
    if (!req.body || Object.keys(req.body).length === 0) {
      console.error('[PatientController] Body vazio ou undefined');
      return res.status(400).json({ 
        error: 'Dados do paciente são obrigatórios',
        message: 'O corpo da requisição está vazio',
      });
    }

    const patientData = req.body as Omit<Patient, 'id' | 'createdAt' | 'updatedAt'>;

    // Validação básica
    if (!patientData.name || (typeof patientData.name === 'string' && patientData.name.trim().length === 0)) {
      return res.status(400).json({ error: 'Nome é obrigatório' });
    }

    console.log('[PatientController] Dados do paciente validados:', {
      hasName: !!patientData.name,
      hasCpf: !!patientData.cpf,
      hasEmail: !!patientData.email,
    });

    const userId = req.userId; // Do middleware de autenticação
    console.log('[PatientController] UserId:', userId);

    const patient = await patientDB.createPatient(patientData, userId);
    console.log('[PatientController] Paciente criado com sucesso:', patient.id);

    res.status(201).json(patient);
  } catch (error: any) {
    console.error('[PatientController] Erro ao criar paciente:', {
      error: error.message,
      stack: error.stack,
      name: error.name,
    });
    
    // Se for erro de JSON, fornecer mensagem mais clara
    if (error.message && error.message.includes('JSON')) {
      return res.status(400).json({
        error: 'Erro ao processar dados do paciente',
        message: 'Os dados enviados estão em formato inválido. Verifique se todos os campos estão corretos.',
        details: error.message,
      });
    }

    res.status(500).json({
      error: 'Erro ao criar paciente',
      message: error.message || 'Erro desconhecido',
    });
  }
};

/**
 * PUT /api/patients/:id
 * Atualiza um paciente existente
 */
export const updatePatient = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const updates = req.body as Partial<Omit<Patient, 'id' | 'createdAt'>>;

    const updatedPatient = await patientDB.updatePatient(id, updates);

    if (!updatedPatient) {
      return res.status(404).json({ error: 'Paciente não encontrado' });
    }

    res.json(updatedPatient);
  } catch (error: any) {
    console.error('Erro ao atualizar paciente:', error);
    res.status(500).json({
      error: 'Erro ao atualizar paciente',
      message: error.message,
    });
  }
};

/**
 * DELETE /api/patients/:id
 * Exclui um paciente
 */
export const deletePatient = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;

    // Deletar arquivos associados
    const patient = await patientDB.getPatientById(id);
    if (patient) {
      // Deletar fotos
      for (const photoUrl of patient.photos) {
        const fileName = photoUrl.split('/').pop();
        if (fileName) {
          try {
            await fileUploadService.deletePhoto(fileName);
          } catch (err) {
            console.error(`Erro ao deletar foto ${fileName}:`, err);
          }
        }
      }

      // Deletar documentos
      for (const doc of patient.documents) {
        const fileName = doc.url.split('/').pop();
        if (fileName) {
          try {
            await fileUploadService.deleteDocument(fileName);
          } catch (err) {
            console.error(`Erro ao deletar documento ${fileName}:`, err);
          }
        }
      }
    }

    const deleted = await patientDB.deletePatient(id);

    if (!deleted) {
      return res.status(404).json({ error: 'Paciente não encontrado' });
    }

    res.json({ message: 'Paciente excluído com sucesso' });
  } catch (error: any) {
    console.error('Erro ao excluir paciente:', error);
    res.status(500).json({
      error: 'Erro ao excluir paciente',
      message: error.message,
    });
  }
};

/**
 * POST /api/patients/:id/photos
 * Upload de foto do paciente
 */
export const uploadPhoto = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;

    if (!req.file) {
      return res.status(400).json({ error: 'Arquivo não fornecido' });
    }

    // Verificar se paciente existe
    const patient = await patientDB.getPatientById(id);
    if (!patient) {
      return res.status(404).json({ error: 'Paciente não encontrado' });
    }

    // Fazer upload da foto
    const uploadedFile = await fileUploadService.uploadPhoto(req.file);

    // Adicionar foto ao paciente
    const updatedPatient = await patientDB.addPhoto(id, uploadedFile.url);

    res.status(201).json({
      photo: uploadedFile,
      patient: updatedPatient,
    });
  } catch (error: any) {
    console.error('Erro ao fazer upload de foto:', error);
    res.status(500).json({
      error: 'Erro ao fazer upload de foto',
      message: error.message,
    });
  }
};

/**
 * DELETE /api/patients/:id/photos/:photoId
 * Exclui uma foto do paciente
 */
export const deletePhoto = async (req: Request, res: Response) => {
  try {
    const { id, photoId } = req.params;

    const patient = await patientDB.getPatientById(id);
    if (!patient) {
      return res.status(404).json({ error: 'Paciente não encontrado' });
    }

    // Encontrar a foto pelo ID (que é parte da URL)
    const photoUrl = patient.photos.find((url) => url.includes(photoId));
    if (!photoUrl) {
      return res.status(404).json({ error: 'Foto não encontrada' });
    }

    // Deletar arquivo físico
    const fileName = photoUrl.split('/').pop();
    if (fileName) {
      await fileUploadService.deletePhoto(fileName);
    }

    // Remover do paciente
    const updatedPatient = await patientDB.removePhoto(id, photoUrl);

    res.json({
      message: 'Foto excluída com sucesso',
      patient: updatedPatient,
    });
  } catch (error: any) {
    console.error('Erro ao excluir foto:', error);
    res.status(500).json({
      error: 'Erro ao excluir foto',
      message: error.message,
    });
  }
};

/**
 * POST /api/patients/:id/documents
 * Upload de documento do paciente
 */
export const uploadDocument = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;

    if (!req.file) {
      return res.status(400).json({ error: 'Arquivo não fornecido' });
    }

    // Verificar se paciente existe
    const patient = await patientDB.getPatientById(id);
    if (!patient) {
      return res.status(404).json({ error: 'Paciente não encontrado' });
    }

    // Fazer upload do documento
    const uploadedFile = await fileUploadService.uploadDocument(req.file);

    // Criar objeto de documento
    const document: PatientDocument = {
      id: uploadedFile.id,
      name: uploadedFile.originalName,
      type: uploadedFile.mimeType.includes('pdf')
        ? 'PDF'
        : uploadedFile.mimeType.includes('word')
        ? 'DOC'
        : 'IMAGE',
      url: uploadedFile.url,
      uploadedAt: new Date().toISOString(),
      size: uploadedFile.size,
    };

    // Adicionar documento ao paciente
    const updatedPatient = await patientDB.addDocument(id, document);

    res.status(201).json({
      document,
      patient: updatedPatient,
    });
  } catch (error: any) {
    console.error('Erro ao fazer upload de documento:', error);
    res.status(500).json({
      error: 'Erro ao fazer upload de documento',
      message: error.message,
    });
  }
};

/**
 * DELETE /api/patients/:id/documents/:docId
 * Exclui um documento do paciente
 */
export const deleteDocument = async (req: Request, res: Response) => {
  try {
    const { id, docId } = req.params;

    const patient = await patientDB.getPatientById(id);
    if (!patient) {
      return res.status(404).json({ error: 'Paciente não encontrado' });
    }

    // Encontrar o documento
    const document = patient.documents.find((doc) => doc.id === docId);
    if (!document) {
      return res.status(404).json({ error: 'Documento não encontrado' });
    }

    // Deletar arquivo físico
    const fileName = document.url.split('/').pop();
    if (fileName) {
      await fileUploadService.deleteDocument(fileName);
    }

    // Remover do paciente
    const updatedPatient = await patientDB.removeDocument(id, docId);

    res.json({
      message: 'Documento excluído com sucesso',
      patient: updatedPatient,
    });
  } catch (error: any) {
    console.error('Erro ao excluir documento:', error);
    res.status(500).json({
      error: 'Erro ao excluir documento',
      message: error.message,
    });
  }
};

