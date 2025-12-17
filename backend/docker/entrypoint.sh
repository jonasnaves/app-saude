#!/bin/sh

# Entrypoint script que executa migrações antes de iniciar o servidor

set -e

echo "=========================================="
echo "Iniciando Backend MedOS"
echo "=========================================="

# Aguardar PostgreSQL estar pronto
echo "Aguardando PostgreSQL..."
until PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USERNAME" -d "$DB_DATABASE" -c '\q' 2>/dev/null; do
  echo "PostgreSQL não está pronto, aguardando..."
  sleep 1
done

echo "PostgreSQL está pronto!"

# Executar migrações
echo ""
echo "Executando migrações..."
export PATH="/usr/local/bin:/usr/bin:/bin:$PATH"
cd /app

# Verificar se script existe
if [ ! -f "/app/scripts/run-migrations.sh" ]; then
    echo "ERRO CRÍTICO: Script de migrações não encontrado em /app/scripts/run-migrations.sh"
    echo "Conteúdo de /app/scripts:"
    ls -la /app/scripts/ 2>&1 || echo "Diretório não existe"
    exit 1
fi

# Executar migrações
if ! sh /app/scripts/run-migrations.sh; then
    echo "ERRO: Falha ao executar migrações. Abortando..."
    exit 1
fi

echo ""
echo "Migrações concluídas. Iniciando servidor..."
echo ""

# Executar comando passado (geralmente node dist/app.js)
exec "$@"

