# Resumo das Migrações de Banco de Dados

## ✅ Migrações Criadas

### 1. `001_create_patients_table.sql`
**Tabela: `patients`**

Campos criados:
- **Dados pessoais:**
  - `id` (UUID, PK)
  - `name` (VARCHAR(255), NOT NULL)
  - `cpf` (VARCHAR(14), UNIQUE)
  - `rg` (VARCHAR(20))
  - `birth_date` (DATE)
  - `gender` (VARCHAR(1), CHECK: 'M', 'F', 'O', 'N')
  - `phone` (VARCHAR(20))
  - `email` (VARCHAR(255), UNIQUE)

- **Endereço:**
  - `address` (JSONB) - Objeto com: street, number, complement, neighborhood, city, state, zipCode

- **Informações de saúde:**
  - `allergies` (JSONB, array de strings)
  - `medical_history` (TEXT)
  - `current_medications` (JSONB, array de strings)
  - `chronic_conditions` (JSONB, array de strings)

- **Contatos de emergência:**
  - `emergency_contacts` (JSONB, array de objetos: name, phone, relationship)

- **Arquivos:**
  - `photos` (JSONB, array de URLs)

- **Metadados:**
  - `created_at` (TIMESTAMP WITH TIME ZONE)
  - `updated_at` (TIMESTAMP WITH TIME ZONE)
  - `created_by` (VARCHAR(255))

**Índices criados:**
- `idx_patients_name` - Busca por nome
- `idx_patients_cpf` - Busca por CPF
- `idx_patients_email` - Busca por email
- `idx_patients_created_at` - Ordenação por data de criação

**Triggers:**
- `update_patients_updated_at` - Atualiza `updated_at` automaticamente

---

### 2. `002_create_patient_documents_table.sql`
**Tabela: `patient_documents`**

Campos criados:
- `id` (UUID, PK)
- `patient_id` (UUID, FK para `patients.id`, ON DELETE CASCADE)
- `name` (VARCHAR(255), NOT NULL)
- `type` (VARCHAR(50), NOT NULL) - Ex: 'PDF', 'DOC', 'DOCX', 'IMAGE'
- `url` (TEXT, NOT NULL)
- `size` (BIGINT) - Tamanho em bytes
- `uploaded_at` (TIMESTAMP WITH TIME ZONE)

**Índices criados:**
- `idx_patient_documents_patient_id` - Busca por paciente
- `idx_patient_documents_type` - Busca por tipo de documento

**Foreign Keys:**
- `patient_documents_patient_id_fkey` - Relacionamento com `patients`

---

### 3. `003_create_consultations_table.sql`
**Tabela: `consultations`**

Campos criados:
- `id` (UUID, PK)

- **Relacionamento:**
  - `patient_id` (UUID, FK para `patients.id`, ON DELETE SET NULL) - Opcional para consultas anônimas
  - `patient_name` (VARCHAR(255)) - Nome para consultas anônimas

- **Transcrição:**
  - `transcript` (TEXT) - Transcrição completa da consulta

- **Análises da IA (cascata):**
  - `summary` (TEXT) - Resumo clínico
  - `anamnesis` (TEXT) - Anamnese estruturada
  - `prescription` (TEXT) - Prescrição (se houver)
  - `suggested_questions` (JSONB, array) - Perguntas sugeridas pela IA

- **Notas e chat:**
  - `doctor_notes` (TEXT) - Notas do médico
  - `chat_messages` (JSONB, array) - Histórico de chat com IA

- **Timestamps:**
  - `started_at` (TIMESTAMP WITH TIME ZONE) - Início da consulta
  - `ended_at` (TIMESTAMP WITH TIME ZONE) - Fim da consulta
  - `created_at` (TIMESTAMP WITH TIME ZONE)
  - `updated_at` (TIMESTAMP WITH TIME ZONE)

**Índices criados:**
- `idx_consultations_patient_id` - Busca por paciente
- `idx_consultations_started_at` - Ordenação por data de início
- `idx_consultations_ended_at` - Ordenação por data de fim

**Triggers:**
- `update_consultations_updated_at` - Atualiza `updated_at` automaticamente

---

## 📋 Como Aplicar as Migrações

### Opção 1: Via Docker Compose (Recomendado)
As migrações são aplicadas automaticamente quando o container PostgreSQL é criado pela primeira vez:

```bash
cd backend/docker
docker-compose down -v  # Remove volumes para recriar do zero
docker-compose up -d postgres  # Cria o banco e aplica migrações
```

### Opção 2: Manualmente
```bash
# Conectar ao banco
docker exec -it medos-postgres psql -U medos_user -d medos_db

# Executar migrações (já devem estar aplicadas automaticamente)
\i /docker-entrypoint-initdb.d/001_create_patients_table.sql
\i /docker-entrypoint-initdb.d/002_create_patient_documents_table.sql
\i /docker-entrypoint-initdb.d/003_create_consultations_table.sql
```

### Opção 3: Verificar se foram aplicadas
```bash
docker exec -it medos-postgres psql -U medos_user -d medos_db -c "\dt"
```

---

## 🔄 Próximos Passos

1. **Integrar com o código:** Substituir o armazenamento em memória (Map) por queries SQL
2. **Adicionar ORM (opcional):** Considerar usar Prisma, TypeORM ou Sequelize
3. **Adicionar mais campos se necessário:** Baseado no uso real do sistema

---

## ⚠️ Notas Importantes

- As migrações usam `IF NOT EXISTS` para serem idempotentes
- Os arquivos são executados em ordem alfabética pelo PostgreSQL
- O volume `postgres_data` persiste os dados mesmo após reiniciar o container
- Para recriar o banco do zero, use `docker-compose down -v`


