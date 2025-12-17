
import { GoogleGenAI, Type } from "@google/genai";
import { TranscriptionSummary } from "../types";

const getAI = () => new GoogleGenAI({ apiKey: process.env.API_KEY });

export const getClinicalSummary = async (transcript: string): Promise<TranscriptionSummary> => {
  const ai = getAI();
  const response = await ai.models.generateContent({
    model: 'gemini-3-flash-preview',
    contents: `Analise a seguinte transcrição de consulta médica e forneça um resumo estruturado.
    
    Transcrição: ${transcript}
    
    Responda estritamente em formato JSON.`,
    config: {
      responseMimeType: "application/json",
      responseSchema: {
        type: Type.OBJECT,
        properties: {
          anamnesis: { type: Type.STRING, description: "Histórico da doença e queixas" },
          physicalExam: { type: Type.STRING, description: "Achados do exame físico mencionados" },
          diagnosisSuggestions: { 
            type: Type.ARRAY, 
            items: { type: Type.STRING },
            description: "Sugestões de diagnóstico baseadas em evidências" 
          },
          conduct: { type: Type.STRING, description: "Tratamentos recomendados ou próximos passos" }
        },
        required: ["anamnesis", "physicalExam", "diagnosisSuggestions", "conduct"]
      }
    }
  });

  try {
    return JSON.parse(response.text);
  } catch (e) {
    console.error("Error parsing clinical summary", e);
    throw e;
  }
};

export interface IncrementalAnalysis {
  insights: string;
  suggestedQuestions: string[];
}

export const getIncrementalAnalysis = async (transcript: string, previousInsights: string): Promise<IncrementalAnalysis> => {
  const ai = getAI();
  const response = await ai.models.generateContent({
    model: 'gemini-3-flash-preview',
    contents: `Você é um assistente de escriba médico de elite. 
    Analise a transcrição parcial e os insights anteriores para:
    1. Refinar e atualizar as observações clínicas (insights).
    2. Sugerir perguntas pertinentes que o médico deve fazer ao paciente para aprofundar o diagnóstico ou esclarecer pontos vagos.

    Transcrição atual: ${transcript}
    Insights anteriores: ${previousInsights}

    Responda apenas em formato JSON.`,
    config: {
      temperature: 0.1,
      responseMimeType: "application/json",
      responseSchema: {
        type: Type.OBJECT,
        properties: {
          insights: { type: Type.STRING, description: "Texto refinado com observações clínicas em tópicos." },
          suggestedQuestions: { 
            type: Type.ARRAY, 
            items: { type: Type.STRING },
            description: "Lista de 2 a 4 perguntas sugeridas para o médico fazer agora." 
          }
        },
        required: ["insights", "suggestedQuestions"]
      }
    }
  });

  try {
    return JSON.parse(response.text);
  } catch (e) {
    console.error("Error parsing incremental analysis", e);
    return { insights: previousInsights, suggestedQuestions: [] };
  }
};

export const getSupportResponse = async (query: string, mode: 'medical' | 'legal' | 'marketing') => {
  const ai = getAI();
  const instructions = {
    medical: "Você é um especialista médico altamente qualificado. Forneça respostas baseadas em evidências.",
    legal: "Você é um consultor jurídico especializado em saúde (LGPD, defesa médica, CFM).",
    marketing: "Você é um especialista em marketing médico. Sugira estratégias de branding pessoal."
  };

  const response = await ai.models.generateContent({
    model: 'gemini-3-flash-preview',
    contents: query,
    config: {
      systemInstruction: instructions[mode],
      temperature: 0.7
    }
  });

  return response.text;
};

export function encodeAudio(bytes: Uint8Array) {
  let binary = '';
  const len = bytes.byteLength;
  for (let i = 0; i < len; i++) {
    binary += String.fromCharCode(bytes[i]);
  }
  return btoa(binary);
}

export function createAudioBlob(data: Float32Array): { data: string; mimeType: string } {
  const l = data.length;
  const int16 = new Int16Array(l);
  for (let i = 0; i < l; i++) {
    int16[i] = Math.max(-1, Math.min(1, data[i])) * 32767;
  }
  return {
    data: encodeAudio(new Uint8Array(int16.buffer)),
    mimeType: 'audio/pcm;rate=16000',
  };
}
