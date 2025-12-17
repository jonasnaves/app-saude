import { Router } from 'express';
import { authMiddleware } from '../middleware/auth.middleware';
import { sendMessage, getChatHistory } from '../controllers/support.controller';

const router = Router();

router.use(authMiddleware);

router.post('/chat', sendMessage);
router.get('/history', getChatHistory);

export default router;

