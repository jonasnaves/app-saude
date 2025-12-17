import { Router } from 'express';
import { authMiddleware } from '../middleware/auth.middleware';
import { registerFCMToken } from '../controllers/notifications.controller';

const router = Router();

router.use(authMiddleware);

router.post('/register', registerFCMToken);

export default router;

