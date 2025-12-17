import { Request, Response, NextFunction } from 'express';
import { authMiddleware, AuthRequest } from './auth.middleware';
import { AppDataSource } from '../config/database';
import { User } from '../models/User';

interface RateLimitConfig {
  windowMs: number; // Janela de tempo em ms
  maxRequests: number; // Máximo de requisições
}

const userRateLimits = new Map<string, { count: number; resetTime: number }>();

export const rateLimitMiddleware = (config: RateLimitConfig) => {
  return async (req: AuthRequest, res: Response, next: NextFunction) => {
    const userId = req.user?.id || req.ip || 'anonymous';
    const now = Date.now();

    // Limpar entradas expiradas
    for (const [key, value] of userRateLimits.entries()) {
      if (value.resetTime < now) {
        userRateLimits.delete(key);
      }
    }

    const limit = userRateLimits.get(userId);

    if (!limit || limit.resetTime < now) {
      // Nova janela
      userRateLimits.set(userId, {
        count: 1,
        resetTime: now + config.windowMs,
      });
      return next();
    }

    if (limit.count >= config.maxRequests) {
      return res.status(429).json({
        error: {
          code: 'RATE_LIMIT_EXCEEDED',
          message: 'Muitas requisições. Tente novamente mais tarde.',
          retryAfter: Math.ceil((limit.resetTime - now) / 1000),
        },
      });
    }

    limit.count++;
    next();
  };
};

// Rate limit padrão: 100 requisições por 15 minutos
export const defaultRateLimit = rateLimitMiddleware({
  windowMs: 15 * 60 * 1000, // 15 minutos
  maxRequests: 100,
});

// Rate limit estrito: 10 requisições por minuto
export const strictRateLimit = rateLimitMiddleware({
  windowMs: 60 * 1000, // 1 minuto
  maxRequests: 10,
});

