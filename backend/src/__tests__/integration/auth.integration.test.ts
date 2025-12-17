import { describe, it, expect, beforeAll, afterAll } from '@jest/globals';
import request from 'supertest';
import app from '../../app';
import { AppDataSource } from '../../config/database';

describe('Auth Integration Tests', () => {
  beforeAll(async () => {
    await AppDataSource.initialize();
  });

  afterAll(async () => {
    await AppDataSource.destroy();
  });

  it('should register a new user and return tokens', async () => {
    const response = await request(app)
      .post('/api/auth/register')
      .send({
        name: 'Test User',
        email: 'test@example.com',
        password: 'password123',
      });

    expect(response.status).toBe(201);
    expect(response.body).toHaveProperty('user');
    expect(response.body).toHaveProperty('token');
    expect(response.body).toHaveProperty('refreshToken');
    expect(response.body.user.email).toBe('test@example.com');
  });

  it('should login with valid credentials', async () => {
    // Primeiro registrar
    await request(app)
      .post('/api/auth/register')
      .send({
        name: 'Login Test',
        email: 'login@example.com',
        password: 'password123',
      });

    // Depois fazer login
    const response = await request(app)
      .post('/api/auth/login')
      .send({
        email: 'login@example.com',
        password: 'password123',
      });

    expect(response.status).toBe(200);
    expect(response.body).toHaveProperty('token');
    expect(response.body).toHaveProperty('refreshToken');
  });

  it('should refresh token successfully', async () => {
    // Registrar e fazer login
    const loginResponse = await request(app)
      .post('/api/auth/register')
      .send({
        name: 'Refresh Test',
        email: 'refresh@example.com',
        password: 'password123',
      });

    const refreshToken = loginResponse.body.refreshToken;

    // Refresh
    const response = await request(app)
      .post('/api/auth/refresh')
      .send({
        refreshToken,
      });

    expect(response.status).toBe(200);
    expect(response.body).toHaveProperty('token');
    expect(response.body).toHaveProperty('refreshToken');
  });
});

