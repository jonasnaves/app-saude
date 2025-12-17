import { Request, Response, NextFunction } from 'express';
import { cacheService, CacheService } from '../services/cache.service';

export const cacheMiddleware = (duration: number = 300) => {
  return (req: Request, res: Response, next: NextFunction) => {
    if (req.method !== 'GET') {
      return next();
    }

    const key = req.originalUrl || req.url;
    const cached = cacheService.get(key);

    if (cached) {
      return res.json(cached);
    }

    const originalJson = res.json.bind(res);
    res.json = function (body: any) {
      cacheService.set(key, body, duration);
      return originalJson(body);
    } as any;

    next();
  };
};

