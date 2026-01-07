import OpenAI from 'openai';
import { Readable } from 'stream';

export class WhisperService {
  private openai: OpenAI;

  constructor() {
    const apiKey = process.env.OPENAI_API_KEY;
    if (!apiKey || apiKey === 'your-openai-api-key-here') {
      console.warn('⚠️  OPENAI_API_KEY não configurada - funcionalidades de transcrição desabilitadas');
      // Não lançar erro, apenas avisar - permite que o backend inicie sem OpenAI
      this.openai = null as any;
      return;
    }
    this.openai = new OpenAI({ apiKey });
  }

  /**
   * Transcreve um chunk de áudio usando OpenAI Whisper API
   * @param audioBuffer Buffer do áudio a ser transcrito
   * @param format Formato do áudio (webm, wav, mp3, etc.)
   * @returns Texto transcrito
   */
  async transcribeAudio(
    audioBuffer: Buffer,
    format: string = 'webm'
  ): Promise<string> {
    try {
      // Mapear formatos para tipos MIME corretos
      const mimeTypes: Record<string, string> = {
        webm: 'audio/webm',
        wav: 'audio/wav',
        mp3: 'audio/mpeg',
        m4a: 'audio/mp4',
        flac: 'audio/flac',
        ogg: 'audio/ogg',
        oga: 'audio/ogg',
        mp4: 'audio/mp4',
        mpeg: 'audio/mpeg',
        mpga: 'audio/mpeg',
      };
      
      const mimeType = mimeTypes[format] || `audio/${format}`;
      const fileName = `audio.${format}`;
      
      // Converter Buffer para Uint8Array
      const uint8Array = new Uint8Array(audioBuffer);
      
      // Criar Blob e adicionar propriedades File-like
      // O SDK da OpenAI aceita Blob quando tem propriedades name e lastModified
      const blob = new globalThis.Blob([uint8Array], { type: mimeType });
      
      // Criar objeto File-like a partir do Blob
      // Adicionar propriedades necessárias para o SDK reconhecer como File
      const file = Object.assign(blob, {
        name: fileName,
        lastModified: Date.now(),
      }) as any;

      console.log(`[WhisperService] Enviando para OpenAI: nome=${fileName}, tipo=${mimeType}, tamanho=${audioBuffer.length} bytes`);

      const transcription = await this.openai.audio.transcriptions.create({
        file: file,
        model: 'whisper-1',
        response_format: 'text',
        language: 'pt', // Português
      });

      console.log(`[WhisperService] Transcrição recebida: ${(transcription as unknown as string).substring(0, 50)}...`);

      // A API retorna string quando response_format é 'text'
      return transcription as unknown as string;
    } catch (error: any) {
      console.error('Erro ao transcrever áudio com Whisper:', error);
      throw new Error(
        `Falha na transcrição: ${error.message || 'Erro desconhecido'}`
      );
    }
  }

  /**
   * Transcreve áudio a partir de base64
   * @param base64Audio String base64 do áudio
   * @param format Formato do áudio
   * @returns Texto transcrito
   */
  async transcribeFromBase64(
    base64Audio: string,
    format: string = 'webm'
  ): Promise<string> {
    // Remover data URL prefix se presente
    const base64Data = base64Audio.includes(',')
      ? base64Audio.split(',')[1]
      : base64Audio;

    const audioBuffer = Buffer.from(base64Data, 'base64');
    console.log(`[WhisperService] Transcrevendo áudio: ${audioBuffer.length} bytes, formato: ${format}`);
    return this.transcribeAudio(audioBuffer, format);
  }
}

