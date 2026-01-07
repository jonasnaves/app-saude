-- Migração: Adicionar campo suggested_medications na tabela consultations
-- Data: 2024-12-18

ALTER TABLE consultations 
ADD COLUMN IF NOT EXISTS suggested_medications TEXT;

COMMENT ON COLUMN consultations.suggested_medications IS 'Medicamentos sugeridos pela IA baseado no contexto clínico (diferente da prescrição mencionada na transcrição)';


