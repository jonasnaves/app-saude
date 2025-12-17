#!/usr/bin/env node

/**
 * Script Node.js para verificar status das migrações
 * Pode ser usado como alternativa ao script bash
 */

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const MIGRATIONS_DIR = path.join(__dirname, '../migrations/sql');

const DB_HOST = process.env.DB_HOST || 'localhost';
const DB_PORT = process.env.DB_PORT || '5432';
const DB_USERNAME = process.env.DB_USERNAME || 'postgres';
const DB_PASSWORD = process.env.DB_PASSWORD || 'postgres';
const DB_DATABASE = process.env.DB_DATABASE || 'medos_db';

function getAppliedMigrations() {
  try {
    const query = `SELECT version FROM schema_migrations ORDER BY version;`;
    const result = execSync(
      `PGPASSWORD="${DB_PASSWORD}" psql -h ${DB_HOST} -p ${DB_PORT} -U ${DB_USERNAME} -d ${DB_DATABASE} -t -c "${query}"`,
      { encoding: 'utf-8' }
    );
    return result
      .split('\n')
      .map((line) => line.trim())
      .filter((line) => line.length > 0);
  } catch (error) {
    return [];
  }
}

function getMigrationFiles() {
  if (!fs.existsSync(MIGRATIONS_DIR)) {
    return [];
  }
  return fs
    .readdirSync(MIGRATIONS_DIR)
    .filter((file) => file.endsWith('.sql'))
    .sort()
    .map((file) => {
      const version = file.split('-')[0];
      return { file, version };
    });
}

function main() {
  console.log('==========================================');
  console.log('Status das Migrações');
  console.log('==========================================');
  console.log(`Database: ${DB_DATABASE}@${DB_HOST}:${DB_PORT}\n`);

  const applied = getAppliedMigrations();
  const files = getMigrationFiles();

  if (files.length === 0) {
    console.log('Nenhuma migração encontrada.');
    return;
  }

  console.log('Migrações:');
  console.log('----------------------------------------');

  files.forEach(({ file, version }) => {
    const isApplied = applied.includes(version);
    const status = isApplied ? '✓ Aplicada' : '○ Pendente';
    const icon = isApplied ? '✓' : '○';
    console.log(`${icon} ${file.padEnd(40)} ${status}`);
  });

  const pending = files.filter(({ version }) => !applied.includes(version));
  
  console.log('\n==========================================');
  console.log(`Total: ${files.length} migrações`);
  console.log(`Aplicadas: ${applied.length}`);
  console.log(`Pendentes: ${pending.length}`);
  console.log('==========================================');
}

main();

