import { Router } from 'express';
import { authMiddleware } from '../middleware/auth.middleware';
import { getStats, getSchedule } from '../controllers/dashboard.controller';

const router = Router();

router.use(authMiddleware);

router.get('/stats', getStats);
router.get('/schedule', getSchedule);

export default router;

