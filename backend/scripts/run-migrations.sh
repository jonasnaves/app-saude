#!/bin/sh

# Script para executar migrações SQL
# Verifica quais migrações já foram aplicadas e aplica apenas as pendentes

set -e

# Obter diretório do script (compatível com sh)
SCRIPT_DIR="$(dirname "$0")"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MIGRATIONS_DIR="$PROJECT_ROOT/migrations/sql"

# Se estiver no Docker, usar caminho absoluto
if [ -d "/app/migrations/sql" ]; then
    MIGRATIONS_DIR="/app/migrations/sql"
fi
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_USERNAME="${DB_USERNAME:-postgres}"
DB_PASSWORD="${DB_PASSWORD:-postgres}"
DB_DATABASE="${DB_DATABASE:-medos_db}"

export PGPASSWORD="$DB_PASSWORD"

echo "=========================================="
echo "Executando Migrações SQL"
echo "=========================================="
echo "Database: $DB_DATABASE@$DB_HOST:$DB_PORT"
echo ""

# Verificar se diretório de migrações existe
if [ ! -d "$MIGRATIONS_DIR" ]; then
    echo "Erro: Diretório de migrações não encontrado: $MIGRATIONS_DIR"
    echo "Tentando criar diretório..."
    mkdir -p "$MIGRATIONS_DIR"
    if [ ! -d "$MIGRATIONS_DIR" ]; then
        exit 1
    fi
fi

# Criar tabela schema_migrations se não existir
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USERNAME" -d "$DB_DATABASE" <<EOF
CREATE TABLE IF NOT EXISTS schema_migrations (
    version VARCHAR(255) PRIMARY KEY,
    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
EOF

# Obter lista de migrações já aplicadas
APPLIED_MIGRATIONS=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USERNAME" -d "$DB_DATABASE" -t -c "SELECT version FROM schema_migrations;" | tr -d ' ')

# Contador de migrações aplicadas
APPLIED_COUNT=0

# Processar cada arquivo SQL em ordem cronológica
for migration_file in $(ls -1 "$MIGRATIONS_DIR"/*.sql 2>/dev/null | sort); do
    filename=$(basename "$migration_file")
    version=$(echo "$filename" | cut -d'-' -f1)
    
    # Verificar se migração já foi aplicada
    if echo "$APPLIED_MIGRATIONS" | grep -q "^$version$"; then
        echo "✓ Migração $filename já aplicada, pulando..."
        continue
    fi
    
    echo ""
    echo "Aplicando migração: $filename"
    echo "----------------------------------------"
    
    # Executar migração dentro de transação
    if psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USERNAME" -d "$DB_DATABASE" -f "$migration_file" -v ON_ERROR_STOP=1; then
        echo "✓ Migração $filename aplicada com sucesso"
        APPLIED_COUNT=$((APPLIED_COUNT + 1))
    else
        echo "✗ Erro ao aplicar migração $filename"
        exit 1
    fi
done

echo ""
echo "=========================================="
if [ $APPLIED_COUNT -eq 0 ]; then
    echo "Nenhuma migração pendente. Banco de dados está atualizado."
else
    echo "Total de migrações aplicadas: $APPLIED_COUNT"
fi
echo "=========================================="

unset PGPASSWORD

