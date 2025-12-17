-- Migração Inicial - Schema do MedOS
-- Data: 2024-01-01 12:00:00
-- Descrição: Cria todas as tabelas iniciais do sistema

-- Habilitar extensão UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Criar tabela schema_migrations para rastreamento
CREATE TABLE IF NOT EXISTS schema_migrations (
    version VARCHAR(255) PRIMARY KEY,
    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- TABELA: users
-- ============================================
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    "passwordHash" VARCHAR(255) NOT NULL,
    credits DECIMAL(10, 2) DEFAULT 0,
    "createdAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índice único para email
CREATE UNIQUE INDEX IF NOT EXISTS "IDX_users_email" ON users(email);

-- ============================================
-- TABELA: consultations
-- ============================================
CREATE TABLE IF NOT EXISTS consultations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "userId" UUID NOT NULL,
    "patientName" VARCHAR(255),
    transcript TEXT,
    "startedAt" TIMESTAMP NOT NULL,
    "endedAt" TIMESTAMP,
    "createdAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "FK_consultations_userId" 
        FOREIGN KEY ("userId") 
        REFERENCES users(id) 
        ON DELETE CASCADE
);

-- Índice para userId
CREATE INDEX IF NOT EXISTS "IDX_consultations_userId" ON consultations("userId");

-- ============================================
-- TABELA: medical_records
-- ============================================
CREATE TABLE IF NOT EXISTS medical_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "consultationId" UUID NOT NULL UNIQUE,
    anamnesis TEXT NOT NULL,
    "physicalExam" TEXT NOT NULL,
    "diagnosisSuggestions" TEXT[] NOT NULL,
    conduct TEXT NOT NULL,
    "createdAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "FK_medical_records_consultationId" 
        FOREIGN KEY ("consultationId") 
        REFERENCES consultations(id) 
        ON DELETE CASCADE
);

-- ============================================
-- TABELA: support_chats
-- ============================================
-- Criar tipo ENUM para mode
DO $$ BEGIN
    CREATE TYPE support_mode_enum AS ENUM ('medical', 'legal', 'marketing');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

CREATE TABLE IF NOT EXISTS support_chats (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "userId" UUID NOT NULL,
    mode support_mode_enum NOT NULL,
    messages JSONB NOT NULL,
    "createdAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "FK_support_chats_userId" 
        FOREIGN KEY ("userId") 
        REFERENCES users(id) 
        ON DELETE CASCADE
);

-- Índice para userId
CREATE INDEX IF NOT EXISTS "IDX_support_chats_userId" ON support_chats("userId");

-- ============================================
-- TABELA: transactions
-- ============================================
-- Criar tipo ENUM para type
DO $$ BEGIN
    CREATE TYPE transaction_type_enum AS ENUM ('credit', 'debit');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

CREATE TABLE IF NOT EXISTS transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "userId" UUID NOT NULL,
    type transaction_type_enum NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    description TEXT,
    "createdAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "FK_transactions_userId" 
        FOREIGN KEY ("userId") 
        REFERENCES users(id) 
        ON DELETE CASCADE
);

-- Índice para userId
CREATE INDEX IF NOT EXISTS "IDX_transactions_userId" ON transactions("userId");

-- ============================================
-- TABELA: drugs
-- ============================================
CREATE TABLE IF NOT EXISTS drugs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    dosage VARCHAR(255) NOT NULL,
    category VARCHAR(255) NOT NULL,
    price DECIMAL(10, 2),
    "createdAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índices para busca
CREATE INDEX IF NOT EXISTS "IDX_drugs_name" ON drugs(name);
CREATE INDEX IF NOT EXISTS "IDX_drugs_category" ON drugs(category);

-- Registrar migração
INSERT INTO schema_migrations (version) 
VALUES ('20240101120000-initial-schema')
ON CONFLICT (version) DO NOTHING;

