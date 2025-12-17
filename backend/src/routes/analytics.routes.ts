import { Router } from 'express';
import { authMiddleware } from '../middleware/auth.middleware';
import { analyticsService } from '../services/analytics.service';

const router = Router();

router.use(authMiddleware);

router.post('/track', (req, res) => {
  const { event, category, properties } = req.body;
  const userId = (req as any).user?.id;

  if (!event || !category) {
    return res.status(400).json({ error: 'event e category são obrigatórios' });
  }

  analyticsService.trackEvent(event, category, userId, properties);
  res.json({ success: true });
});

router.get('/events', (req, res) => {
  const { userId, category, event, startDate, endDate } = req.query;
  const events = analyticsService.getEvents({
    userId: userId as string,
    category: category as string,
    event: event as string,
    startDate: startDate ? new Date(startDate as string) : undefined,
    endDate: endDate ? new Date(endDate as string) : undefined,
  });
  res.json(events);
});

router.get('/stats/:category', (req, res) => {
  const { category } = req.params;
  const userId = req.query.userId as string | undefined;
  const stats = analyticsService.getCategoryStats(category, userId);
  res.json(stats);
});

export default router;

