import { Pool } from 'pg';

// Configuração do pool de conexões PostgreSQL
const pool = new Pool({
  host: process.env.DB_HOST || 'postgres',
  port: parseInt(process.env.DB_PORT || '5432'),
  database: process.env.DB_NAME || 'medos_db',
  user: process.env.DB_USER || 'medos_user',
  password: process.env.DB_PASSWORD || 'medos_password',
  max: 20, // Máximo de conexões no pool
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

// Testar conexão na inicialização
pool.on('connect', () => {
  console.log('✅ Conectado ao PostgreSQL');
});

pool.on('error', (err) => {
  console.error('❌ Erro inesperado no cliente PostgreSQL:', err);
  process.exit(-1);
});

export default pool;


