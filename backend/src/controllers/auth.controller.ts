import { Request, Response } from 'express';
import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import { AppDataSource } from '../config/database';
import { User } from '../models/User';
import { z } from 'zod';

const registerSchema = z.object({
  name: z.string().min(3),
  email: z.string().email(),
  password: z.string().min(6),
});

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1),
});

export const register = async (req: Request, res: Response) => {
  try {
    const data = registerSchema.parse(req.body);
    const userRepository = AppDataSource.getRepository(User);

    const existingUser = await userRepository.findOne({
      where: { email: data.email },
    });

    if (existingUser) {
      return res.status(400).json({ error: 'Email já cadastrado' });
    }

    const passwordHash = await bcrypt.hash(data.password, 10);
    const user = userRepository.create({
      name: data.name,
      email: data.email,
      passwordHash,
      credits: 0,
    });

    await userRepository.save(user);

    const token = jwt.sign(
      { userId: user.id },
      process.env.JWT_SECRET!,
      { expiresIn: process.env.JWT_EXPIRES_IN || '7d' } as jwt.SignOptions
    );

    const refreshToken = jwt.sign(
      { userId: user.id },
      process.env.JWT_REFRESH_SECRET || process.env.JWT_SECRET!,
      { expiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '30d' } as jwt.SignOptions
    );

    res.status(201).json({
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        credits: user.credits,
      },
      token,
      refreshToken,
    });
  } catch (error) {
    if (error instanceof z.ZodError) {
      return res.status(400).json({ error: 'Dados inválidos', details: error.issues });
    }
    res.status(500).json({ error: 'Erro ao registrar usuário' });
  }
};

export const login = async (req: Request, res: Response) => {
  try {
    const data = loginSchema.parse(req.body);
    const userRepository = AppDataSource.getRepository(User);

    const user = await userRepository.findOne({
      where: { email: data.email },
    });

    if (!user) {
      return res.status(401).json({ error: 'Email ou senha inválidos' });
    }

    const isValidPassword = await bcrypt.compare(data.password, user.passwordHash);

    if (!isValidPassword) {
      return res.status(401).json({ error: 'Email ou senha inválidos' });
    }

    const token = jwt.sign(
      { userId: user.id },
      process.env.JWT_SECRET!,
      { expiresIn: process.env.JWT_EXPIRES_IN || '7d' } as jwt.SignOptions
    );

    const refreshToken = jwt.sign(
      { userId: user.id },
      process.env.JWT_REFRESH_SECRET || process.env.JWT_SECRET!,
      { expiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '30d' } as jwt.SignOptions
    );

    res.json({
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        credits: user.credits,
      },
      token,
      refreshToken,
    });
  } catch (error) {
    if (error instanceof z.ZodError) {
      return res.status(400).json({ error: 'Dados inválidos', details: error.issues });
    }
    res.status(500).json({ error: 'Erro ao fazer login' });
  }
};

const refreshTokenSchema = z.object({
  refreshToken: z.string().min(1),
});

export const refreshToken = async (req: Request, res: Response) => {
  try {
    const data = refreshTokenSchema.parse(req.body);
    const refreshSecret = process.env.JWT_REFRESH_SECRET || process.env.JWT_SECRET!;

    let decoded: { userId: string };
    try {
      decoded = jwt.verify(data.refreshToken, refreshSecret) as { userId: string };
    } catch (error) {
      return res.status(401).json({ error: 'Refresh token inválido ou expirado' });
    }

    const userRepository = AppDataSource.getRepository(User);
    const user = await userRepository.findOne({
      where: { id: decoded.userId },
    });

    if (!user) {
      return res.status(401).json({ error: 'Usuário não encontrado' });
    }

    const newToken = jwt.sign(
      { userId: user.id },
      process.env.JWT_SECRET!,
      { expiresIn: process.env.JWT_EXPIRES_IN || '7d' } as jwt.SignOptions
    );

    const newRefreshToken = jwt.sign(
      { userId: user.id },
      refreshSecret,
      { expiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '30d' } as jwt.SignOptions
    );

    res.json({
      token: newToken,
      refreshToken: newRefreshToken,
    });
  } catch (error) {
    if (error instanceof z.ZodError) {
      return res.status(400).json({ error: 'Dados inválidos', details: error.issues });
    }
    res.status(500).json({ error: 'Erro ao renovar token' });
  }
};

