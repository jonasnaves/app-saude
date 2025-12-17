import { MigrationInterface, QueryRunner, TableColumn } from 'typeorm';

/**
 * EXEMPLO DE MIGRAÇÃO
 * 
 * Esta é uma migração de exemplo mostrando como adicionar um novo campo.
 * Para criar uma migração real, use:
 * npm run migration:generate -- src/migrations/AddFCMTokenToUser
 * 
 * Depois, delete este arquivo de exemplo.
 */
export class AddFCMTokenToUser1734567890124 implements MigrationInterface {
  name = 'AddFCMTokenToUser1734567890124';

  public async up(queryRunner: QueryRunner): Promise<void> {
    // Adicionar coluna fcmToken à tabela users
    await queryRunner.addColumn(
      'users',
      new TableColumn({
        name: 'fcmToken',
        type: 'varchar',
        length: '255',
        isNullable: true,
        comment: 'Token FCM para notificações push',
      })
    );

    // Opcional: Criar índice para busca rápida
    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS "IDX_users_fcmToken" 
      ON "users" ("fcmToken") 
      WHERE "fcmToken" IS NOT NULL
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    // Remover índice primeiro
    await queryRunner.query(`DROP INDEX IF EXISTS "IDX_users_fcmToken"`);

    // Remover coluna
    await queryRunner.dropColumn('users', 'fcmToken');
  }
}

