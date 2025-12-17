// Setup para testes de integração
import { AppDataSource } from '../config/database';

beforeAll(async () => {
  // Configurar banco de dados de teste se necessário
});

afterAll(async () => {
  // Limpar após testes
  if (AppDataSource.isInitialized) {
    await AppDataSource.destroy();
  }
});

