-- Migração: Criar tabela de pacientes
-- Data: 2024-12-18

-- Criar extensão para UUID se não existir (para PostgreSQL < 13)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS patients (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Dados pessoais
  name VARCHAR(255) NOT NULL,
  cpf VARCHAR(14) UNIQUE,
  rg VARCHAR(20),
  birth_date DATE,
  gender VARCHAR(20) CHECK (gender IN ('Masculino', 'Feminino', 'Outro', 'M', 'F', 'O', 'N') OR gender IS NULL),
  phone VARCHAR(20),
  email VARCHAR(255),
  
  -- Endereço (JSONB para flexibilidade)
  address JSONB,
  
  -- Informações de saúde (arrays como JSONB)
  allergies JSONB DEFAULT '[]'::jsonb,
  medical_history TEXT,
  current_medications JSONB DEFAULT '[]'::jsonb, -- Também conhecido como medications_in_use
  chronic_conditions JSONB DEFAULT '[]'::jsonb,
  
  -- Contatos de emergência (JSONB array)
  emergency_contacts JSONB DEFAULT '[]'::jsonb,
  
  -- Fotos (array de URLs)
  photos JSONB DEFAULT '[]'::jsonb,
  
  -- Metadados
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  created_by VARCHAR(255),
  
  -- Índices para busca
  CONSTRAINT patients_email_unique UNIQUE (email)
);

-- Índices para melhor performance
CREATE INDEX IF NOT EXISTS idx_patients_name ON patients(name);
CREATE INDEX IF NOT EXISTS idx_patients_cpf ON patients(cpf);
CREATE INDEX IF NOT EXISTS idx_patients_email ON patients(email);
CREATE INDEX IF NOT EXISTS idx_patients_created_at ON patients(created_at DESC);

-- Trigger para atualizar updated_at automaticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_patients_updated_at 
  BEFORE UPDATE ON patients 
  FOR EACH ROW 
  EXECUTE FUNCTION update_updated_at_column();

