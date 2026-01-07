import pool from '../config/database';
import { Patient, PatientDocument } from '../models/Patient';

/**
 * Serviço de armazenamento de pacientes no PostgreSQL
 */
export class PatientDBService {
  /**
   * Lista todos os pacientes com busca e paginação
   * Se userId fornecido, filtra apenas pacientes criados por esse usuário
   */
  async getPatients(search?: string, page: number = 1, limit: number = 50, userId?: string): Promise<{
    patients: Patient[];
    total: number;
    page: number;
    limit: number;
  }> {
    let query = 'SELECT * FROM patients';
    const params: any[] = [];
    let paramCount = 0;
    const conditions: string[] = [];

    // Filtrar por usuário se fornecido
    if (userId) {
      conditions.push(`created_by = $${++paramCount}`);
      params.push(userId);
    }

    // Aplicar busca se fornecida
    if (search) {
      const searchConditions = [
        `LOWER(name) LIKE $${++paramCount}`,
        `LOWER(cpf) LIKE $${++paramCount}`,
        `LOWER(email) LIKE $${++paramCount}`,
        `LOWER(phone) LIKE $${++paramCount}`,
      ];
      const searchPattern = `%${search.toLowerCase()}%`;
      params.push(searchPattern, searchPattern, searchPattern, searchPattern);
      conditions.push(`(${searchConditions.join(' OR ')})`);
    }

    if (conditions.length > 0) {
      query += ` WHERE ${conditions.join(' AND ')}`;
    }

    // Ordenar por data de criação (mais recentes primeiro)
    query += ' ORDER BY created_at DESC';

    // Aplicar paginação
    const offset = (page - 1) * limit;
    query += ` LIMIT $${++paramCount} OFFSET $${++paramCount}`;
    params.push(limit, offset);

    // Contar total
    let countQuery = 'SELECT COUNT(*) FROM patients';
    const countParams: any[] = [];
    const countConditions: string[] = [];
    let countParamCount = 0;

    if (userId) {
      countConditions.push(`created_by = $${++countParamCount}`);
      countParams.push(userId);
    }

    if (search) {
      const searchConditions = [
        `LOWER(name) LIKE $${++countParamCount}`,
        `LOWER(cpf) LIKE $${++countParamCount}`,
        `LOWER(email) LIKE $${++countParamCount}`,
        `LOWER(phone) LIKE $${++countParamCount}`,
      ];
      const searchPattern = `%${search.toLowerCase()}%`;
      countParams.push(searchPattern, searchPattern, searchPattern, searchPattern);
      countConditions.push(`(${searchConditions.join(' OR ')})`);
    }

    if (countConditions.length > 0) {
      countQuery += ` WHERE ${countConditions.join(' AND ')}`;
    }

    try {
      const [result, countResult] = await Promise.all([
        pool.query(query, params),
        pool.query(countQuery, countParams),
      ]);

      console.log('[PatientDB] getPatients - Resultados:', {
        rowsCount: result.rows.length,
        total: countResult.rows[0]?.count,
      });

      // Mapear pacientes com tratamento de erro individual
      const patients: Patient[] = [];
      for (const row of result.rows) {
        try {
          const patient = this.mapRowToPatient(row);
          // Buscar documentos do paciente
          const documents = await this.getPatientDocuments(patient.id);
          patient.documents = documents;
          patients.push(patient);
        } catch (error: any) {
          console.error('[PatientDB] Erro ao mapear paciente:', {
            patientId: row.id,
            error: error.message,
            row: JSON.stringify(row).substring(0, 200),
          });
          // Continuar com os outros pacientes mesmo se um falhar
        }
      }

      const total = parseInt(countResult.rows[0]?.count || '0');

      return {
        patients,
        total,
        page,
        limit,
      };
    } catch (error: any) {
      console.error('[PatientDB] Erro ao listar pacientes:', {
        error: error.message,
        stack: error.stack,
        query: query.substring(0, 200),
      });
      throw error;
    }
  }

  /**
   * Obtém um paciente por ID
   */
  async getPatientById(id: string): Promise<Patient | null> {
    try {
      const result = await pool.query('SELECT * FROM patients WHERE id = $1', [id]);
      if (result.rows.length === 0) {
        return null;
      }
      
      const patient = this.mapRowToPatient(result.rows[0]);
      
      // Buscar documentos do paciente
      const documents = await this.getPatientDocuments(patient.id);
      patient.documents = documents;
      
      return patient;
    } catch (error: any) {
      console.error('[PatientDB] Erro ao obter paciente por ID:', {
        id,
        error: error.message,
        stack: error.stack,
      });
      throw error;
    }
  }

  /**
   * Cria um novo paciente
   */
  async createPatient(patientData: Omit<Patient, 'id' | 'createdAt' | 'updatedAt'>, createdBy?: string): Promise<Patient> {
    const query = `
      INSERT INTO patients (
        name, cpf, rg, birth_date, gender, phone, email,
        address, allergies, medical_history, current_medications,
        chronic_conditions, emergency_contacts, photos, created_by
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15)
      RETURNING *
    `;

    // Helper para fazer stringify seguro de JSON
    const safeJsonStringify = (value: any): string | null => {
      if (!value) return null;
      try {
        if (typeof value === 'string') {
          // Se já é string, tentar parsear para validar
          JSON.parse(value);
          return value;
        }
        return JSON.stringify(value);
      } catch (error) {
        console.error('[PatientDB] Erro ao fazer stringify de JSON:', error);
        return null;
      }
    };

    const values = [
      patientData.name,
      patientData.cpf || null,
      patientData.rg || null,
      patientData.birthDate || null,
      patientData.gender || null,
      patientData.phone || null,
      patientData.email || null,
      safeJsonStringify(patientData.address),
      safeJsonStringify(patientData.allergies),
      patientData.medicalHistory || null,
      safeJsonStringify(patientData.currentMedications),
      safeJsonStringify(patientData.chronicConditions),
      safeJsonStringify(patientData.emergencyContacts),
      safeJsonStringify(patientData.photos),
      createdBy || patientData.createdBy || null,
    ];

    console.log('[PatientDB] Valores para inserção:', {
      name: values[0],
      hasAddress: !!values[7],
      hasAllergies: !!values[8],
      hasMedications: !!values[10],
    });

    const result = await pool.query(query, values);
    const patient = this.mapRowToPatient(result.rows[0]);

    // Buscar documentos do paciente
    const documents = await this.getPatientDocuments(patient.id);
    patient.documents = documents;

    return patient;
  }

  /**
   * Atualiza um paciente existente
   */
  async updatePatient(id: string, updates: Partial<Omit<Patient, 'id' | 'createdAt'>>): Promise<Patient | null> {
    const existing = await this.getPatientById(id);
    if (!existing) {
      return null;
    }

    const updateFields: string[] = [];
    const values: any[] = [];
    let paramCount = 0;

    if (updates.name !== undefined) {
      updateFields.push(`name = $${++paramCount}`);
      values.push(updates.name);
    }
    if (updates.cpf !== undefined) {
      updateFields.push(`cpf = $${++paramCount}`);
      values.push(updates.cpf || null);
    }
    if (updates.rg !== undefined) {
      updateFields.push(`rg = $${++paramCount}`);
      values.push(updates.rg || null);
    }
    if (updates.birthDate !== undefined) {
      updateFields.push(`birth_date = $${++paramCount}`);
      values.push(updates.birthDate || null);
    }
    if (updates.gender !== undefined) {
      updateFields.push(`gender = $${++paramCount}`);
      values.push(updates.gender || null);
    }
    if (updates.phone !== undefined) {
      updateFields.push(`phone = $${++paramCount}`);
      values.push(updates.phone || null);
    }
    if (updates.email !== undefined) {
      updateFields.push(`email = $${++paramCount}`);
      values.push(updates.email || null);
    }
    if (updates.address !== undefined) {
      updateFields.push(`address = $${++paramCount}`);
      values.push(updates.address ? JSON.stringify(updates.address) : null);
    }
    if (updates.allergies !== undefined) {
      updateFields.push(`allergies = $${++paramCount}`);
      values.push(updates.allergies ? JSON.stringify(updates.allergies) : null);
    }
    if (updates.medicalHistory !== undefined) {
      updateFields.push(`medical_history = $${++paramCount}`);
      values.push(updates.medicalHistory || null);
    }
    if (updates.currentMedications !== undefined) {
      updateFields.push(`current_medications = $${++paramCount}`);
      values.push(updates.currentMedications ? JSON.stringify(updates.currentMedications) : null);
    }
    if (updates.chronicConditions !== undefined) {
      updateFields.push(`chronic_conditions = $${++paramCount}`);
      values.push(updates.chronicConditions ? JSON.stringify(updates.chronicConditions) : null);
    }
    if (updates.emergencyContacts !== undefined) {
      updateFields.push(`emergency_contacts = $${++paramCount}`);
      values.push(updates.emergencyContacts ? JSON.stringify(updates.emergencyContacts) : null);
    }
    if (updates.photos !== undefined) {
      updateFields.push(`photos = $${++paramCount}`);
      values.push(updates.photos ? JSON.stringify(updates.photos) : null);
    }

    if (updateFields.length === 0) {
      return existing;
    }

    values.push(id);
    const query = `
      UPDATE patients 
      SET ${updateFields.join(', ')}
      WHERE id = $${++paramCount}
      RETURNING *
    `;

    const result = await pool.query(query, values);
    const patient = this.mapRowToPatient(result.rows[0]);

    // Buscar documentos do paciente
    const documents = await this.getPatientDocuments(patient.id);
    patient.documents = documents;

    return patient;
  }

  /**
   * Deleta um paciente
   */
  async deletePatient(id: string): Promise<boolean> {
    const result = await pool.query('DELETE FROM patients WHERE id = $1', [id]);
    return result.rowCount !== null && result.rowCount > 0;
  }

  /**
   * Adiciona uma foto ao paciente
   */
  async addPhoto(patientId: string, photoUrl: string): Promise<Patient | null> {
    const patient = await this.getPatientById(patientId);
    if (!patient) {
      return null;
    }

    const photos = patient.photos || [];
    if (!photos.includes(photoUrl)) {
      photos.push(photoUrl);
      return await this.updatePatient(patientId, { photos });
    }

    return patient;
  }

  /**
   * Remove uma foto do paciente
   */
  async removePhoto(patientId: string, photoUrl: string): Promise<Patient | null> {
    const patient = await this.getPatientById(patientId);
    if (!patient) {
      return null;
    }

    const photos = (patient.photos || []).filter((url) => url !== photoUrl);
    return await this.updatePatient(patientId, { photos });
  }

  /**
   * Adiciona um documento ao paciente
   */
  async addDocument(patientId: string, document: PatientDocument): Promise<Patient | null> {
    const query = `
      INSERT INTO patient_documents (patient_id, name, type, url, size)
      VALUES ($1, $2, $3, $4, $5)
      RETURNING *
    `;

    await pool.query(query, [
      patientId,
      document.name,
      document.type,
      document.url,
      document.size || null,
    ]);

    return await this.getPatientById(patientId);
  }

  /**
   * Remove um documento do paciente
   */
  async removeDocument(patientId: string, documentId: string): Promise<Patient | null> {
    await pool.query('DELETE FROM patient_documents WHERE id = $1 AND patient_id = $2', [
      documentId,
      patientId,
    ]);

    return await this.getPatientById(patientId);
  }

  /**
   * Busca documentos de um paciente
   */
  private async getPatientDocuments(patientId: string): Promise<PatientDocument[]> {
    const result = await pool.query(
      'SELECT * FROM patient_documents WHERE patient_id = $1 ORDER BY uploaded_at DESC',
      [patientId]
    );

    return result.rows.map((row: any) => ({
      id: row.id,
      name: row.name,
      type: row.type,
      url: row.url,
      uploadedAt: row.uploaded_at,
      size: row.size,
    }));
  }

  /**
   * Helper para fazer parse seguro de JSON
   */
  private safeJsonParse(value: any): any {
    // Se for null, undefined ou string vazia, retornar undefined
    if (value === null || value === undefined || value === '') {
      return undefined;
    }
    
    // Se já for um objeto/array, retornar como está
    if (typeof value === 'object' && !(value instanceof String)) {
      return value;
    }
    
    // Se for string, tentar fazer parse
    if (typeof value === 'string') {
      const trimmed = value.trim();
      if (trimmed === '' || trimmed === 'null' || trimmed === 'undefined') {
        return undefined;
      }
      try {
        return JSON.parse(trimmed);
      } catch (error) {
        console.error('[PatientDB] Erro ao fazer parse de JSON:', {
          value: trimmed.substring(0, 100),
          error: error instanceof Error ? error.message : String(error),
        });
        return undefined;
      }
    }
    
    return undefined;
  }

  /**
   * Mapeia uma linha do banco para o modelo Patient
   */
  private mapRowToPatient(row: any): Patient {
    try {
      // Parse seguro de birthDate
      let birthDate: string | undefined = undefined;
      if (row.birth_date) {
        try {
          birthDate = new Date(row.birth_date).toISOString();
        } catch (error) {
          console.error('[PatientDB] Erro ao parsear birthDate:', row.birth_date);
        }
      }

      // Parse seguro de createdAt e updatedAt
      let createdAt: string = '';
      let updatedAt: string = '';
      try {
        createdAt = row.created_at ? new Date(row.created_at).toISOString() : new Date().toISOString();
        updatedAt = row.updated_at ? new Date(row.updated_at).toISOString() : new Date().toISOString();
      } catch (error) {
        console.error('[PatientDB] Erro ao parsear timestamps:', error);
        createdAt = new Date().toISOString();
        updatedAt = new Date().toISOString();
      }

      return {
        id: row.id || '',
        name: row.name || '',
        cpf: row.cpf || undefined,
        rg: row.rg || undefined,
        birthDate: birthDate,
        gender: (row.gender as 'M' | 'F' | 'O' | 'N') || undefined,
        phone: row.phone || undefined,
        email: row.email || undefined,
        address: this.safeJsonParse(row.address),
        allergies: this.safeJsonParse(row.allergies) || undefined,
        medicalHistory: row.medical_history || undefined,
        currentMedications: this.safeJsonParse(row.current_medications) || undefined,
        chronicConditions: this.safeJsonParse(row.chronic_conditions) || undefined,
        emergencyContacts: this.safeJsonParse(row.emergency_contacts) || undefined,
        photos: this.safeJsonParse(row.photos) || [],
        documents: [], // Será preenchido separadamente
        createdAt: createdAt,
        updatedAt: updatedAt,
        createdBy: row.created_by || undefined,
      };
    } catch (error: any) {
      console.error('[PatientDB] Erro ao mapear paciente:', {
        rowId: row.id,
        error: error.message,
        stack: error.stack,
      });
      throw new Error(`Erro ao mapear paciente ${row.id}: ${error.message}`);
    }
  }
}

