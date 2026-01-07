-- Script de inicialização do banco de dados
-- Este arquivo será executado automaticamente quando o container PostgreSQL for criado pela primeira vez
-- Os arquivos SQL são executados em ordem alfabética pelo PostgreSQL

-- Criar extensão para UUID (PostgreSQL 13+ usa gen_random_uuid() nativo, mas mantemos para compatibilidade)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
