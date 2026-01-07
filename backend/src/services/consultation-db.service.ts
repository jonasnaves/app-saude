import pool from '../config/database';

export interface Consultation {
  id: string;
  patientId?: string;
  patientName?: string;
  transcript: string;
  summary?: string;
  anamnesis?: string;
  prescription?: string;
  suggestedMedications?: string;
  suggestedQuestions?: string[];
  doctorNotes?: string;
  chatMessages?: any[];
  startedAt: string;
  endedAt?: string;
  createdAt: string;
  updatedAt: string;
}

/**
 * Serviço de armazenamento de consultas no PostgreSQL
 */
export class ConsultationDBService {
  /**
   * Cria uma nova consulta
   */
  async createConsultation(patientId?: string, patientName?: string, userId?: string): Promise<Consultation> {
    console.log('[ConsultationDB] createConsultation chamado:', {
      patientId,
      patientName,
      userId,
      hasPatientId: !!patientId,
      hasPatientName: !!patientName,
      patientIdType: typeof patientId,
      patientNameType: typeof patientName,
    });

    // Nota: A tabela consultations não tem campo user_id ainda
    // Por enquanto, vamos usar created_by se existir, ou adicionar depois
    const query = `
      INSERT INTO consultations (patient_id, patient_name)
      VALUES ($1, $2)
      RETURNING *
    `;

    const params = [patientId || null, patientName || null];
    console.log('[ConsultationDB] Executando INSERT com parâmetros:', {
      param1: params[0],
      param2: params[1],
      param1Type: typeof params[0],
      param2Type: typeof params[1],
    });

    const result = await pool.query(query, params);
    
    console.log('[ConsultationDB] Consulta criada no banco:', {
      id: result.rows[0]?.id,
      patient_id: result.rows[0]?.patient_id,
      patient_name: result.rows[0]?.patient_name,
      started_at: result.rows[0]?.started_at,
    });

    const consultation = this.mapRowToConsultation(result.rows[0]);
    
    console.log('[ConsultationDB] Consulta mapeada:', {
      id: consultation.id,
      patientId: consultation.patientId,
      patientName: consultation.patientName,
    });

    return consultation;
  }

  /**
   * Obtém uma consulta por ID
   */
  async getConsultationById(id: string): Promise<Consultation | null> {
    try {
      console.log('[ConsultationDB] Buscando consulta por ID:', id);
      const result = await pool.query('SELECT * FROM consultations WHERE id = $1', [id]);
      
      if (result.rows.length === 0) {
        console.log('[ConsultationDB] Consulta não encontrada:', id);
        return null;
      }

      console.log('[ConsultationDB] Consulta encontrada, mapeando...');
      const consultation = this.mapRowToConsultation(result.rows[0]);
      console.log('[ConsultationDB] Consulta mapeada com sucesso:', consultation.id);
      return consultation;
    } catch (error: any) {
      console.error('[ConsultationDB] Erro ao buscar consulta:', {
        id,
        error: error.message,
        stack: error.stack,
      });
      throw error;
    }
  }

  /**
   * Lista consultas com filtros
   * Se userId fornecido, filtra apenas consultas do usuário (quando implementado)
   */
  async getConsultations(patientId?: string, page: number = 1, limit: number = 50, userId?: string): Promise<{
    consultations: Consultation[];
    total: number;
    page: number;
    limit: number;
  }> {
    // Selecionar apenas campos necessários para listagem (excluir campos grandes)
    let query = `SELECT 
      id, 
      patient_id, 
      patient_name, 
      started_at, 
      ended_at, 
      created_at, 
      updated_at 
    FROM consultations`;
    const params: any[] = [];
    let paramCount = 0;
    const conditions: string[] = [];

    if (patientId) {
      conditions.push(`patient_id = $${++paramCount}`);
      params.push(patientId);
    }

    // TODO: Adicionar filtro por userId quando a tabela tiver campo user_id
    // if (userId) {
    //   conditions.push(`user_id = $${++paramCount}`);
    //   params.push(userId);
    // }

    if (conditions.length > 0) {
      query += ` WHERE ${conditions.join(' AND ')}`;
    }

    query += ' ORDER BY started_at DESC';
    query += ` LIMIT $${++paramCount} OFFSET $${++paramCount}`;
    params.push(limit, (page - 1) * limit);

    // Contar total
    let countQuery = 'SELECT COUNT(*) FROM consultations';
    const countParams: any[] = [];
    const countConditions: string[] = [];
    let countParamCount = 0;

    if (patientId) {
      countConditions.push(`patient_id = $${++countParamCount}`);
      countParams.push(patientId);
    }

    if (countConditions.length > 0) {
      countQuery += ` WHERE ${countConditions.join(' AND ')}`;
    }

    try {
      const [result, countResult] = await Promise.all([
        pool.query(query, params),
        pool.query(countQuery, countParams),
      ]);

      console.log('[ConsultationDB] getConsultations - Resultados:', {
        rowsCount: result.rows.length,
        total: countResult.rows[0]?.count,
      });

      // Mapear consultas com tratamento de erro individual (usando método otimizado para listagem)
      const consultations: Consultation[] = [];
      for (const row of result.rows) {
        try {
          const consultation = this.mapRowToConsultationList(row);
          consultations.push(consultation);
        } catch (error: any) {
          console.error('[ConsultationDB] Erro ao mapear consulta:', {
            consultationId: row.id,
            error: error.message,
          });
          // Continuar com as outras consultas mesmo se uma falhar
        }
      }

      const total = parseInt(countResult.rows[0]?.count || '0');

      return {
        consultations,
        total,
        page,
        limit,
      };
    } catch (error: any) {
      console.error('[ConsultationDB] Erro ao listar consultas:', {
        error: error.message,
        stack: error.stack,
      });
      throw error;
    }
  }

  /**
   * Atualiza a transcrição de uma consulta
   */
  async updateTranscript(consultationId: string, transcript: string): Promise<Consultation | null> {
    const query = `
      UPDATE consultations 
      SET transcript = $1, updated_at = CURRENT_TIMESTAMP
      WHERE id = $2
      RETURNING *
    `;

    const result = await pool.query(query, [transcript, consultationId]);
    if (result.rows.length === 0) {
      return null;
    }
    return this.mapRowToConsultation(result.rows[0]);
  }

  /**
   * Atualiza os resultados da análise em cascata
   */
  async updateCascadeAnalysis(
    consultationId: string,
    analysis: {
      summary?: string;
      anamnesis?: string;
      prescription?: string | null;
      suggestedMedications?: string | null;
      suggestedQuestions?: string[];
    }
  ): Promise<Consultation | null> {
    try {
      // Validação de entrada
      if (!consultationId || typeof consultationId !== 'string') {
        throw new Error('consultationId é obrigatório e deve ser uma string');
      }

      console.log('[ConsultationDB] Atualizando análise em cascata:', {
        consultationId,
        hasSummary: analysis.summary !== undefined,
        hasAnamnesis: analysis.anamnesis !== undefined,
        hasPrescription: analysis.prescription !== undefined,
        hasSuggestedQuestions: analysis.suggestedQuestions !== undefined,
      });

      const updateFields: string[] = [];
      const values: any[] = [];
      let paramCount = 0;

      // Validar e adicionar summary
      if (analysis.summary !== undefined) {
        const summaryValue = analysis.summary === null ? null : String(analysis.summary);
        updateFields.push(`summary = $${++paramCount}`);
        values.push(summaryValue);
        console.log('[ConsultationDB] Adicionando summary:', summaryValue?.substring(0, 50) + '...');
      }

      // Validar e adicionar anamnesis
      if (analysis.anamnesis !== undefined) {
        const anamnesisValue = analysis.anamnesis === null ? null : String(analysis.anamnesis);
        updateFields.push(`anamnesis = $${++paramCount}`);
        values.push(anamnesisValue);
        console.log('[ConsultationDB] Adicionando anamnesis:', anamnesisValue?.substring(0, 50) + '...');
      }

      // Validar e adicionar prescription (pode ser null)
      if (analysis.prescription !== undefined) {
        const prescriptionValue = analysis.prescription === null ? null : String(analysis.prescription);
        updateFields.push(`prescription = $${++paramCount}`);
        values.push(prescriptionValue);
        console.log('[ConsultationDB] Adicionando prescription:', prescriptionValue?.substring(0, 50) + '...');
      }

      // Validar e adicionar suggestedMedications (pode ser null)
      if (analysis.suggestedMedications !== undefined) {
        const suggestedMedicationsValue = analysis.suggestedMedications === null ? null : String(analysis.suggestedMedications);
        updateFields.push(`suggested_medications = $${++paramCount}`);
        values.push(suggestedMedicationsValue);
        console.log('[ConsultationDB] Adicionando suggestedMedications:', suggestedMedicationsValue?.substring(0, 50) + '...');
      }

      // Validar e adicionar suggestedQuestions
      if (analysis.suggestedQuestions !== undefined) {
        if (!Array.isArray(analysis.suggestedQuestions)) {
          console.warn('[ConsultationDB] suggestedQuestions não é um array, convertendo...');
          const questions = Array.isArray(analysis.suggestedQuestions) 
            ? analysis.suggestedQuestions 
            : [];
          updateFields.push(`suggested_questions = $${++paramCount}`);
          values.push(JSON.stringify(questions));
        } else {
          updateFields.push(`suggested_questions = $${++paramCount}`);
          values.push(JSON.stringify(analysis.suggestedQuestions));
        }
        console.log('[ConsultationDB] Adicionando suggestedQuestions:', analysis.suggestedQuestions?.length || 0, 'perguntas');
      }

      if (updateFields.length === 0) {
        console.log('[ConsultationDB] Nenhum campo para atualizar, retornando consulta atual');
        return await this.getConsultationById(consultationId);
      }

      values.push(consultationId);
      const query = `
        UPDATE consultations 
        SET ${updateFields.join(', ')}, updated_at = CURRENT_TIMESTAMP
        WHERE id = $${++paramCount}
        RETURNING *
      `;

      console.log('[ConsultationDB] Executando query:', query.substring(0, 200) + '...');
      console.log('[ConsultationDB] Valores:', values.map((v, i) => `$${i + 1}: ${typeof v} (${v?.toString().substring(0, 50) || 'null'}...)`));

      const result = await pool.query(query, values);
      
      if (result.rows.length === 0) {
        console.error('[ConsultationDB] Nenhuma linha atualizada. ConsultationId pode não existir:', consultationId);
        return null;
      }

      const updated = this.mapRowToConsultation(result.rows[0]);
      console.log('[ConsultationDB] Análise em cascata atualizada com sucesso');
      return updated;
    } catch (error: any) {
      console.error('[ConsultationDB] Erro ao atualizar análise em cascata:', {
        consultationId,
        error: error.message,
        stack: error.stack,
        analysis: {
          hasSummary: analysis.summary !== undefined,
          hasAnamnesis: analysis.anamnesis !== undefined,
          hasPrescription: analysis.prescription !== undefined,
          hasSuggestedQuestions: analysis.suggestedQuestions !== undefined,
        },
      });
      throw new Error(`Falha ao atualizar análise em cascata: ${error.message}`);
    }
  }

  /**
   * Atualiza as notas do médico
   */
  async updateDoctorNotes(consultationId: string, doctorNotes: string): Promise<Consultation | null> {
    const query = `
      UPDATE consultations 
      SET doctor_notes = $1, updated_at = CURRENT_TIMESTAMP
      WHERE id = $2
      RETURNING *
    `;

    const result = await pool.query(query, [doctorNotes, consultationId]);
    if (result.rows.length === 0) {
      return null;
    }
    return this.mapRowToConsultation(result.rows[0]);
  }

  /**
   * Atualiza o histórico de chat
   */
  async updateChatMessages(consultationId: string, chatMessages: any[]): Promise<Consultation | null> {
    const query = `
      UPDATE consultations 
      SET chat_messages = $1, updated_at = CURRENT_TIMESTAMP
      WHERE id = $2
      RETURNING *
    `;

    const result = await pool.query(query, [JSON.stringify(chatMessages), consultationId]);
    if (result.rows.length === 0) {
      return null;
    }
    return this.mapRowToConsultation(result.rows[0]);
  }

  /**
   * Atualiza campos parciais do prontuário médico
   * Permite atualizar qualquer combinação de campos, aceitando null para limpar campos
   */
  async updateMedicalRecordPartial(
    consultationId: string,
    data: {
      patientId?: string | null;
      transcript?: string | null;
      summary?: string | null;
      anamnesis?: string | null;
      prescription?: string | null;
      suggestedMedications?: string | null;
      suggestedQuestions?: string[] | null;
      doctorNotes?: string | null;
      chatMessages?: any[] | null;
    }
  ): Promise<Consultation | null> {
    try {
      // Validação de entrada
      if (!consultationId || typeof consultationId !== 'string') {
        throw new Error('consultationId é obrigatório e deve ser uma string');
      }

      // Verificar se a consulta existe
      const existingConsultation = await this.getConsultationById(consultationId);
      if (!existingConsultation) {
        console.error('[ConsultationDB] Consulta não encontrada para atualização:', consultationId);
        return null;
      }

      console.log('[ConsultationDB] Atualizando prontuário parcial:', {
        consultationId,
        fieldsToUpdate: Object.keys(data).filter(key => data[key as keyof typeof data] !== undefined),
        existingPatientId: existingConsultation.patientId,
        existingPatientName: existingConsultation.patientName,
        newPatientId: data.patientId,
        newPatientName: data.patientId !== undefined ? 'será atualizado via patientId' : 'não fornecido',
      });

      const updateFields: string[] = [];
      const values: any[] = [];
      let paramCount = 0;

      // Processar cada campo se fornecido (undefined = não atualizar, null = limpar)
      if (data.patientId !== undefined) {
        updateFields.push(`patient_id = $${++paramCount}`);
        const patientIdValue = data.patientId === null ? null : String(data.patientId);
        values.push(patientIdValue);
        console.log('[ConsultationDB] Atualizando patientId:', {
          oldValue: existingConsultation.patientId,
          newValue: patientIdValue,
          willChange: existingConsultation.patientId !== patientIdValue,
          isNull: patientIdValue === null,
        });
      } else {
        console.log('[ConsultationDB] patientId não será atualizado (undefined)');
      }
      if (data.transcript !== undefined) {
        updateFields.push(`transcript = $${++paramCount}`);
        values.push(data.transcript === null ? null : String(data.transcript));
      }

      if (data.summary !== undefined) {
        updateFields.push(`summary = $${++paramCount}`);
        values.push(data.summary === null ? null : String(data.summary));
      }

      if (data.anamnesis !== undefined) {
        updateFields.push(`anamnesis = $${++paramCount}`);
        values.push(data.anamnesis === null ? null : String(data.anamnesis));
      }

      if (data.prescription !== undefined) {
        updateFields.push(`prescription = $${++paramCount}`);
        values.push(data.prescription === null ? null : String(data.prescription));
      }

      if (data.suggestedMedications !== undefined) {
        updateFields.push(`suggested_medications = $${++paramCount}`);
        values.push(data.suggestedMedications === null ? null : String(data.suggestedMedications));
      }

      if (data.suggestedQuestions !== undefined) {
        updateFields.push(`suggested_questions = $${++paramCount}`);
        if (data.suggestedQuestions === null) {
          values.push(null);
        } else if (Array.isArray(data.suggestedQuestions)) {
          values.push(JSON.stringify(data.suggestedQuestions));
        } else {
          values.push(JSON.stringify([]));
        }
      }

      if (data.doctorNotes !== undefined) {
        updateFields.push(`doctor_notes = $${++paramCount}`);
        values.push(data.doctorNotes === null ? null : String(data.doctorNotes));
      }

      if (data.chatMessages !== undefined) {
        updateFields.push(`chat_messages = $${++paramCount}`);
        if (data.chatMessages === null) {
          values.push(null);
        } else if (Array.isArray(data.chatMessages)) {
          values.push(JSON.stringify(data.chatMessages));
        } else {
          values.push(JSON.stringify([]));
        }
      }

      // Se não há campos para atualizar, retornar consulta atual
      if (updateFields.length === 0) {
        console.log('[ConsultationDB] Nenhum campo para atualizar');
        return existingConsultation;
      }

      // Adicionar consultationId e updated_at
      values.push(consultationId);
      const query = `
        UPDATE consultations 
        SET ${updateFields.join(', ')}, updated_at = CURRENT_TIMESTAMP
        WHERE id = $${++paramCount}
        RETURNING *
      `;

      console.log('[ConsultationDB] Executando UPDATE:', {
        query: query.substring(0, 200) + '...',
        values: values.map((v, i) => `$${i + 1}: ${v === null ? 'NULL' : (typeof v === 'string' ? v.substring(0, 50) : String(v))}`),
        updateFieldsCount: updateFields.length,
      });

      const result = await pool.query(query, values);

      if (result.rows.length === 0) {
        console.error('[ConsultationDB] Nenhuma linha atualizada');
        return null;
      }

      console.log('[ConsultationDB] UPDATE executado com sucesso. Linha retornada:', {
        id: result.rows[0]?.id,
        patient_id: result.rows[0]?.patient_id,
        patient_name: result.rows[0]?.patient_name,
      });

      const updated = this.mapRowToConsultation(result.rows[0]);
      console.log('[ConsultationDB] Prontuário parcial atualizado com sucesso:', {
        consultationId: updated.id,
        patientId: updated.patientId,
        patientName: updated.patientName,
        hasPatientId: !!updated.patientId,
        hasPatientName: !!updated.patientName,
      });
      return updated;
    } catch (error: any) {
      console.error('[ConsultationDB] Erro ao atualizar prontuário parcial:', {
        consultationId,
        error: error.message,
        stack: error.stack,
      });
      throw new Error(`Falha ao atualizar prontuário parcial: ${error.message}`);
    }
  }

  /**
   * Mapeia uma linha do banco para o objeto Consultation (versão otimizada para listagem)
   * Retorna apenas campos essenciais, sem campos grandes como transcript, anamnesis, etc.
   */
  private mapRowToConsultationList(row: any): Consultation {
    try {
      const startedAt = row.started_at ? new Date(row.started_at).toISOString() : new Date().toISOString();
      const endedAt = row.ended_at ? new Date(row.ended_at).toISOString() : undefined;
      const createdAt = row.created_at ? new Date(row.created_at).toISOString() : new Date().toISOString();
      const updatedAt = row.updated_at ? new Date(row.updated_at).toISOString() : new Date().toISOString();

      return {
        id: String(row.id || ''),
        patientId: row.patient_id ? String(row.patient_id) : undefined,
        patientName: row.patient_name ? String(row.patient_name) : undefined,
        // Campos grandes não são retornados na listagem para economizar memória
        transcript: '',
        summary: undefined,
        anamnesis: undefined,
        prescription: undefined,
        suggestedMedications: undefined,
        suggestedQuestions: undefined,
        doctorNotes: undefined,
        chatMessages: undefined,
        startedAt: startedAt,
        endedAt: endedAt,
        createdAt: createdAt,
        updatedAt: updatedAt,
      };
    } catch (error: any) {
      console.error('[ConsultationDB] Erro ao mapear consulta (listagem):', {
        rowId: row?.id,
        error: error.message,
      });
      throw new Error(`Erro ao mapear consulta ${row?.id || 'desconhecido'}: ${error.message}`);
    }
  }

  /**
   * Finaliza uma consulta
   */
  async endConsultation(consultationId: string): Promise<Consultation | null> {
    const query = `
      UPDATE consultations 
      SET ended_at = CURRENT_TIMESTAMP, updated_at = CURRENT_TIMESTAMP
      WHERE id = $1
      RETURNING *
    `;

    const result = await pool.query(query, [consultationId]);
    if (result.rows.length === 0) {
      return null;
    }
    return this.mapRowToConsultation(result.rows[0]);
  }

  /**
   * Retoma uma consulta (remove ended_at para permitir continuar)
   */
  async resumeConsultation(consultationId: string): Promise<Consultation | null> {
    const query = `
      UPDATE consultations 
      SET ended_at = NULL, updated_at = CURRENT_TIMESTAMP
      WHERE id = $1
      RETURNING *
    `;

    const result = await pool.query(query, [consultationId]);
    if (result.rows.length === 0) {
      return null;
    }
    return this.mapRowToConsultation(result.rows[0]);
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
    if (typeof value === 'object' && !(value instanceof String) && !Array.isArray(value)) {
      // Se for um objeto Date ou outro tipo especial, retornar undefined
      if (value instanceof Date) {
        return undefined;
      }
      return value;
    }
    
    // Se já for array, retornar como está
    if (Array.isArray(value)) {
      return value;
    }
    
    // Se for string, tentar fazer parse
    if (typeof value === 'string') {
      const trimmed = value.trim();
      if (trimmed === '' || trimmed === 'null' || trimmed === 'undefined') {
        return undefined;
      }
      try {
        const parsed = JSON.parse(trimmed);
        return parsed;
      } catch (error) {
        console.error('[ConsultationDB] Erro ao fazer parse de JSON:', {
          value: trimmed.substring(0, 100),
          error: error instanceof Error ? error.message : String(error),
        });
        return undefined;
      }
    }
    
    return undefined;
  }

  /**
   * Mapeia uma linha do banco para o modelo Consultation
   */
  private mapRowToConsultation(row: any): Consultation {
    try {
      // Parse seguro de timestamps
      let startedAt: string = '';
      let endedAt: string | undefined = undefined;
      let createdAt: string = '';
      let updatedAt: string = '';

      try {
        startedAt = row.started_at ? new Date(row.started_at).toISOString() : new Date().toISOString();
        endedAt = row.ended_at ? new Date(row.ended_at).toISOString() : undefined;
        createdAt = row.created_at ? new Date(row.created_at).toISOString() : new Date().toISOString();
        updatedAt = row.updated_at ? new Date(row.updated_at).toISOString() : new Date().toISOString();
      } catch (error) {
        console.error('[ConsultationDB] Erro ao parsear timestamps:', error);
        const now = new Date().toISOString();
        startedAt = now;
        createdAt = now;
        updatedAt = now;
      }

      // Parse seguro de suggested_questions (pode ser JSONB ou array)
      let suggestedQuestions: string[] | undefined = undefined;
      try {
        const parsed = this.safeJsonParse(row.suggested_questions);
        if (Array.isArray(parsed)) {
          suggestedQuestions = parsed.map((q: any) => String(q));
        }
      } catch (error) {
        console.error('[ConsultationDB] Erro ao parsear suggested_questions:', error);
      }

      // Parse seguro de chat_messages (pode ser JSONB ou array)
      let chatMessages: any[] | undefined = undefined;
      try {
        const parsed = this.safeJsonParse(row.chat_messages);
        if (Array.isArray(parsed)) {
          chatMessages = parsed;
        }
      } catch (error) {
        console.error('[ConsultationDB] Erro ao parsear chat_messages:', error);
      }

      // Verificar se o campo suggested_medications existe (pode não existir se migração não foi aplicada)
      let suggestedMedications: string | undefined = undefined;
      if (row.hasOwnProperty('suggested_medications') && row.suggested_medications != null) {
        suggestedMedications = String(row.suggested_medications);
      }

      return {
        id: String(row.id || ''),
        patientId: row.patient_id ? String(row.patient_id) : undefined,
        patientName: row.patient_name ? String(row.patient_name) : undefined,
        transcript: row.transcript ? String(row.transcript) : '',
        summary: row.summary ? String(row.summary) : undefined,
        anamnesis: row.anamnesis ? String(row.anamnesis) : undefined,
        prescription: row.prescription ? String(row.prescription) : undefined,
        suggestedMedications: suggestedMedications,
        suggestedQuestions: suggestedQuestions,
        doctorNotes: row.doctor_notes ? String(row.doctor_notes) : undefined,
        chatMessages: chatMessages,
        startedAt: startedAt,
        endedAt: endedAt,
        createdAt: createdAt,
        updatedAt: updatedAt,
      };
    } catch (error: any) {
      console.error('[ConsultationDB] Erro ao mapear consulta:', {
        rowId: row?.id,
        rowKeys: row ? Object.keys(row) : [],
        error: error.message,
        stack: error.stack,
      });
      throw new Error(`Erro ao mapear consulta ${row?.id || 'desconhecido'}: ${error.message}`);
    }
  }
}

