import { Request, Response, NextFunction } from 'express';
import { performanceService } from '../services/performance.service';

export const performanceMiddleware = (req: Request, res: Response, next: NextFunction) => {
  const startTime = Date.now();
  const metricName = `${req.method}_${req.path}`;

  res.on('finish', () => {
    const duration = Date.now() - startTime;
    performanceService.recordMetric(metricName, duration, {
      statusCode: res.statusCode,
      method: req.method,
      path: req.path,
    });
  });

  next();
};

