import { Router } from 'express';
import { authMiddleware } from '../middleware/auth.middleware';
import { metricsService } from '../services/metrics.service';

const router = Router();

router.use(authMiddleware);

router.get('/stats/:name', (req, res) => {
  const { name } = req.params;
  const stats = metricsService.getStats(name);
  res.json(stats);
});

router.get('/metrics', (req, res) => {
  const { name, startDate, endDate } = req.query;
  const metrics = metricsService.getMetrics(
    name as string,
    startDate ? new Date(startDate as string) : undefined,
    endDate ? new Date(endDate as string) : undefined
  );
  res.json(metrics);
});

export default router;

