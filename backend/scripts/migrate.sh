#!/bin/bash

# Script helper para executar migrações
# Uso: ./scripts/migrate.sh [run|revert|show|generate NomeDaMigracao]

set -e

cd "$(dirname "$0")/.."

case "$1" in
  run)
    echo "Aplicando migrações..."
    npm run migration:run
    ;;
  revert)
    echo "Revertendo última migração..."
    npm run migration:revert
    ;;
  show)
    echo "Status das migrações:"
    npm run migration:show
    ;;
  generate)
    if [ -z "$2" ]; then
      echo "Erro: Nome da migração é obrigatório"
      echo "Uso: ./scripts/migrate.sh generate NomeDaMigracao"
      exit 1
    fi
    echo "Gerando migração: $2"
    npm run migration:generate -- "src/migrations/$2"
    ;;
  *)
    echo "Uso: ./scripts/migrate.sh [run|revert|show|generate NomeDaMigracao]"
    exit 1
    ;;
esac

