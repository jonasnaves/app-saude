# Guia de Migrações - MedOS

Este documento explica como usar o sistema de migrações SQL para versionar e controlar alterações no banco de dados.

> **Nota**: O projeto agora usa **migrações SQL puras** em vez de TypeORM migrations. As migrações são executadas automaticamente quando o backend inicia no Docker.

## Conceitos

### O que são Migrações?

Migrações são arquivos que descrevem mudanças no esquema do banco de dados de forma versionada e controlada. Cada migração representa uma alteração específica (criar tabela, adicionar coluna, criar índice, etc.).

### Por que usar Migrações?

- **Versionamento**: Cada mudança no banco é versionada e pode ser rastreada
- **Controle**: Você sabe exatamente quais mudanças foram aplicadas
- **Reprodutibilidade**: Qualquer ambiente pode aplicar as mesmas migrações
- **Rollback**: Possibilidade de reverter mudanças se necessário
- **Colaboração**: Time pode trabalhar com as mesmas mudanças de banco

## Estrutura

```
backend/
├── migrations/
│   └── sql/
│       ├── 20240101120000-initial-schema.sql
│       ├── 20240102120000-add-fcm-token.sql
│       └── ...
├── scripts/
│   ├── run-migrations.sh    # Script para executar migrações
│   └── check-migrations.js  # Verificar status
```

Cada migração SQL tem:
- **Timestamp**: Formato `YYYYMMDDHHMMSS` que identifica a ordem
- **Nome**: Descrição da mudança (ex: `add-fcm-token`)
- **SQL puro**: Comandos SQL para aplicar a mudança
- **Registro**: Deve inserir na tabela `schema_migrations` ao final

## Comandos Disponíveis

### Criar Nova Migração SQL

Crie um novo arquivo SQL com timestamp e descrição:

```bash
# Formato: YYYYMMDDHHMMSS-descricao.sql
touch migrations/sql/$(date +%Y%m%d%H%M%S)-add-fcm-token.sql
```

**Exemplo:**
```bash
touch migrations/sql/20240102120000-add-fcm-token.sql
```

### Aplicar Migrações

**No Docker (automático):**
As migrações são executadas automaticamente quando o backend inicia.

**Manualmente:**
```bash
# Dentro do container
docker exec -it medos-backend ./scripts/run-migrations.sh

# Ou localmente (se tiver psql instalado)
npm run migration:sql:run
```

Isso vai:
1. Verificar tabela `schema_migrations` para ver o que já foi aplicado
2. Aplicar apenas migrações pendentes em ordem cronológica
3. Registrar cada migração aplicada

### Ver Status das Migrações

Para ver quais migrações foram aplicadas e quais estão pendentes:

```bash
npm run migration:sql:check
```

Ou dentro do container:
```bash
docker exec -it medos-backend node scripts/check-migrations.js
```

## Workflow de Desenvolvimento

### 1. Criar Arquivo de Migração SQL

```bash
cd backend
touch migrations/sql/$(date +%Y%m%d%H%M%S)-add-fcm-token.sql
```

### 2. Escrever SQL da Migração

Edite o arquivo criado:

```sql
-- Adicionar coluna fcmToken à tabela users
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS "fcmToken" VARCHAR(255);

-- Criar índice se necessário
CREATE INDEX IF NOT EXISTS "IDX_users_fcmToken" 
ON users("fcmToken") 
WHERE "fcmToken" IS NOT NULL;

-- Registrar migração
INSERT INTO schema_migrations (version) 
VALUES ('20240102120000-add-fcm-token')
ON CONFLICT (version) DO NOTHING;
```

### 3. Testar Localmente

```bash
# Executar migração manualmente
npm run migration:sql:run

# Ou reiniciar Docker
npm run docker:restart
```

### 4. Verificar Status

```bash
npm run migration:sql:check
```

### 5. Commit no Git

```bash
git add migrations/sql/
git commit -m "feat: add FCM token to users"
```

### 6. Deploy

No próximo build/restart do Docker, a migração será aplicada automaticamente.

## Boas Práticas

### ✅ FAZER

- Sempre revisar migrações geradas antes de aplicar
- Testar migrações em ambiente de desenvolvimento primeiro
- Fazer backup do banco antes de aplicar em produção
- Commitar migrações junto com o código que as usa
- Usar nomes descritivos para migrações
- Implementar método `down()` corretamente para rollback

### ❌ NÃO FAZER

- Não editar migrações já aplicadas em produção
- Não usar `synchronize: true` em produção
- Não aplicar migrações manualmente no banco (sempre usar CLI)
- Não deletar migrações já aplicadas
- Não pular etapas do workflow

## Exemplos Comuns

### Adicionar Coluna

```sql
-- migrations/sql/20240102120000-add-phone-to-users.sql
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS phone VARCHAR(20);

-- Registrar migração
INSERT INTO schema_migrations (version) 
VALUES ('20240102120000-add-phone-to-users')
ON CONFLICT (version) DO NOTHING;
```

### Criar Índice

```sql
-- migrations/sql/20240102120000-add-index-consultations.sql
CREATE INDEX IF NOT EXISTS "IDX_consultations_startedAt" 
ON consultations("startedAt");

-- Registrar migração
INSERT INTO schema_migrations (version) 
VALUES ('20240102120000-add-index-consultations')
ON CONFLICT (version) DO NOTHING;
```

### Adicionar Foreign Key

```sql
-- migrations/sql/20240102120000-add-doctor-fk.sql
ALTER TABLE consultations
ADD CONSTRAINT "FK_consultations_doctorId"
FOREIGN KEY ("doctorId")
REFERENCES doctors(id)
ON DELETE CASCADE;

-- Registrar migração
INSERT INTO schema_migrations (version) 
VALUES ('20240102120000-add-doctor-fk')
ON CONFLICT (version) DO NOTHING;
```

### Criar Nova Tabela

```sql
-- migrations/sql/20240102120000-create-doctors.sql
CREATE TABLE IF NOT EXISTS doctors (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    specialty VARCHAR(255) NOT NULL,
    "createdAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS "IDX_doctors_specialty" 
ON doctors(specialty);

-- Registrar migração
INSERT INTO schema_migrations (version) 
VALUES ('20240102120000-create-doctors')
ON CONFLICT (version) DO NOTHING;
```

## Troubleshooting

### Erro: "Migration already executed"

A migração já foi aplicada. Verifique com `npm run migration:show`.

### Erro: "Cannot find module"

Certifique-se de que o TypeScript está compilado ou use `ts-node`.

### Erro: "Relation already exists"

A estrutura já existe no banco. Você pode precisar fazer rollback primeiro.

## Variáveis de Ambiente

Certifique-se de ter as variáveis corretas no `.env`:

```env
DB_HOST=localhost
DB_PORT=5432
DB_USERNAME=postgres
DB_PASSWORD=postgres
DB_DATABASE=medos_db
```

## Tabela de Migrações

O sistema cria automaticamente uma tabela `schema_migrations` no banco que rastreia quais migrações foram aplicadas:

```sql
SELECT * FROM schema_migrations ORDER BY applied_at;
```

Esta tabela não deve ser editada manualmente.

## Scripts Disponíveis

### run-migrations.sh

Script bash que executa todas as migrações pendentes:

```bash
./scripts/run-migrations.sh
```

Funcionalidades:
- Lê arquivos SQL em ordem cronológica
- Verifica `schema_migrations` para ver o que já foi aplicado
- Aplica apenas migrações pendentes
- Registra migrações aplicadas
- Suporta transações (rollback em caso de erro)

### check-migrations.js

Script Node.js para verificar status:

```bash
node scripts/check-migrations.js
```

Mostra:
- Lista de todas as migrações
- Status (aplicada/pendente)
- Contadores (total, aplicadas, pendentes)

## Checklist de Deploy

Antes de fazer deploy em produção:

- [ ] Todas as migrações foram testadas localmente
- [ ] Backup do banco de dados foi feito
- [ ] Migrações foram commitadas no Git
- [ ] Variáveis de ambiente estão configuradas
- [ ] Executar `npm run migration:run` antes de iniciar o servidor
- [ ] Verificar logs para confirmar que migrações foram aplicadas

