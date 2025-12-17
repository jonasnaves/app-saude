# Sistema de Migrações - Quick Start

## Primeira Vez

1. **Criar banco de dados:**
```sql
CREATE DATABASE medos_db;
```

2. **Aplicar migração inicial:**
```bash
npm run migration:run
```

Isso vai criar todas as tabelas do sistema.

## Adicionar Nova Coluna/Tabela

1. **Modificar o modelo** em `src/models/`

2. **Gerar migração:**
```bash
npm run migration:generate -- src/migrations/NomeDaMigracao
```

3. **Revisar** o arquivo gerado em `src/migrations/`

4. **Aplicar:**
```bash
npm run migration:run
```

5. **Commit:**
```bash
git add src/migrations/
git commit -m "feat: add new field"
```

## Comandos Rápidos

```bash
# Ver status
npm run migration:show

# Aplicar todas
npm run migration:run

# Reverter última
npm run migration:revert
```

Veja o guia completo em [MIGRATIONS.md](MIGRATIONS.md)

