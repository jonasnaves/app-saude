-- Migração: Criar tabela de usuários
-- Data: 2024-12-18

CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Dados de autenticação
  email VARCHAR(255) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL, -- Hash bcrypt da senha
  
  -- Dados pessoais
  name VARCHAR(255) NOT NULL,
  role VARCHAR(50) DEFAULT 'user', -- 'user', 'admin', etc.
  
  -- Metadados
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  
  -- Constraints
  CONSTRAINT users_email_unique UNIQUE (email)
);

-- Índices para melhor performance
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);

-- Trigger para atualizar updated_at automaticamente
CREATE TRIGGER update_users_updated_at 
  BEFORE UPDATE ON users 
  FOR EACH ROW 
  EXECUTE FUNCTION update_updated_at_column();


