import { MigrationInterface, QueryRunner, Table, TableColumn, TableForeignKey, TableIndex } from 'typeorm';

export class InitialMigration1734567890123 implements MigrationInterface {
  name = 'InitialMigration1734567890123';

  public async up(queryRunner: QueryRunner): Promise<void> {
    // Habilitar extensão UUID se não existir
    await queryRunner.query(`CREATE EXTENSION IF NOT EXISTS "uuid-ossp"`);

    // Criar tabela users
    await queryRunner.createTable(
      new Table({
        name: 'users',
        columns: [
          {
            name: 'id',
            type: 'uuid',
            isPrimary: true,
            generationStrategy: 'uuid',
            default: 'uuid_generate_v4()',
          },
          {
            name: 'name',
            type: 'varchar',
            isNullable: false,
          },
          {
            name: 'email',
            type: 'varchar',
            isUnique: true,
            isNullable: false,
          },
          {
            name: 'passwordHash',
            type: 'varchar',
            isNullable: false,
          },
          {
            name: 'credits',
            type: 'decimal',
            precision: 10,
            scale: 2,
            default: 0,
          },
          {
            name: 'createdAt',
            type: 'timestamp',
            default: 'CURRENT_TIMESTAMP',
          },
        ],
      }),
      true
    );

    // Criar índice único para email
    await queryRunner.createIndex(
      'users',
      new TableIndex({
        name: 'IDX_users_email',
        columnNames: ['email'],
        isUnique: true,
      })
    );

    // Criar tabela consultations
    await queryRunner.createTable(
      new Table({
        name: 'consultations',
        columns: [
          {
            name: 'id',
            type: 'uuid',
            isPrimary: true,
            generationStrategy: 'uuid',
            default: 'uuid_generate_v4()',
          },
          {
            name: 'userId',
            type: 'uuid',
            isNullable: false,
          },
          {
            name: 'patientName',
            type: 'varchar',
            isNullable: true,
          },
          {
            name: 'transcript',
            type: 'text',
            isNullable: true,
          },
          {
            name: 'startedAt',
            type: 'timestamp',
            isNullable: false,
          },
          {
            name: 'endedAt',
            type: 'timestamp',
            isNullable: true,
          },
          {
            name: 'createdAt',
            type: 'timestamp',
            default: 'CURRENT_TIMESTAMP',
          },
        ],
      }),
      true
    );

    // Foreign key para consultations -> users
    await queryRunner.createForeignKey(
      'consultations',
      new TableForeignKey({
        name: 'FK_consultations_userId',
        columnNames: ['userId'],
        referencedColumnNames: ['id'],
        referencedTableName: 'users',
        onDelete: 'CASCADE',
      })
    );

    // Criar índice para userId em consultations
    await queryRunner.createIndex(
      'consultations',
      new TableIndex({
        name: 'IDX_consultations_userId',
        columnNames: ['userId'],
      })
    );

    // Criar tabela medical_records
    await queryRunner.createTable(
      new Table({
        name: 'medical_records',
        columns: [
          {
            name: 'id',
            type: 'uuid',
            isPrimary: true,
            generationStrategy: 'uuid',
            default: 'uuid_generate_v4()',
          },
          {
            name: 'consultationId',
            type: 'uuid',
            isUnique: true,
            isNullable: false,
          },
          {
            name: 'anamnesis',
            type: 'text',
            isNullable: false,
          },
          {
            name: 'physicalExam',
            type: 'text',
            isNullable: false,
          },
          {
            name: 'diagnosisSuggestions',
            type: 'text',
            isArray: true,
            isNullable: false,
          },
          {
            name: 'conduct',
            type: 'text',
            isNullable: false,
          },
          {
            name: 'createdAt',
            type: 'timestamp',
            default: 'CURRENT_TIMESTAMP',
          },
        ],
      }),
      true
    );

    // Foreign key para medical_records -> consultations
    await queryRunner.createForeignKey(
      'medical_records',
      new TableForeignKey({
        name: 'FK_medical_records_consultationId',
        columnNames: ['consultationId'],
        referencedColumnNames: ['id'],
        referencedTableName: 'consultations',
        onDelete: 'CASCADE',
      })
    );

    // Criar tabela support_chats
    await queryRunner.createTable(
      new Table({
        name: 'support_chats',
        columns: [
          {
            name: 'id',
            type: 'uuid',
            isPrimary: true,
            generationStrategy: 'uuid',
            default: 'uuid_generate_v4()',
          },
          {
            name: 'userId',
            type: 'uuid',
            isNullable: false,
          },
          {
            name: 'mode',
            type: 'enum',
            enum: ['medical', 'legal', 'marketing'],
            isNullable: false,
          },
          {
            name: 'messages',
            type: 'jsonb',
            isNullable: false,
          },
          {
            name: 'createdAt',
            type: 'timestamp',
            default: 'CURRENT_TIMESTAMP',
          },
        ],
      }),
      true
    );

    // Foreign key para support_chats -> users
    await queryRunner.createForeignKey(
      'support_chats',
      new TableForeignKey({
        name: 'FK_support_chats_userId',
        columnNames: ['userId'],
        referencedColumnNames: ['id'],
        referencedTableName: 'users',
        onDelete: 'CASCADE',
      })
    );

    // Criar índice para userId em support_chats
    await queryRunner.createIndex(
      'support_chats',
      new TableIndex({
        name: 'IDX_support_chats_userId',
        columnNames: ['userId'],
      })
    );

    // Criar tabela transactions
    await queryRunner.createTable(
      new Table({
        name: 'transactions',
        columns: [
          {
            name: 'id',
            type: 'uuid',
            isPrimary: true,
            generationStrategy: 'uuid',
            default: 'uuid_generate_v4()',
          },
          {
            name: 'userId',
            type: 'uuid',
            isNullable: false,
          },
          {
            name: 'type',
            type: 'enum',
            enum: ['credit', 'debit'],
            isNullable: false,
          },
          {
            name: 'amount',
            type: 'decimal',
            precision: 10,
            scale: 2,
            isNullable: false,
          },
          {
            name: 'description',
            type: 'text',
            isNullable: true,
          },
          {
            name: 'createdAt',
            type: 'timestamp',
            default: 'CURRENT_TIMESTAMP',
          },
        ],
      }),
      true
    );

    // Foreign key para transactions -> users
    await queryRunner.createForeignKey(
      'transactions',
      new TableForeignKey({
        name: 'FK_transactions_userId',
        columnNames: ['userId'],
        referencedColumnNames: ['id'],
        referencedTableName: 'users',
        onDelete: 'CASCADE',
      })
    );

    // Criar índice para userId em transactions
    await queryRunner.createIndex(
      'transactions',
      new TableIndex({
        name: 'IDX_transactions_userId',
        columnNames: ['userId'],
      })
    );

    // Criar tabela drugs
    await queryRunner.createTable(
      new Table({
        name: 'drugs',
        columns: [
          {
            name: 'id',
            type: 'uuid',
            isPrimary: true,
            generationStrategy: 'uuid',
            default: 'uuid_generate_v4()',
          },
          {
            name: 'name',
            type: 'varchar',
            isNullable: false,
          },
          {
            name: 'dosage',
            type: 'varchar',
            isNullable: false,
          },
          {
            name: 'category',
            type: 'varchar',
            isNullable: false,
          },
          {
            name: 'price',
            type: 'decimal',
            precision: 10,
            scale: 2,
            isNullable: true,
          },
          {
            name: 'createdAt',
            type: 'timestamp',
            default: 'CURRENT_TIMESTAMP',
          },
        ],
      }),
      true
    );

    // Criar índices para busca em drugs
    await queryRunner.createIndex(
      'drugs',
      new TableIndex({
        name: 'IDX_drugs_name',
        columnNames: ['name'],
      })
    );

    await queryRunner.createIndex(
      'drugs',
      new TableIndex({
        name: 'IDX_drugs_category',
        columnNames: ['category'],
      })
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    // Remover índices
    await queryRunner.dropIndex('drugs', 'IDX_drugs_category');
    await queryRunner.dropIndex('drugs', 'IDX_drugs_name');
    await queryRunner.dropIndex('transactions', 'IDX_transactions_userId');
    await queryRunner.dropIndex('support_chats', 'IDX_support_chats_userId');
    await queryRunner.dropIndex('consultations', 'IDX_consultations_userId');
    await queryRunner.dropIndex('users', 'IDX_users_email');

    // Remover foreign keys
    await queryRunner.dropForeignKey('transactions', 'FK_transactions_userId');
    await queryRunner.dropForeignKey('support_chats', 'FK_support_chats_userId');
    await queryRunner.dropForeignKey('medical_records', 'FK_medical_records_consultationId');
    await queryRunner.dropForeignKey('consultations', 'FK_consultations_userId');

    // Remover tabelas (ordem inversa por causa das dependências)
    await queryRunner.dropTable('drugs');
    await queryRunner.dropTable('transactions');
    await queryRunner.dropTable('support_chats');
    await queryRunner.dropTable('medical_records');
    await queryRunner.dropTable('consultations');
    await queryRunner.dropTable('users');
  }
}

