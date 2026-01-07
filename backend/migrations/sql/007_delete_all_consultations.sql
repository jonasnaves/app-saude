-- Script para excluir todas as consultas do banco de dados
-- ATENÇÃO: Esta operação é IRREVERSÍVEL!

-- Excluir todas as consultas
DELETE FROM consultations;

-- Opcional: Resetar a sequência (se houver alguma)
-- ALTER SEQUENCE consultations_id_seq RESTART WITH 1;

-- Verificar quantas consultas restam (deve retornar 0)
SELECT COUNT(*) as total_consultations FROM consultations;
