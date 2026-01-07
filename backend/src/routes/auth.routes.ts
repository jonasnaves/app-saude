import { Router } from 'express';
import * as authController from '../controllers/auth.controller';
import { authMiddleware } from '../middleware/auth.middleware';

const router = Router();

// Rotas públicas
router.post('/register', authController.register);
router.post('/login', authController.login);
router.post('/logout', authController.logout);

// Rota protegida
router.get('/me', authMiddleware, authController.getCurrentUser);

export default router;


