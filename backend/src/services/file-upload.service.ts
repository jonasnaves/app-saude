import { v4 as uuidv4 } from 'uuid';
import * as fs from 'fs';
import * as path from 'path';
import { Request } from 'express';

export interface UploadedFile {
  id: string;
  originalName: string;
  fileName: string;
  url: string;
  size: number;
  mimeType: string;
}

export class FileUploadService {
  private readonly uploadsDir: string;
  private readonly photosDir: string;
  private readonly documentsDir: string;
  private readonly maxPhotoSize: number = 10 * 1024 * 1024; // 10MB
  private readonly maxDocumentSize: number = 50 * 1024 * 1024; // 50MB
  private readonly allowedPhotoTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'];
  private readonly allowedDocumentTypes = [
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'image/jpeg',
    'image/jpg',
    'image/png',
  ];

  constructor() {
    // Definir diretórios de upload
    this.uploadsDir = path.join(__dirname, '../../uploads');
    this.photosDir = path.join(this.uploadsDir, 'patients/photos');
    this.documentsDir = path.join(this.uploadsDir, 'patients/documents');

    // Criar diretórios se não existirem
    this.ensureDirectoriesExist();
  }

  private ensureDirectoriesExist(): void {
    [this.uploadsDir, this.photosDir, this.documentsDir].forEach((dir) => {
      if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
      }
    });
  }

  /**
   * Valida e faz upload de uma foto
   */
  async uploadPhoto(file: Express.Multer.File): Promise<UploadedFile> {
    // Validar tipo
    if (!this.allowedPhotoTypes.includes(file.mimetype)) {
      throw new Error(
        `Tipo de arquivo não permitido. Tipos permitidos: ${this.allowedPhotoTypes.join(', ')}`
      );
    }

    // Validar tamanho
    if (file.size > this.maxPhotoSize) {
      throw new Error(`Arquivo muito grande. Tamanho máximo: ${this.maxPhotoSize / 1024 / 1024}MB`);
    }

    // Gerar nome único
    const fileId = uuidv4();
    const extension = path.extname(file.originalname);
    const fileName = `${fileId}${extension}`;
    const filePath = path.join(this.photosDir, fileName);

    // Salvar arquivo
    fs.writeFileSync(filePath, file.buffer);

    // Retornar informações do arquivo
    return {
      id: fileId,
      originalName: file.originalname,
      fileName,
      url: `/uploads/patients/photos/${fileName}`,
      size: file.size,
      mimeType: file.mimetype,
    };
  }

  /**
   * Valida e faz upload de um documento
   */
  async uploadDocument(file: Express.Multer.File): Promise<UploadedFile> {
    // Validar tipo
    if (!this.allowedDocumentTypes.includes(file.mimetype)) {
      throw new Error(
        `Tipo de arquivo não permitido. Tipos permitidos: ${this.allowedDocumentTypes.join(', ')}`
      );
    }

    // Validar tamanho
    if (file.size > this.maxDocumentSize) {
      throw new Error(
        `Arquivo muito grande. Tamanho máximo: ${this.maxDocumentSize / 1024 / 1024}MB`
      );
    }

    // Gerar nome único
    const fileId = uuidv4();
    const extension = path.extname(file.originalname);
    const fileName = `${fileId}${extension}`;
    const filePath = path.join(this.documentsDir, fileName);

    // Salvar arquivo
    fs.writeFileSync(filePath, file.buffer);

    // Retornar informações do arquivo
    return {
      id: fileId,
      originalName: file.originalname,
      fileName,
      url: `/uploads/patients/documents/${fileName}`,
      size: file.size,
      mimeType: file.mimetype,
    };
  }

  /**
   * Deleta um arquivo de foto
   */
  async deletePhoto(fileName: string): Promise<void> {
    const filePath = path.join(this.photosDir, fileName);
    if (fs.existsSync(filePath)) {
      fs.unlinkSync(filePath);
    }
  }

  /**
   * Deleta um arquivo de documento
   */
  async deleteDocument(fileName: string): Promise<void> {
    const filePath = path.join(this.documentsDir, fileName);
    if (fs.existsSync(filePath)) {
      fs.unlinkSync(filePath);
    }
  }

  /**
   * Obtém o caminho completo de um arquivo de foto
   */
  getPhotoPath(fileName: string): string {
    return path.join(this.photosDir, fileName);
  }

  /**
   * Obtém o caminho completo de um arquivo de documento
   */
  getDocumentPath(fileName: string): string {
    return path.join(this.documentsDir, fileName);
  }
}


