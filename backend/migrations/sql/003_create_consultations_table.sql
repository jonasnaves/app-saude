-- Migração: Criar tabela de consultas clínicas
-- Data: 2024-12-18

CREATE TABLE IF NOT EXISTS consultations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Relacionamento com paciente (opcional para consultas anônimas)
  patient_id UUID REFERENCES patients(id) ON DELETE SET NULL,
  patient_name VARCHAR(255), -- Nome para consultas anônimas
  
  -- Transcrição e análise
  transcript TEXT DEFAULT '',
  
  -- Análises da IA (cascata)
  summary TEXT, -- Resumo clínico
  anamnesis TEXT, -- Anamnese estruturada
  prescription TEXT, -- Prescrição (se houver)
  suggested_questions JSONB DEFAULT '[]'::jsonb, -- Perguntas sugeridas
  
  -- Notas do médico
  doctor_notes TEXT,
  
  -- Histórico de chat com IA
  chat_messages JSONB DEFAULT '[]'::jsonb,
  
  -- Timestamps
  started_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  ended_at TIMESTAMP WITH TIME ZONE,
  
  -- Metadados
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_consultations_patient_id ON consultations(patient_id);
CREATE INDEX IF NOT EXISTS idx_consultations_started_at ON consultations(started_at DESC);
CREATE INDEX IF NOT EXISTS idx_consultations_ended_at ON consultations(ended_at DESC);

-- Trigger para atualizar updated_at
CREATE TRIGGER update_consultations_updated_at 
  BEFORE UPDATE ON consultations 
  FOR EACH ROW 
  EXECUTE FUNCTION update_updated_at_column();


