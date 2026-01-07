# Migrações de Banco de Dados

Este diretório contém as migrações SQL para criar e atualizar o esquema do banco de dados PostgreSQL.

## Estrutura

- `sql/000_init.sql` - Script de inicialização (executado primeiro)
- `sql/001_create_patients_table.sql` - Cria tabela de pacientes
- `sql/002_create_patient_documents_table.sql` - Cria tabela de documentos de pacientes
- `sql/003_create_consultations_table.sql` - Cria tabela de consultas clínicas

## Execução Automática

As migrações são executadas automaticamente quando o container PostgreSQL é criado pela primeira vez através do Docker Compose. Os arquivos SQL no diretório `/docker-entrypoint-initdb.d` são executados em ordem alfabética.

## Execução Manual

Se precisar executar as migrações manualmente:

```bash
# Conectar ao banco de dados
docker exec -it medos-postgres psql -U medos_user -d medos_db

# Executar migrações
\i /docker-entrypoint-initdb.d/001_create_patients_table.sql
\i /docker-entrypoint-initdb.d/002_create_patient_documents_table.sql
\i /docker-entrypoint-initdb.d/003_create_consultations_table.sql
```

## Tabelas Criadas

### patients
Armazena informações dos pacientes, incluindo:
- Dados pessoais (nome, CPF, RG, data de nascimento, gênero, telefone, email)
- Endereço (JSONB)
- Informações de saúde (alergias, histórico médico, medicamentos, condições crônicas)
- Contatos de emergência (JSONB array)
- Fotos (array de URLs)
- Metadados (created_at, updated_at, created_by)

### patient_documents
Armazena documentos anexados aos pacientes:
- Relacionamento com paciente (foreign key)
- Nome, tipo, URL, tamanho
- Data de upload

### consultations
Armazena consultas clínicas:
- Relacionamento com paciente (opcional para consultas anônimas)
- Transcrição completa
- Análises da IA (resumo, anamnese, prescrição, perguntas sugeridas)
- Notas do médico
- Histórico de chat com IA
- Timestamps (início e fim da consulta)


