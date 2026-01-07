import { v4 as uuidv4 } from 'uuid';
import pool from '../config/database';
import { User } from '../models/User';

const SESSION_DURATION_HOURS = 24 * 7; // 7 dias

/**
 * Serviço de gerenciamento de sessions
 */
export class SessionService {
  /**
   * Cria uma nova session
   */
  async createSession(userId: string): Promise<string> {
    const sessionToken = uuidv4();
    const expiresAt = new Date();
    expiresAt.setHours(expiresAt.getHours() + SESSION_DURATION_HOURS);

    const query = `
      INSERT INTO sessions (user_id, session_token, expires_at)
      VALUES ($1, $2, $3)
      RETURNING session_token
    `;

    const result = await pool.query(query, [userId, sessionToken, expiresAt.toISOString()]);
    return result.rows[0].session_token;
  }

  /**
   * Busca session válida por token
   */
  async getSession(sessionToken: string): Promise<{ userId: string; user: User } | null> {
    // Limpar sessions expiradas primeiro
    await this.cleanExpiredSessions();

    const query = `
      SELECT s.user_id, u.id, u.email, u.name, u.role, u.created_at, u.updated_at
      FROM sessions s
      INNER JOIN users u ON s.user_id = u.id
      WHERE s.session_token = $1
        AND s.expires_at > CURRENT_TIMESTAMP
    `;

    const result = await pool.query(query, [sessionToken]);
    if (result.rows.length === 0) {
      return null;
    }

    const row = result.rows[0];
    return {
      userId: row.user_id,
      user: {
        id: row.id,
        email: row.email,
        name: row.name,
        role: row.role,
        createdAt: row.created_at,
        updatedAt: row.updated_at,
      },
    };
  }

  /**
   * Destrói uma session
   */
  async destroySession(sessionToken: string): Promise<boolean> {
    const query = `
      DELETE FROM sessions
      WHERE session_token = $1
    `;

    const result = await pool.query(query, [sessionToken]);
    return result.rowCount !== null && result.rowCount > 0;
  }

  /**
   * Destrói todas as sessions de um usuário
   */
  async destroyAllUserSessions(userId: string): Promise<void> {
    const query = `
      DELETE FROM sessions
      WHERE user_id = $1
    `;

    await pool.query(query, [userId]);
  }

  /**
   * Limpa sessions expiradas
   */
  private async cleanExpiredSessions(): Promise<void> {
    const query = `
      DELETE FROM sessions
      WHERE expires_at <= CURRENT_TIMESTAMP
    `;

    await pool.query(query);
  }
}


