# Multi-stage build para otimizar tamanho da imagem

# Stage 1: Build
FROM node:20-alpine AS builder

WORKDIR /app

# Copiar arquivos de dependências
COPY package*.json ./
COPY tsconfig.json ./

# Instalar dependências
RUN npm ci

# Copiar código fonte
COPY src ./src
COPY migrations ./migrations
COPY scripts ./scripts

# Compilar TypeScript
RUN npm run build

# Stage 2: Production
FROM node:20-alpine

WORKDIR /app

# Instalar psql para executar migrações SQL
RUN apk add --no-cache postgresql-client

# Copiar package.json e instalar apenas dependências de produção
COPY package*.json ./
RUN npm ci --only=production

# Copiar código compilado
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/migrations ./migrations
COPY --from=builder /app/scripts ./scripts

# Garantir que scripts têm permissão de execução
RUN chmod +x ./scripts/*.sh && \
    ls -la ./scripts/ && \
    test -f ./scripts/run-migrations.sh || (echo "ERRO: run-migrations.sh não encontrado!" && exit 1)

# Copiar entrypoint
COPY docker/entrypoint.sh ./entrypoint.sh
RUN chmod +x ./entrypoint.sh ./scripts/run-migrations.sh

# Variáveis de ambiente padrão
ENV NODE_ENV=production
ENV PORT=3000

# Expor porta
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Entrypoint que roda migrações antes de iniciar
ENTRYPOINT ["./entrypoint.sh"]
CMD ["node", "dist/app.js"]

