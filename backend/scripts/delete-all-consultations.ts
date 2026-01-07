import pool from '../src/config/database';

async function deleteAllConsultations() {
  try {
    console.log('🔍 Verificando quantas consultas existem...');
    const countResult = await pool.query('SELECT COUNT(*) as total FROM consultations');
    const totalBefore = parseInt(countResult.rows[0].total);
    console.log(`📊 Total de consultas encontradas: ${totalBefore}`);

    if (totalBefore === 0) {
      console.log('✅ Não há consultas para excluir.');
      await pool.end();
      return;
    }

    console.log('🗑️  Excluindo todas as consultas...');
    const deleteResult = await pool.query('DELETE FROM consultations');
    console.log(`✅ ${deleteResult.rowCount} consulta(s) excluída(s) com sucesso!`);

    // Verificar novamente
    const countAfterResult = await pool.query('SELECT COUNT(*) as total FROM consultations');
    const totalAfter = parseInt(countAfterResult.rows[0].total);
    console.log(`📊 Total de consultas restantes: ${totalAfter}`);

    if (totalAfter === 0) {
      console.log('✅ Todas as consultas foram excluídas com sucesso!');
    } else {
      console.log('⚠️  Ainda existem consultas no banco.');
    }

    await pool.end();
    process.exit(0);
  } catch (error: any) {
    console.error('❌ Erro ao excluir consultas:', error.message);
    console.error(error);
    await pool.end();
    process.exit(1);
  }
}

deleteAllConsultations();
