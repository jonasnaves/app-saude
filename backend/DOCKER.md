# Guia Docker - MedOS Backend

Este guia explica como usar Docker para desenvolvimento e produção do backend MedOS.

## Pré-requisitos

- Docker Desktop instalado (Mac/Windows)
- Docker Compose instalado
- Arquivo `.env` configurado (veja `.env.example`)

## Estrutura Docker

```
backend/
├── docker/
│   ├── Dockerfile          # Build da imagem do backend
│   ├── docker-compose.yml  # Orquestração de serviços
│   └── entrypoint.sh       # Script que roda migrações antes de iniciar
└── .env                    # Variáveis de ambiente (não commitado)
```

## Configuração Inicial

### 1. Criar arquivo .env

```bash
cd backend
cp .env.example .env
```

Edite o `.env` e configure:
- `DB_PASSWORD` - Senha do PostgreSQL
- `JWT_SECRET` - Secret para JWT
- `JWT_REFRESH_SECRET` - Secret para refresh token
- `GEMINI_API_KEY` - Chave da API Gemini

### 2. Iniciar serviços

```bash
# Build e start (primeira vez)
npm run docker:build
npm run docker:up

# Ou tudo de uma vez
docker-compose -f docker/docker-compose.yml up --build
```

Isso vai:
1. Criar e iniciar container PostgreSQL
2. Build da imagem do backend
3. Executar migrações SQL automaticamente
4. Iniciar servidor backend na porta 3000

## Comandos Disponíveis

### Desenvolvimento

```bash
# Iniciar serviços
npm run docker:up

# Ver logs
npm run docker:logs

# Parar serviços
npm run docker:down

# Reiniciar
npm run docker:restart

# Rebuild (após mudanças no código)
npm run docker:build
```

### Migrações

As migrações SQL são executadas **automaticamente** quando o container inicia.

Para executar manualmente:

```bash
# Dentro do container
docker exec -it medos-backend ./scripts/run-migrations.sh

# Ou localmente (se tiver psql instalado)
npm run migration:sql:run

# Verificar status
npm run migration:sql:check
```

## Adicionar Nova Migração SQL

1. **Criar arquivo SQL:**
```bash
touch migrations/sql/$(date +%Y%m%d%H%M%S)-nome-da-migracao.sql
```

2. **Escrever SQL:**
```sql
-- Exemplo: Adicionar coluna
ALTER TABLE users ADD COLUMN IF NOT EXISTS phone VARCHAR(20);

-- Registrar migração
INSERT INTO schema_migrations (version) 
VALUES ('20240102120000-add-phone-to-users')
ON CONFLICT (version) DO NOTHING;
```

3. **Commit no Git**

4. **No próximo build/restart**, a migração será aplicada automaticamente

## Acessar Serviços

### Backend API
- URL: `http://localhost:3000`
- Health check: `http://localhost:3000/health`

### PostgreSQL
- Host: `localhost`
- Porta: `5432` (ou a configurada no .env)
- Database: `medos_db`
- User: `medos_user` (ou configurado no .env)
- Password: (do .env)

### Conectar ao PostgreSQL

```bash
# Via psql
psql -h localhost -p 5432 -U medos_user -d medos_db

# Via Docker
docker exec -it medos-postgres psql -U medos_user -d medos_db
```

## Desenvolvimento com Hot Reload

Para desenvolvimento com hot reload, você pode:

1. **Rodar backend localmente** (fora do Docker):
```bash
# Terminal 1: PostgreSQL em Docker
docker-compose -f docker/docker-compose.yml up postgres -d

# Terminal 2: Backend local
npm run dev
```

2. **Ou usar volumes no Docker** (já configurado no docker-compose.yml)

## Troubleshooting

### Container não inicia

```bash
# Ver logs
docker logs medos-backend
docker logs medos-postgres

# Verificar se PostgreSQL está pronto
docker exec medos-postgres pg_isready -U medos_user
```

### Migrações falhando

```bash
# Verificar status
npm run migration:sql:check

# Executar manualmente
docker exec -it medos-backend ./scripts/run-migrations.sh
```

### Porta já em uso

Altere a porta no `.env`:
```env
PORT=3001
DB_PORT=5433
```

### Limpar tudo e recomeçar

```bash
# Parar e remover containers e volumes
docker-compose -f docker/docker-compose.yml down -v

# Rebuild
npm run docker:build
npm run docker:up
```

## Produção

Para produção, ajuste:

1. **Variáveis de ambiente** com valores seguros
2. **Secrets** via Docker secrets ou variáveis de ambiente do host
3. **Networks** apropriadas
4. **Volumes** persistentes para PostgreSQL
5. **Health checks** configurados
6. **Restart policies** adequadas

## Estrutura de Rede

```
┌─────────────────┐
│   Mac (Host)    │
│  localhost:3000 │
└────────┬────────┘
         │
    ┌────┴────┐
    │         │
┌───▼───┐ ┌──▼────┐
│Backend│ │Postgres│
│ :3000 │ │ :5432  │
└───┬───┘ └───┬───┘
    └────┬────┘
         │
    medos-network
```

O app Flutter no Mac acessa `localhost:3000`, que é mapeado para o container do backend.

