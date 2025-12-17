import { GoogleGenerativeAI } from '@google/generative-ai';

// Para desenvolvimento, permitir valor dummy
const geminiApiKey = process.env.GEMINI_API_KEY || 'AIzaSyDummyKeyForDevelopmentOnly123456789';

if (!geminiApiKey || geminiApiKey === 'your-gemini-api-key-here') {
  console.warn('⚠️  GEMINI_API_KEY não configurada. Usando valor dummy para desenvolvimento.');
}

export const geminiAI = new GoogleGenerativeAI(geminiApiKey);

