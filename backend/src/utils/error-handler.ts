import { Response } from 'express';

export enum ErrorCode {
  VALIDATION_ERROR = 'VALIDATION_ERROR',
  AUTHENTICATION_ERROR = 'AUTHENTICATION_ERROR',
  AUTHORIZATION_ERROR = 'AUTHORIZATION_ERROR',
  NOT_FOUND = 'NOT_FOUND',
  CONFLICT = 'CONFLICT',
  INTERNAL_ERROR = 'INTERNAL_ERROR',
  EXTERNAL_SERVICE_ERROR = 'EXTERNAL_SERVICE_ERROR',
}

export class AppError extends Error {
  constructor(
    public code: ErrorCode,
    public message: string,
    public statusCode: number = 500,
    public details?: any
  ) {
    super(message);
    this.name = 'AppError';
  }
}

export const handleError = (error: unknown, res: Response) => {
  console.error('Error:', error);

  if (error instanceof AppError) {
    return res.status(error.statusCode).json({
      error: {
        code: error.code,
        message: error.message,
        details: error.details,
      },
    });
  }

  if (error instanceof Error) {
    return res.status(500).json({
      error: {
        code: ErrorCode.INTERNAL_ERROR,
        message: process.env.NODE_ENV === 'production' 
          ? 'Erro interno do servidor' 
          : error.message,
      },
    });
  }

  return res.status(500).json({
    error: {
      code: ErrorCode.INTERNAL_ERROR,
      message: 'Erro interno do servidor',
    },
  });
};

