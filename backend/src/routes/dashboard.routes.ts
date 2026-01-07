import { Router } from 'express';
import * as dashboardController from '../controllers/dashboard.controller';
import { authMiddleware } from '../middleware/auth.middleware';

const router = Router();

// Aplicar middleware de autenticação em todas as rotas
router.use(authMiddleware);

// Endpoint para estatísticas do dashboard
router.get('/stats', dashboardController.getDashboardStats);

export default router;

