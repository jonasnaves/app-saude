-- Migração: Criar tabela de sessions
-- Data: 2024-12-18

CREATE TABLE IF NOT EXISTS sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  session_token VARCHAR(255) NOT NULL UNIQUE,
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  
  -- Constraints
  CONSTRAINT sessions_token_unique UNIQUE (session_token)
);

-- Índices para melhor performance
CREATE INDEX IF NOT EXISTS idx_sessions_token ON sessions(session_token);
CREATE INDEX IF NOT EXISTS idx_sessions_user_id ON sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_expires_at ON sessions(expires_at);

-- Limpar sessions expiradas automaticamente (opcional - pode ser feito via job)
-- CREATE INDEX IF NOT EXISTS idx_sessions_expires_at ON sessions(expires_at) WHERE expires_at > CURRENT_TIMESTAMP;


