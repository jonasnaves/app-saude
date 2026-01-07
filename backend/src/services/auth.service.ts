import bcrypt from 'bcrypt';
import pool from '../config/database';
import { User, UserWithPassword } from '../models/User';

const SALT_ROUNDS = 10;

/**
 * Serviço de autenticação
 */
export class AuthService {
  /**
   * Gera hash da senha usando bcrypt
   */
  async hashPassword(password: string): Promise<string> {
    return await bcrypt.hash(password, SALT_ROUNDS);
  }

  /**
   * Compara senha com hash
   */
  async comparePassword(password: string, hash: string): Promise<boolean> {
    return await bcrypt.compare(password, hash);
  }

  /**
   * Cria um novo usuário
   */
  async createUser(email: string, password: string, name: string, role: string = 'user'): Promise<User> {
    const passwordHash = await this.hashPassword(password);

    const query = `
      INSERT INTO users (email, password_hash, name, role)
      VALUES ($1, $2, $3, $4)
      RETURNING id, email, name, role, created_at, updated_at
    `;

    const result = await pool.query(query, [email, passwordHash, name, role]);
    return this.mapRowToUser(result.rows[0]);
  }

  /**
   * Busca usuário por email
   */
  async getUserByEmail(email: string): Promise<UserWithPassword | null> {
    const query = `
      SELECT id, email, password_hash, name, role, created_at, updated_at
      FROM users
      WHERE email = $1
    `;

    const result = await pool.query(query, [email]);
    if (result.rows.length === 0) {
      return null;
    }

    return this.mapRowToUserWithPassword(result.rows[0]);
  }

  /**
   * Busca usuário por ID
   */
  async getUserById(id: string): Promise<User | null> {
    const query = `
      SELECT id, email, name, role, created_at, updated_at
      FROM users
      WHERE id = $1
    `;

    const result = await pool.query(query, [id]);
    if (result.rows.length === 0) {
      return null;
    }

    return this.mapRowToUser(result.rows[0]);
  }

  /**
   * Valida credenciais de login
   */
  async validateCredentials(email: string, password: string): Promise<User | null> {
    const user = await this.getUserByEmail(email);
    if (!user) {
      console.log('[AuthService] Usuário não encontrado:', email);
      return null;
    }

    const isValid = await this.comparePassword(password, user.passwordHash);
    if (!isValid) {
      console.log('[AuthService] Senha inválida para:', email);
      return null;
    }

    console.log('[AuthService] Credenciais válidas para:', email);

    // Retornar sem password_hash
    return {
      id: user.id,
      email: user.email,
      name: user.name,
      role: user.role,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
    };
  }

  /**
   * Mapeia linha do banco para User (sem password)
   */
  private mapRowToUser(row: any): User {
    return {
      id: row.id,
      email: row.email,
      name: row.name,
      role: row.role,
      createdAt: row.created_at,
      updatedAt: row.updated_at,
    };
  }

  /**
   * Mapeia linha do banco para UserWithPassword
   */
  private mapRowToUserWithPassword(row: any): UserWithPassword {
    return {
      id: row.id,
      email: row.email,
      name: row.name,
      role: row.role,
      passwordHash: row.password_hash,
      createdAt: row.created_at,
      updatedAt: row.updated_at,
    };
  }
}

