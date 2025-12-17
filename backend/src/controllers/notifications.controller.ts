import { Request, Response } from 'express';
import { AppDataSource } from '../config/database';
import { User } from '../models/User';
import { authMiddleware, AuthRequest } from '../middleware/auth.middleware';
import { z } from 'zod';

const registerTokenSchema = z.object({
  fcmToken: z.string().min(1),
});

export const registerFCMToken = async (req: AuthRequest, res: Response) => {
  try {
    const data = registerTokenSchema.parse(req.body);
    const userRepository = AppDataSource.getRepository(User);
    
    const user = await userRepository.findOne({
      where: { id: req.user!.id },
    });

    if (!user) {
      return res.status(404).json({ error: 'Usuário não encontrado' });
    }

    // Armazenar token FCM (pode adicionar campo no modelo User ou criar tabela separada)
    // Por enquanto, apenas retornar sucesso
    // Em produção: await userRepository.update(user.id, { fcmToken: data.fcmToken });

    res.json({ success: true });
  } catch (error) {
    if (error instanceof z.ZodError) {
      return res.status(400).json({ error: 'Dados inválidos' });
    }
    res.status(500).json({ error: 'Erro ao registrar token' });
  }
};

