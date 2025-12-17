import { geminiAI } from '../config/gemini';
import { GoogleGenerativeAI } from '@google/generative-ai';

export interface TranscriptionSummary {
  anamnesis: string;
  physicalExam: string;
  diagnosisSuggestions: string[];
  conduct: string;
}

export interface IncrementalAnalysis {
  insights: string;
  suggestedQuestions: string[];
}

export class GeminiService {
  private model: any;

  constructor() {
    this.model = geminiAI.getGenerativeModel({ model: 'gemini-1.5-flash' });
  }

  async getClinicalSummary(transcript: string): Promise<TranscriptionSummary> {
    try {
      const prompt = `Analise a seguinte transcrição de consulta médica e forneça um resumo estruturado.
    
    Transcrição: ${transcript}
    
    Responda estritamente em formato JSON com as seguintes chaves:
    - anamnesis: Histórico da doença e queixas
    - physicalExam: Achados do exame físico mencionados
    - diagnosisSuggestions: Array de sugestões de diagnóstico baseadas em evidências
    - conduct: Tratamentos recomendados ou próximos passos`;

      const result = await this.model.generateContent(prompt);
      const response = await result.response;
      const text = response.text();

      // Extrair JSON da resposta
      const jsonMatch = text.match(/\{[\s\S]*\}/);
      if (!jsonMatch) {
        throw new Error('Resposta não contém JSON válido');
      }

      const parsed = JSON.parse(jsonMatch[0]);
      return {
        anamnesis: parsed.anamnesis || 'Não especificado',
        physicalExam: parsed.physicalExam || 'Não especificado',
        diagnosisSuggestions: Array.isArray(parsed.diagnosisSuggestions)
          ? parsed.diagnosisSuggestions
          : [],
        conduct: parsed.conduct || 'Não especificado',
      };
    } catch (error) {
      console.error('Error generating clinical summary:', error);
      throw error;
    }
  }

  async getIncrementalAnalysis(
    transcript: string,
    previousInsights: string
  ): Promise<IncrementalAnalysis> {
    try {
      const prompt = `Você é um assistente de escriba médico de elite. 
    Analise a transcrição parcial e os insights anteriores para:
    1. Refinar e atualizar as observações clínicas (insights).
    2. Sugerir perguntas pertinentes que o médico deve fazer ao paciente para aprofundar o diagnóstico ou esclarecer pontos vagos.

    Transcrição atual: ${transcript}
    Insights anteriores: ${previousInsights}

    Responda apenas em formato JSON com as seguintes chaves:
    - insights: Texto refinado com observações clínicas em tópicos
    - suggestedQuestions: Array de 2 a 4 perguntas sugeridas para o médico fazer agora`;

      const result = await this.model.generateContent(prompt);
      const response = await result.response;
      const text = response.text();

      const jsonMatch = text.match(/\{[\s\S]*\}/);
      if (!jsonMatch) {
        return {
          insights: previousInsights,
          suggestedQuestions: [],
        };
      }

      const parsed = JSON.parse(jsonMatch[0]);
      return {
        insights: parsed.insights || previousInsights,
        suggestedQuestions: Array.isArray(parsed.suggestedQuestions)
          ? parsed.suggestedQuestions
          : [],
      };
    } catch (error) {
      console.error('Error in incremental analysis:', error);
      return {
        insights: previousInsights,
        suggestedQuestions: [],
      };
    }
  }

  async getSupportResponse(
    query: string,
    mode: 'medical' | 'legal' | 'marketing'
  ): Promise<string> {
    try {
      const instructions = {
        medical:
          'Você é um especialista médico altamente qualificado. Forneça respostas baseadas em evidências científicas, guidelines atualizados e estudos recentes.',
        legal: 'Você é um consultor jurídico especializado em saúde (LGPD, termos de consentimento, defesa médica, CFM). Forneça orientações jurídicas precisas.',
        marketing:
          'Você é um especialista em marketing médico. Sugira estratégias de branding pessoal, posicionamento e crescimento profissional.',
      };

      const model = geminiAI.getGenerativeModel({
        model: 'gemini-1.5-flash',
        systemInstruction: instructions[mode],
      });

      const result = await model.generateContent(query);
      const response = await result.response;
      return response.text();
    } catch (error) {
      console.error('Error in support response:', error);
      throw error;
    }
  }

  async transcribeAudioChunk(audioBase64: string): Promise<string> {
    try {
      // Para transcrição em tempo real, usamos o modelo de áudio do Gemini
      const model = geminiAI.getGenerativeModel({ model: 'gemini-1.5-flash' });
      
      // Converter base64 para buffer
      const audioBuffer = Buffer.from(audioBase64, 'base64');
      
      // Usar a API de áudio do Gemini
      // Nota: A API atual do Gemini pode não suportar áudio diretamente
      // Esta é uma implementação simplificada que processa texto
      // Para produção, seria necessário usar a API Live do Gemini quando disponível
      
      // Por enquanto, retornamos uma transcrição simulada
      // Em produção, isso seria substituído pela integração real com Gemini Live API
      return '';
    } catch (error) {
      console.error('Error transcribing audio chunk:', error);
      throw error;
    }
  }

  async transcribeText(audioText: string): Promise<string> {
    try {
      // Método alternativo: processar texto de transcrição parcial
      // Isso pode ser usado quando o áudio já foi parcialmente transcrito no cliente
      const model = geminiAI.getGenerativeModel({ 
        model: 'gemini-1.5-flash',
        systemInstruction: 'Você é um escriba médico. Transcreva fielmente o que foi dito na consulta médica. Não adicione interpretações, apenas transcreva o texto exato.',
      });

      const result = await model.generateContent(
        `Transcreva e refine o seguinte texto de uma consulta médica, mantendo fidelidade ao que foi dito: ${audioText}`
      );
      
      return result.response.text();
    } catch (error) {
      console.error('Error transcribing text:', error);
      return audioText; // Retorna o texto original em caso de erro
    }
  }
}

export const geminiService = new GeminiService();

