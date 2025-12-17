import { Request, Response } from 'express';
import { AppDataSource } from '../config/database';
import { SupportChat, SupportMode } from '../models/SupportChat';
import { geminiService } from '../services/gemini.service';
import { authMiddleware, AuthRequest } from '../middleware/auth.middleware';
import { z } from 'zod';

const chatSchema = z.object({
  message: z.string().min(1),
  mode: z.enum(['medical', 'legal', 'marketing']),
});

export const sendMessage = async (req: AuthRequest, res: Response) => {
  try {
    const data = chatSchema.parse(req.body);
    const supportChatRepository = AppDataSource.getRepository(SupportChat);

    // Buscar ou criar chat
    let chat = await supportChatRepository.findOne({
      where: {
        userId: req.user!.id,
        mode: data.mode as SupportMode,
      },
      order: { createdAt: 'DESC' },
    });

    if (!chat) {
      chat = supportChatRepository.create({
        userId: req.user!.id,
        mode: data.mode as SupportMode,
        messages: [],
      });
    }

    // Adicionar mensagem do usuário
    chat.messages.push({
      role: 'user',
      text: data.message,
      timestamp: new Date(),
    });

    // Obter resposta da IA
    const aiResponse = await geminiService.getSupportResponse(data.message, data.mode);

    // Adicionar resposta da IA
    chat.messages.push({
      role: 'bot',
      text: aiResponse,
      timestamp: new Date(),
    });

    await supportChatRepository.save(chat);

    res.json({
      response: aiResponse,
      chatId: chat.id,
    });
  } catch (error) {
    if (error instanceof z.ZodError) {
      return res.status(400).json({ error: 'Dados inválidos' });
    }
    res.status(500).json({ error: 'Erro ao processar mensagem' });
  }
};

export const getChatHistory = async (req: AuthRequest, res: Response) => {
  try {
    const { mode } = req.query;
    const supportChatRepository = AppDataSource.getRepository(SupportChat);

    const where: any = { userId: req.user!.id };
    if (mode) {
      where.mode = mode;
    }

    const chats = await supportChatRepository.find({
      where,
      order: { createdAt: 'DESC' },
    });

    res.json(chats);
  } catch (error) {
    res.status(500).json({ error: 'Erro ao buscar histórico' });
  }
};

