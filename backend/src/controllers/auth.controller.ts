import { Request, Response } from 'express';
import { AuthService } from '../services/auth.service';
import { SessionService } from '../services/session.service';

const authService = new AuthService();
const sessionService = new SessionService();

/**
 * POST /api/auth/register
 * Registra um novo usuário
 */
export const register = async (req: Request, res: Response) => {
  try {
    const { email, password, name, role } = req.body;

    // Validação básica
    if (!email || !password || !name) {
      return res.status(400).json({
        error: 'Email, senha e nome são obrigatórios',
      });
    }

    // Verificar se email já existe
    const existingUser = await authService.getUserByEmail(email);
    if (existingUser) {
      return res.status(409).json({
        error: 'Email já cadastrado',
      });
    }

    // Criar usuário
    const user = await authService.createUser(email, password, name, role || 'user');

    // Criar session
    const sessionToken = await sessionService.createSession(user.id);

    // Definir cookie
    res.cookie('session_token', sessionToken, {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      sameSite: process.env.NODE_ENV === 'production' ? 'none' : 'lax', // 'none' para permitir cross-origin em dev
      maxAge: 7 * 24 * 60 * 60 * 1000, // 7 dias
      path: '/',
    });

    res.status(201).json({
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role,
      },
      message: 'Usuário criado com sucesso',
    });
  } catch (error: any) {
    console.error('Erro ao registrar usuário:', error);
    res.status(500).json({
      error: 'Erro ao registrar usuário',
      message: error.message,
    });
  }
};

/**
 * POST /api/auth/login
 * Autentica um usuário
 */
export const login = async (req: Request, res: Response) => {
  try {
    const { email, password } = req.body;

    console.log('[Auth] Tentativa de login:', { email, hasPassword: !!password });

    if (!email || !password) {
      return res.status(400).json({
        error: 'Email e senha são obrigatórios',
      });
    }

    // Validar credenciais
    const user = await authService.validateCredentials(email, password);
    if (!user) {
      console.log('[Auth] Credenciais inválidas para:', email);
      return res.status(401).json({
        error: 'Credenciais inválidas',
      });
    }

    console.log('[Auth] Login bem-sucedido para:', email);

    // Criar session
    const sessionToken = await sessionService.createSession(user.id);

    // Definir cookie
    // Para requisições cross-origin com withCredentials, precisamos usar sameSite: 'none' e secure: true
    // Mas em desenvolvimento local sem HTTPS, alguns navegadores podem não aceitar
    // Vamos tentar 'lax' primeiro, que funciona para navegação top-level
    const isDevelopment = process.env.NODE_ENV !== 'production';
    res.cookie('session_token', sessionToken, {
      httpOnly: true,
      secure: false, // false em desenvolvimento (localhost não usa HTTPS)
      sameSite: isDevelopment ? 'lax' : 'none', // 'lax' para dev, 'none' para produção
      maxAge: 7 * 24 * 60 * 60 * 1000, // 7 dias
      path: '/',
      // Não definir domain para permitir que funcione em qualquer porta do localhost
    });
    
    console.log('[Auth] Cookie definido:', { 
      sessionToken: sessionToken.substring(0, 10) + '...',
      sameSite: isDevelopment ? 'lax' : 'none',
      secure: false,
    });

    res.json({
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role,
      },
      message: 'Login realizado com sucesso',
    });
  } catch (error: any) {
    console.error('Erro ao fazer login:', error);
    res.status(500).json({
      error: 'Erro ao fazer login',
      message: error.message,
    });
  }
};

/**
 * POST /api/auth/logout
 * Encerra a session do usuário
 */
export const logout = async (req: Request, res: Response) => {
  try {
    const sessionToken = req.cookies?.session_token;

    if (sessionToken) {
      await sessionService.destroySession(sessionToken);
    }

    // Limpar cookie
    res.clearCookie('session_token');

    res.json({
      message: 'Logout realizado com sucesso',
    });
  } catch (error: any) {
    console.error('Erro ao fazer logout:', error);
    res.status(500).json({
      error: 'Erro ao fazer logout',
      message: error.message,
    });
  }
};

/**
 * GET /api/auth/me
 * Retorna informações do usuário atual
 */
export const getCurrentUser = async (req: Request, res: Response) => {
  try {
    // O middleware de autenticação já adicionou req.user
    if (!req.user) {
      return res.status(401).json({
        error: 'Não autenticado',
      });
    }

    res.json({
      user: {
        id: req.user.id,
        email: req.user.email,
        name: req.user.name,
        role: req.user.role,
      },
    });
  } catch (error: any) {
    console.error('Erro ao obter usuário atual:', error);
    res.status(500).json({
      error: 'Erro ao obter usuário atual',
      message: error.message,
    });
  }
};

