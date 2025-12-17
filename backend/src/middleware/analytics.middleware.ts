import { Request, Response, NextFunction } from 'express';
import { analyticsService } from '../services/analytics.service';
import { AuthRequest } from './auth.middleware';

export const analyticsMiddleware = (req: AuthRequest, res: Response, next: NextFunction) => {
  const userId = req.user?.id;

  // Track request
  analyticsService.trackEvent('api_request', 'api', userId, {
    method: req.method,
    path: req.path,
    statusCode: res.statusCode,
  });

  next();
};

