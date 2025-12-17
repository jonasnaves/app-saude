import { Router } from 'express';
import { authMiddleware } from '../middleware/auth.middleware';
import { performanceService } from '../services/performance.service';

const router = Router();

router.use(authMiddleware);

router.get('/metrics', (req, res) => {
  const { name, startDate, endDate } = req.query;
  const metrics = performanceService.getMetrics(
    name as string,
    startDate ? new Date(startDate as string) : undefined,
    endDate ? new Date(endDate as string) : undefined
  );
  res.json(metrics);
});

router.get('/stats/:name', (req, res) => {
  const { name } = req.params;
  const stats = performanceService.getStats(name);
  res.json(stats);
});

export default router;

