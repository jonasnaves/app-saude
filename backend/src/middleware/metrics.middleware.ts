import { Request, Response, NextFunction } from 'express';
import { metricsService } from '../services/metrics.service';

export const metricsMiddleware = (req: Request, res: Response, next: NextFunction) => {
  const startTime = Date.now();

  res.on('finish', () => {
    const duration = Date.now() - startTime;
    metricsService.recordMetric('http_request_duration', duration, {
      method: req.method,
      path: req.path,
      status: res.statusCode.toString(),
    });

    metricsService.recordMetric('http_request_count', 1, {
      method: req.method,
      path: req.path,
      status: res.statusCode.toString(),
    });
  });

  next();
};

