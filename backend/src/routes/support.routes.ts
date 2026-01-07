import express from 'express';
import { chatWithAI } from '../controllers/support.controller';
import { authMiddleware } from '../middleware/auth.middleware';

const router = express.Router();

/**
 * POST /api/support/chat
 * Chat com IA usando contexto do modo selecionado
 */
router.post('/chat', authMiddleware, chatWithAI);

export default router;


