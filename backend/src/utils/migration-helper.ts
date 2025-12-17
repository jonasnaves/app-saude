/**
 * Helper functions para migrações
 * Use estas funções para operações comuns em migrações
 */

import { QueryRunner, TableColumn, TableIndex, TableForeignKey } from 'typeorm';

export class MigrationHelper {
  /**
   * Adiciona coluna com verificação se já existe
   */
  static async addColumnIfNotExists(
    queryRunner: QueryRunner,
    tableName: string,
    column: TableColumn
  ): Promise<void> {
    const table = await queryRunner.getTable(tableName);
    const columnExists = table?.findColumnByName(column.name);

    if (!columnExists) {
      await queryRunner.addColumn(tableName, column);
    }
  }

  /**
   * Remove coluna se existir
   */
  static async dropColumnIfExists(
    queryRunner: QueryRunner,
    tableName: string,
    columnName: string
  ): Promise<void> {
    const table = await queryRunner.getTable(tableName);
    const columnExists = table?.findColumnByName(columnName);

    if (columnExists) {
      await queryRunner.dropColumn(tableName, columnName);
    }
  }

  /**
   * Cria índice se não existir
   */
  static async createIndexIfNotExists(
    queryRunner: QueryRunner,
    tableName: string,
    index: TableIndex
  ): Promise<void> {
    const table = await queryRunner.getTable(tableName);
    const indexExists = table?.indices.find(
      (idx) => idx.name === index.name
    );

    if (!indexExists) {
      await queryRunner.createIndex(tableName, index);
    }
  }

  /**
   * Remove índice se existir
   */
  static async dropIndexIfExists(
    queryRunner: QueryRunner,
    tableName: string,
    indexName: string
  ): Promise<void> {
    const table = await queryRunner.getTable(tableName);
    const indexExists = table?.indices.find(
      (idx) => idx.name === indexName
    );

    if (indexExists) {
      await queryRunner.dropIndex(tableName, indexName);
    }
  }

  /**
   * Cria foreign key se não existir
   */
  static async createForeignKeyIfNotExists(
    queryRunner: QueryRunner,
    tableName: string,
    foreignKey: TableForeignKey
  ): Promise<void> {
    const table = await queryRunner.getTable(tableName);
    const fkExists = table?.foreignKeys.find(
      (fk) => fk.name === foreignKey.name
    );

    if (!fkExists) {
      await queryRunner.createForeignKey(tableName, foreignKey);
    }
  }

  /**
   * Remove foreign key se existir
   */
  static async dropForeignKeyIfExists(
    queryRunner: QueryRunner,
    tableName: string,
    foreignKeyName: string
  ): Promise<void> {
    const table = await queryRunner.getTable(tableName);
    const fkExists = table?.foreignKeys.find(
      (fk) => fk.name === foreignKeyName
    );

    if (fkExists) {
      await queryRunner.dropForeignKey(tableName, foreignKeyName);
    }
  }
}

