import OpenAI from 'openai';

export class OpenAIService {
  private openai: OpenAI;

  constructor() {
    const apiKey = process.env.OPENAI_API_KEY;
    if (!apiKey) {
      throw new Error('OPENAI_API_KEY não configurada no ambiente');
    }
    this.openai = new OpenAI({ apiKey });
  }

  /**
   * Gera análise clínica incremental usando GPT-4
   * @param transcript Transcrição completa acumulada
   * @param previousInsights Insights anteriores (anamnese anterior)
   * @returns Análise com anamnese, prescrição e perguntas sugeridas
   */
  async analyzeIncremental(
    transcript: string,
    previousInsights?: string
  ): Promise<{
    anamnesis: string;
    prescription: string | null;
    suggestedQuestions: string[];
  }> {
    try {
      const systemPrompt = `Você é um assistente médico especializado em análise clínica. 
Sua função é analisar transcrições de consultas médicas e extrair informações estruturadas.

Analise a transcrição e retorne:
1. ANAMNESE: Informações do paciente (sintomas, histórico, queixas, sinais vitais mencionados)
2. PRESCRIÇÃO: Apenas se houver menção explícita a medicamentos, dosagens ou prescrições. Se não houver, retorne null.
3. PERGUNTAS SUGERIDAS: 2-4 perguntas clínicas relevantes que o médico deveria fazer para aprofundar o diagnóstico.

Seja objetivo e focado em informações clínicas relevantes.`;

      const userPrompt = `Transcrição atual da consulta:
${transcript}

${previousInsights ? `Insights anteriores:\n${previousInsights}\n\n` : ''}
Analise e retorne em formato JSON com as chaves: anamnesis, prescription (null se não houver), suggestedQuestions.`;

      const response = await this.openai.chat.completions.create({
        model: 'gpt-4o-mini',
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user', content: userPrompt },
        ],
        response_format: { type: 'json_object' },
        temperature: 0.3,
      });

      const content = response.choices[0]?.message?.content;
      if (!content) {
        throw new Error('Resposta vazia da API OpenAI');
      }

      const analysis = JSON.parse(content);

      return {
        anamnesis: analysis.anamnesis || '',
        prescription: analysis.prescription || null,
        suggestedQuestions: Array.isArray(analysis.suggestedQuestions)
          ? analysis.suggestedQuestions
          : [],
      };
    } catch (error: any) {
      console.error('Erro ao analisar transcrição:', error);
      throw new Error(
        `Falha na análise: ${error.message || 'Erro desconhecido'}`
      );
    }
  }

  /**
   * Gera resumo clínico completo da consulta
   * @param transcript Transcrição completa da consulta
   * @returns Resumo estruturado
   */
  async generateClinicalSummary(transcript: string): Promise<{
    anamnesis: string;
    physicalExam: string;
    diagnosisSuggestions: string[];
    conduct: string;
  }> {
    try {
      const systemPrompt = `Você é um assistente médico especializado em gerar resumos clínicos estruturados.
Analise a transcrição completa da consulta e gere um resumo profissional.`;

      const userPrompt = `Transcrição da consulta:
${transcript}

Gere um resumo clínico estruturado em formato JSON com:
- anamnesis: Informações do paciente
- physicalExam: Exame físico mencionado
- diagnosisSuggestions: Sugestões de diagnóstico
- conduct: Conduta médica/prescrição`;

      const response = await this.openai.chat.completions.create({
        model: 'gpt-4o-mini',
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user', content: userPrompt },
        ],
        response_format: { type: 'json_object' },
        temperature: 0.3,
      });

      const content = response.choices[0]?.message?.content;
      if (!content) {
        throw new Error('Resposta vazia da API OpenAI');
      }

      return JSON.parse(content);
    } catch (error: any) {
      console.error('Erro ao gerar resumo clínico:', error);
      throw new Error(
        `Falha ao gerar resumo: ${error.message || 'Erro desconhecido'}`
      );
    }
  }

  /**
   * Agente 1: Gera resumo clínico da transcrição
   * @param transcript Transcrição completa da consulta
   * @returns Resumo clínico
   */
  async generateSummary(transcript: string): Promise<{ summary: string }> {
    try {
      const systemPrompt = `Você é um assistente médico especializado em gerar resumos clínicos concisos e objetivos.
Sua função é analisar a transcrição de uma consulta médica e gerar um resumo claro e estruturado.
IMPORTANTE: Retorne o texto formatado de forma legível, não em formato JSON puro. Use parágrafos, tópicos e estrutura clara.`;

      const userPrompt = `Contexto em JSON:
{
  "transcript": ${JSON.stringify(transcript)}
}

Gere um resumo clínico conciso e bem formatado. Retorne em formato JSON com a chave "summary" contendo texto formatado e legível, não JSON aninhado.`;

      const response = await this.openai.chat.completions.create({
        model: 'gpt-4o-mini',
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user', content: userPrompt },
        ],
        response_format: { type: 'json_object' },
        temperature: 0.3,
      });

      const content = response.choices[0]?.message?.content;
      if (!content) {
        throw new Error('Resposta vazia da API OpenAI');
      }

      const result = JSON.parse(content);
      return {
        summary: result.summary || '',
      };
    } catch (error: any) {
      console.error('Erro ao gerar resumo:', error);
      throw new Error(
        `Falha ao gerar resumo: ${error.message || 'Erro desconhecido'}`
      );
    }
  }

  /**
   * Agente 2: Gera anamnese estruturada
   * @param context Contexto com transcript e summary
   * @returns Anamnese estruturada
   */
  async generateAnamnesis(context: {
    transcript: string;
    summary: string;
  }): Promise<{ anamnesis: string }> {
    try {
      const systemPrompt = `Você é um assistente médico especializado em estruturar anamneses clínicas.
Sua função é analisar a transcrição e o resumo da consulta e gerar uma anamnese estruturada e completa.
IMPORTANTE: Retorne o texto formatado de forma legível, organizado em seções claras separadas por quebras de linha duplas.
Cada seção deve começar com o título da seção seguido de dois pontos (:).`;

      const userPrompt = `Contexto em JSON:
{
  "transcript": ${JSON.stringify(context.transcript)},
  "summary": ${JSON.stringify(context.summary)}
}

Gere uma anamnese clínica estruturada e bem formatada. Retorne em formato JSON com a chave "anamnesis" contendo texto formatado e legível, organizado nas seguintes seções (cada uma em uma linha separada com quebra de linha dupla):

**Queixa Principal:**
[Liste as queixas principais do paciente, separadas por vírgulas]

**História da Doença:**
[Descreva a história da doença atual, incluindo duração, início, fatores associados, etc.]

**Exame Físico:**
[Descreva os achados do exame físico, se disponíveis. Se não houver informações, escreva "Não disponível na transcrição"]

**Hipótese Diagnóstica:**
[Liste as hipóteses diagnósticas, separadas por vírgulas]

**Conduta:**
[Liste as condutas recomendadas, separadas por vírgulas ou em parágrafos]

IMPORTANTE: Use o formato de texto simples com títulos de seção claros, não use JSON aninhado dentro do campo anamnesis.`;

      const response = await this.openai.chat.completions.create({
        model: 'gpt-4o-mini',
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user', content: userPrompt },
        ],
        response_format: { type: 'json_object' },
        temperature: 0.3,
      });

      const content = response.choices[0]?.message?.content;
      if (!content) {
        throw new Error('Resposta vazia da API OpenAI');
      }

      const result = JSON.parse(content);
      return {
        anamnesis: result.anamnesis || '',
      };
    } catch (error: any) {
      console.error('Erro ao gerar anamnese:', error);
      throw new Error(
        `Falha ao gerar anamnese: ${error.message || 'Erro desconhecido'}`
      );
    }
  }

  /**
   * Agente 3: Extrai e estrutura prescrições + sugere medicamentos
   * @param context Contexto com transcript, summary e anamnesis
   * @returns Prescrição mencionada e medicamentos sugeridos pela IA
   */
  async generatePrescription(context: {
    transcript: string;
    summary: string;
    anamnesis: string;
  }): Promise<{ 
    prescription: string | null;
    suggestedMedications: string | null;
  }> {
    try {
      const systemPrompt = `Você é um assistente médico especializado em identificar prescrições médicas e sugerir medicamentos.
Sua função tem duas partes:
1. IDENTIFICAR prescrições mencionadas na transcrição (o que o médico realmente prescreveu)
2. SUGERIR medicamentos baseado no contexto clínico (sugestões da IA baseadas em sintomas, diagnóstico e anamnese)

IMPORTANTE:
- "prescription": Apenas medicamentos, dosagens e orientações que foram MENCIONADOS ou PRESCRITOS na transcrição. Se não houver menção, retorne null.
- "suggestedMedications": Medicamentos que a IA SUGERE baseado na análise clínica, mesmo que não tenham sido mencionados. Inclua dosagens sugeridas e justificativa breve. Se não houver sugestões relevantes, retorne null.

Retorne ambos os campos formatados de forma legível, com medicamentos, dosagens e orientações claramente organizados.`;

      const userPrompt = `Contexto em JSON:
{
  "transcript": ${JSON.stringify(context.transcript)},
  "summary": ${JSON.stringify(context.summary)},
  "anamnesis": ${JSON.stringify(context.anamnesis)}
}

Analise e retorne em formato JSON com duas chaves:
1. "prescription": Prescrições MENCIONADAS na transcrição (ou null se não houver)
2. "suggestedMedications": Medicamentos SUGERIDOS pela IA baseado no contexto clínico (ou null se não houver sugestões relevantes)

Ambos devem ser texto formatado e legível, não JSON aninhado.`;

      const response = await this.openai.chat.completions.create({
        model: 'gpt-4o-mini',
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user', content: userPrompt },
        ],
        response_format: { type: 'json_object' },
        temperature: 0.3,
      });

      const content = response.choices[0]?.message?.content;
      if (!content) {
        throw new Error('Resposta vazia da API OpenAI');
      }

      const result = JSON.parse(content);
      return {
        prescription: result.prescription || null,
        suggestedMedications: result.suggestedMedications || null,
      };
    } catch (error: any) {
      console.error('Erro ao gerar prescrição:', error);
      throw new Error(
        `Falha ao gerar prescrição: ${error.message || 'Erro desconhecido'}`
      );
    }
  }

  /**
   * Agente 4: Gera perguntas sugeridas
   * @param context Contexto completo com todos os dados anteriores
   * @returns Lista de perguntas sugeridas
   */
  async generateSuggestedQuestions(context: {
    transcript: string;
    summary: string;
    anamnesis: string;
    prescription: string | null;
  }): Promise<{ suggestedQuestions: string[] }> {
    try {
      const systemPrompt = `Você é um assistente médico especializado em sugerir perguntas clínicas relevantes.
Sua função é analisar todo o contexto da consulta e sugerir 2-4 perguntas que o médico deveria fazer para aprofundar o diagnóstico ou esclarecer pontos importantes.`;

      const userPrompt = `Contexto em JSON:
{
  "transcript": ${JSON.stringify(context.transcript)},
  "summary": ${JSON.stringify(context.summary)},
  "anamnesis": ${JSON.stringify(context.anamnesis)},
  "prescription": ${context.prescription ? JSON.stringify(context.prescription) : null}
}

Gere 2-4 perguntas clínicas relevantes em formato JSON com a chave "suggestedQuestions" (array de strings).`;

      const response = await this.openai.chat.completions.create({
        model: 'gpt-4o-mini',
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user', content: userPrompt },
        ],
        response_format: { type: 'json_object' },
        temperature: 0.3,
      });

      const content = response.choices[0]?.message?.content;
      if (!content) {
        throw new Error('Resposta vazia da API OpenAI');
      }

      const result = JSON.parse(content);
      return {
        suggestedQuestions: Array.isArray(result.suggestedQuestions)
          ? result.suggestedQuestions
          : [],
      };
    } catch (error: any) {
      console.error('Erro ao gerar perguntas sugeridas:', error);
      throw new Error(
        `Falha ao gerar perguntas: ${error.message || 'Erro desconhecido'}`
      );
    }
  }

  /**
   * Formata dados do paciente em texto estruturado para contexto
   */
  private formatPatientData(patientData: any): string {
    if (!patientData) return '';
    
    const parts: string[] = [];
    parts.push('=== DADOS DO PACIENTE ===');
    
    if (patientData.name) parts.push(`Nome: ${patientData.name}`);
    if (patientData.cpf) parts.push(`CPF: ${patientData.cpf}`);
    if (patientData.birthDate) parts.push(`Data de Nascimento: ${patientData.birthDate}`);
    if (patientData.gender) parts.push(`Sexo: ${patientData.gender}`);
    if (patientData.email) parts.push(`Email: ${patientData.email}`);
    if (patientData.phone) parts.push(`Telefone: ${patientData.phone}`);
    
    if (patientData.address) {
      parts.push(`\nEndereço:`);
      if (patientData.address.street) parts.push(`  Rua: ${patientData.address.street}`);
      if (patientData.address.number) parts.push(`  Número: ${patientData.address.number}`);
      if (patientData.address.complement) parts.push(`  Complemento: ${patientData.address.complement}`);
      if (patientData.address.neighborhood) parts.push(`  Bairro: ${patientData.address.neighborhood}`);
      if (patientData.address.city) parts.push(`  Cidade: ${patientData.address.city}`);
      if (patientData.address.state) parts.push(`  Estado: ${patientData.address.state}`);
      if (patientData.address.zipCode) parts.push(`  CEP: ${patientData.address.zipCode}`);
    }
    
    if (patientData.allergies && patientData.allergies.length > 0) {
      parts.push(`\nAlergias: ${patientData.allergies.join(', ')}`);
    }
    
    if (patientData.currentMedications && patientData.currentMedications.length > 0) {
      parts.push(`\nMedicamentos em uso: ${patientData.currentMedications.join(', ')}`);
    }
    
    if (patientData.medicalHistory) {
      parts.push(`\nHistórico Médico: ${patientData.medicalHistory}`);
    }
    
    if (patientData.familyHistory) {
      parts.push(`\nHistórico Familiar: ${patientData.familyHistory}`);
    }
    
    if (patientData.notes) {
      parts.push(`\nObservações: ${patientData.notes}`);
    }
    
    parts.push('========================\n');
    
    return parts.join('\n');
  }

  /**
   * Método principal: Executa todos os agentes em cascata
   * @param transcript Transcrição completa da consulta
   * @param doctorNotes Notas do médico (opcional)
   * @param patientData Dados do paciente (opcional)
   * @returns Resultado completo de todos os agentes
   */
  async processCascade(
    transcript: string,
    doctorNotes?: string,
    patientData?: any
  ): Promise<{
    summary: string;
    anamnesis: string;
    prescription: string | null;
    suggestedMedications: string | null;
    suggestedQuestions: string[];
  }> {
    try {
      // Formatar dados do paciente
      const patientContext = patientData ? this.formatPatientData(patientData) : '';
      
      // Contexto completo incluindo notas do médico e dados do paciente
      let fullContext = transcript;
      if (patientContext) {
        fullContext = `${patientContext}${transcript}`;
      }
      if (doctorNotes) {
        fullContext = `${fullContext}\n\nNOTAS DO MÉDICO:\n${doctorNotes}`;
      }

      // Agente 1: Resumo
      const { summary } = await this.generateSummary(fullContext);

      // Agente 2: Anamnese
      const { anamnesis } = await this.generateAnamnesis({
        transcript: fullContext,
        summary,
      });

      // Agente 3: Prescrições e Medicamentos Sugeridos
      const { prescription, suggestedMedications } = await this.generatePrescription({
        transcript: fullContext,
        summary,
        anamnesis,
      });

      // Agente 4: Perguntas Sugeridas
      const { suggestedQuestions } = await this.generateSuggestedQuestions({
        transcript: fullContext,
        summary,
        anamnesis,
        prescription,
      });

      return {
        summary,
        anamnesis,
        prescription,
        suggestedMedications,
        suggestedQuestions,
      };
    } catch (error: any) {
      console.error('Erro ao processar cascata:', error);
      throw new Error(
        `Falha no processamento em cascata: ${error.message || 'Erro desconhecido'}`
      );
    }
  }

  /**
   * Chat com IA usando contexto completo do atendimento
   * @param message Mensagem do usuário
   * @param context Contexto completo (transcript, summary, anamnesis, prescription, notes)
   * @returns Resposta da IA
   */
  async chatWithContext(
    message: string,
    context: {
      transcript: string;
      summary: string;
      anamnesis: string;
      prescription: string | null;
      notes: string;
    }
  ): Promise<string> {
    try {
      const systemPrompt = `Você é um assistente médico especializado em ajudar médicos durante consultas.
Você tem acesso a todo o contexto do atendimento atual, incluindo transcrição, resumo, anamnese, prescrições e notas do médico.
Sua função é responder perguntas do médico de forma clara, objetiva e útil, sempre baseando-se no contexto fornecido.
Se a pergunta não puder ser respondida com base no contexto, informe isso claramente.`;

      const contextText = `
CONTEXTO DO ATENDIMENTO:

TRANSCRIÇÃO:
${context.transcript}

${context.summary ? `RESUMO CLÍNICO:\n${context.summary}\n` : ''}
${context.anamnesis ? `ANAMNESE:\n${context.anamnesis}\n` : ''}
${context.prescription ? `PRESCRIÇÃO:\n${context.prescription}\n` : ''}
${context.notes ? `NOTAS DO MÉDICO:\n${context.notes}\n` : ''}
`;

      const userPrompt = `${contextText}

PERGUNTA DO MÉDICO:
${message}

Responda de forma clara e objetiva, baseando-se no contexto fornecido.`;

      const response = await this.openai.chat.completions.create({
        model: 'gpt-4o-mini',
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user', content: userPrompt },
        ],
        temperature: 0.7,
      });

      const content = response.choices[0]?.message?.content;
      if (!content) {
        throw new Error('Resposta vazia da API OpenAI');
      }

      return content;
    } catch (error: any) {
      console.error('Erro no chat com IA:', error);
      throw new Error(
        `Falha no chat: ${error.message || 'Erro desconhecido'}`
      );
    }
  }

  /**
   * Chat com IA para hubs (Support, Business) com contexto do próprio chat
   * @param mode Modo do chat: 'medical', 'legal', 'marketing', 'business'
   * @param message Mensagem do usuário
   * @param chatHistory Histórico de mensagens do chat
   * @param context Contexto adicional (opcional)
   * @returns Resposta da IA
   */
  async chatWithHubContext(
    mode: string,
    message: string,
    chatHistory: Array<{ role: string; content: string }> = [],
    context?: any
  ): Promise<string> {
    try {
      // Definir prompts do sistema baseado no modo
      const modePrompts: Record<string, string> = {
        medical: `Você é um assistente médico especializado em ajudar profissionais de saúde.
Sua função é responder perguntas médicas de forma clara, objetiva e baseada em evidências.
Sempre enfatize que suas respostas são sugestões e não substituem a avaliação clínica presencial.`,
        legal: `Você é um assistente jurídico especializado em direito médico e saúde.
Sua função é fornecer informações jurídicas relevantes para profissionais de saúde.
Sempre enfatize que suas respostas são informativas e não constituem aconselhamento jurídico formal.`,
        marketing: `Você é um especialista em marketing para profissionais de saúde.
Sua função é ajudar com estratégias de marketing, comunicação e relacionamento com pacientes.
Forneça sugestões práticas e éticas para promover serviços de saúde.`,
        business: `Você é um consultor de negócios especializado em gestão de clínicas e consultórios médicos.
Sua função é ajudar com questões de gestão, operações, finanças e estratégia de negócios em saúde.
Forneça insights práticos e acionáveis.`,
      };

      const systemPrompt = modePrompts[mode] || modePrompts.medical;

      // Construir mensagens incluindo histórico
      const messages: Array<{ role: string; content: string }> = [
        { role: 'system', content: systemPrompt },
      ];

      // Adicionar contexto se fornecido
      if (context) {
        let contextText = 'CONTEXTO ADICIONAL:\n';
        if (typeof context === 'string') {
          contextText += context;
        } else if (typeof context === 'object') {
          contextText += JSON.stringify(context, null, 2);
        }
        messages.push({ role: 'user', content: contextText });
      }

      // Adicionar histórico do chat (últimas 10 mensagens para não exceder tokens)
      const recentHistory = chatHistory.slice(-10);
      for (const msg of recentHistory) {
        if (msg.role === 'user' || msg.role === 'assistant') {
          messages.push({
            role: msg.role,
            content: msg.content,
          });
        }
      }

      // Adicionar mensagem atual
      messages.push({ role: 'user', content: message });

      const response = await this.openai.chat.completions.create({
        model: 'gpt-4o-mini',
        messages: messages as any,
        temperature: 0.7,
      });

      const content = response.choices[0]?.message?.content;
      if (!content) {
        throw new Error('Resposta vazia da API OpenAI');
      }

      return content;
    } catch (error: any) {
      console.error('Erro no chat com IA (hub):', error);
      throw new Error(
        `Falha no chat: ${error.message || 'Erro desconhecido'}`
      );
    }
  }
}

