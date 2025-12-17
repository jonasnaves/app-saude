import { geminiService } from './gemini.service';

export interface AudioChunk {
  data: string; // base64 encoded audio
  mimeType: string;
  timestamp: number;
}

export class AudioService {
  private transcriptBuffer: string = '';
  private lastAnalysisLength: number = 0;

  async processAudioChunk(chunk: AudioChunk, consultationId: string): Promise<string> {
    try {
      // Processar chunk de áudio
      // Por enquanto, assumimos que o cliente já fez a transcrição básica
      // e estamos apenas refinando com o Gemini
      
      // Em produção, aqui seria feita a transcrição real do áudio
      const transcribed = await geminiService.transcribeAudioChunk(chunk.data);
      
      if (transcribed) {
        this.transcriptBuffer += ' ' + transcribed;
      }

      return this.transcriptBuffer.trim();
    } catch (error) {
      console.error('Error processing audio chunk:', error);
      throw error;
    }
  }

  async processTextChunk(text: string): Promise<string> {
    try {
      // Processar chunk de texto (transcrição já feita no cliente)
      const refined = await geminiService.transcribeText(text);
      
      if (refined && refined !== text) {
        this.transcriptBuffer += ' ' + refined;
      } else {
        this.transcriptBuffer += ' ' + text;
      }

      return this.transcriptBuffer.trim();
    } catch (error) {
      console.error('Error processing text chunk:', error);
      this.transcriptBuffer += ' ' + text;
      return this.transcriptBuffer.trim();
    }
  }

  shouldTriggerAnalysis(currentLength: number): boolean {
    const threshold = 200;
    if (currentLength - this.lastAnalysisLength >= threshold) {
      this.lastAnalysisLength = currentLength;
      return true;
    }
    return false;
  }

  reset(consultationId?: string) {
    this.transcriptBuffer = '';
    this.lastAnalysisLength = 0;
  }

  getTranscript(): string {
    return this.transcriptBuffer;
  }
}

export const audioService = new AudioService();

