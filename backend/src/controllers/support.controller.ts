import { Request, Response } from 'express';
import { OpenAIService } from '../services/openai.service';

const openaiService = new OpenAIService();

/**
 * POST /api/support/chat
 * Chat com IA usando contexto do modo selecionado
 */
export const chatWithAI = async (req: Request, res: Response) => {
  try {
    const { mode, message, chatHistory, context } = req.body;

    console.log('[SupportController] Chat com IA:', {
      mode,
      messageLength: message?.length || 0,
      chatHistoryLength: chatHistory?.length || 0,
      hasContext: !!context,
    });

    // Validação de entrada
    if (!mode || typeof mode !== 'string') {
      return res.status(400).json({ error: 'mode é obrigatório e deve ser uma string' });
    }

    if (!message || typeof message !== 'string' || message.trim().length === 0) {
      return res.status(400).json({ error: 'message é obrigatório e não pode estar vazio' });
    }

    // Validar chatHistory
    const history = Array.isArray(chatHistory) ? chatHistory : [];

    // Chamar serviço de chat com contexto
    const response = await openaiService.chatWithHubContext(
      mode,
      message,
      history,
      context
    );

    res.json({ response });
  } catch (error: any) {
    console.error('[SupportController] Erro no chat com IA:', error);
    res.status(500).json({
      error: 'Erro ao processar chat',
      message: error.message,
    });
  }
};

