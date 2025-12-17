import { DataSource } from 'typeorm';
import { User } from '../models/User';
import { Consultation } from '../models/Consultation';
import { MedicalRecord } from '../models/MedicalRecord';
import { SupportChat } from '../models/SupportChat';
import { Transaction } from '../models/Transaction';
import { Drug } from '../models/Drug';

export const AppDataSource = new DataSource({
  type: 'postgres',
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '5432'),
  username: process.env.DB_USERNAME || 'postgres',
  password: process.env.DB_PASSWORD || 'postgres',
  database: process.env.DB_DATABASE || 'medos_db',
  synchronize: false, // NUNCA usar synchronize - usar migrações sempre
  logging: process.env.NODE_ENV === 'development',
  entities: [User, Consultation, MedicalRecord, SupportChat, Transaction, Drug],
  migrations: ['src/migrations/**/*.ts'],
  migrationsTableName: 'migrations',
  migrationsRun: false, // Migrações devem ser executadas manualmente
  subscribers: ['src/subscribers/**/*.ts'],
});

