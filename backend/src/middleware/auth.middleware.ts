import { Request, Response, NextFunction } from 'express';
import { SessionService } from '../services/session.service';
import { User } from '../models/User';

// Estender interface Request para incluir user
declare global {
  namespace Express {
    interface Request {
      user?: User;
      userId?: string;
    }
  }
}

const sessionService = new SessionService();

/**
 * Middleware de autenticação
 * Verifica se o usuário está autenticado via session cookie
 */
export const authMiddleware = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    // Buscar session token do cookie ou do header Authorization
    let sessionToken = req.cookies?.session_token;
    
    // Se não tiver cookie, tentar pegar do header Authorization
    if (!sessionToken) {
      const authHeader = req.headers.authorization;
      if (authHeader && authHeader.startsWith('Bearer ')) {
        sessionToken = authHeader.substring(7);
      }
    }

    console.log('[AuthMiddleware] Verificando autenticação:', {
      hasCookie: !!req.cookies?.session_token,
      hasAuthHeader: !!req.headers.authorization,
      authHeaderValue: req.headers.authorization ? req.headers.authorization.substring(0, 20) + '...' : null,
      hasSessionToken: !!sessionToken,
      origin: req.headers.origin,
      allHeaders: Object.keys(req.headers),
    });

    if (!sessionToken) {
      console.log('[AuthMiddleware] Token não encontrado (cookie ou header)');
      res.status(401).json({ error: 'Não autenticado' });
      return;
    }

    // Validar session
    const session = await sessionService.getSession(sessionToken);
    if (!session) {
      res.status(401).json({ error: 'Session inválida ou expirada' });
      return;
    }

    // Adicionar usuário à requisição
    req.user = session.user;
    req.userId = session.userId;

    next();
  } catch (error: any) {
    console.error('Erro no middleware de autenticação:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
};

/**
 * Middleware opcional - não bloqueia se não autenticado
 * Útil para rotas que funcionam com ou sem autenticação
 */
export const optionalAuthMiddleware = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    // Buscar session token do cookie ou do header Authorization
    let sessionToken = req.cookies?.session_token;
    
    // Se não tiver cookie, tentar pegar do header Authorization
    if (!sessionToken) {
      const authHeader = req.headers.authorization;
      if (authHeader && authHeader.startsWith('Bearer ')) {
        sessionToken = authHeader.substring(7);
      }
    }
    
    if (sessionToken) {
      const session = await sessionService.getSession(sessionToken);
      if (session) {
        req.user = session.user;
        req.userId = session.userId;
      }
    }
    next();
  } catch (error: any) {
    // Em caso de erro, continuar sem autenticação
    next();
  }
};

