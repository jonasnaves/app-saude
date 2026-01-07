# Backend - Assistente Médico

## Instalação

1. Instalar dependências:
```bash
npm install
```

2. Configurar variáveis de ambiente:
Crie um arquivo `.env` na raiz do backend com:
```
OPENAI_API_KEY=sua_chave_openai_aqui
PORT=3000
```

3. Executar em desenvolvimento:
```bash
npm run dev
```

4. Executar em produção:
```bash
npm run build
npm start
```

## Endpoints

### POST /api/clinical/start-recording
Inicia uma nova gravação/consulta.
Retorna: `{ consultationId: string }`

### POST /api/clinical/transcribe-chunk
Recebe um chunk de áudio e retorna transcrição.
Body:
```json
{
  "audioData": "base64_audio_data",
  "format": "webm",
  "consultationId": "string"
}
```
Retorna: `{ transcript: string, fullTranscript: string }`

### POST /api/clinical/analyze-incremental
Analisa transcrição e retorna anamnese, prescrição e perguntas.
Body:
```json
{
  "transcript": "string",
  "previousInsights": "string?",
  "consultationId": "string?"
}
```
Retorna: `{ anamnesis: string, prescription: string | null, suggestedQuestions: string[] }`

### POST /api/clinical/generate-summary
Gera resumo clínico completo.
Body:
```json
{
  "consultationId": "string",
  "transcript": "string?"
}
```

### GET /api/clinical/transcript/:consultationId
Retorna transcrição completa de uma consulta.


