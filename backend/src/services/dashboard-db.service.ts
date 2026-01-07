import pool from '../config/database';

export interface DashboardStats {
  totalPatients: number;
  consultationsToday: number;
  pendingConsultations: number; // Consultas não finalizadas
  totalConsultations: number;
  consultationsByDay: Array<{ day: string; count: number }>;
  recentConsultations: Array<{
    id: string;
    patientName: string | null;
    startedAt: string;
    endedAt: string | null;
  }>;
}

export class DashboardDBService {
  /**
   * Obtém estatísticas do dashboard
   */
  async getDashboardStats(userId?: string): Promise<DashboardStats> {
    try {
      // Total de pacientes
      const patientsResult = await pool.query('SELECT COUNT(*) FROM patients');
      const totalPatients = parseInt(patientsResult.rows[0]?.count || '0');

      // Consultas de hoje
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      const todayStart = today.toISOString();
      const todayEnd = new Date(today);
      todayEnd.setHours(23, 59, 59, 999);
      const todayEndStr = todayEnd.toISOString();

      const consultationsTodayResult = await pool.query(
        `SELECT COUNT(*) FROM consultations 
         WHERE started_at >= $1 AND started_at <= $2`,
        [todayStart, todayEndStr]
      );
      const consultationsToday = parseInt(consultationsTodayResult.rows[0]?.count || '0');

      // Consultas pendentes (não finalizadas)
      const pendingResult = await pool.query(
        'SELECT COUNT(*) FROM consultations WHERE ended_at IS NULL'
      );
      const pendingConsultations = parseInt(pendingResult.rows[0]?.count || '0');

      // Total de consultas
      const totalResult = await pool.query('SELECT COUNT(*) FROM consultations');
      const totalConsultations = parseInt(totalResult.rows[0]?.count || '0');

      // Consultas por dia da semana (últimos 7 dias)
      const sevenDaysAgo = new Date();
      sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
      sevenDaysAgo.setHours(0, 0, 0, 0);

      const consultationsByDayResult = await pool.query(
        `SELECT 
          TO_CHAR(started_at, 'Dy') as day,
          COUNT(*) as count
         FROM consultations 
         WHERE started_at >= $1
         GROUP BY TO_CHAR(started_at, 'Dy'), DATE_PART('dow', started_at)
         ORDER BY DATE_PART('dow', started_at)`,
        [sevenDaysAgo.toISOString()]
      );

      // Mapear dias da semana para português
      const dayMap: { [key: string]: string } = {
        'Mon': 'Seg',
        'Tue': 'Ter',
        'Wed': 'Qua',
        'Thu': 'Qui',
        'Fri': 'Sex',
        'Sat': 'Sáb',
        'Sun': 'Dom',
      };

      const consultationsByDay = consultationsByDayResult.rows.map((row: any) => ({
        day: dayMap[row.day] || row.day,
        count: parseInt(row.count || '0'),
      }));

      // Preencher dias faltantes com 0
      const allDays = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
      const dayCounts: { [key: string]: number } = {};
      consultationsByDay.forEach((item) => {
        dayCounts[item.day] = item.count;
      });

      const completeConsultationsByDay = allDays.map((day) => ({
        day,
        count: dayCounts[day] || 0,
      }));

      // Consultas recentes (últimas 5, ordenadas por data de início)
      const recentResult = await pool.query(
        `SELECT 
          id,
          patient_name,
          started_at,
          ended_at
         FROM consultations 
         ORDER BY started_at DESC 
         LIMIT 5`
      );

      const recentConsultations = recentResult.rows.map((row: any) => ({
        id: String(row.id),
        patientName: row.patient_name ? String(row.patient_name) : null,
        startedAt: new Date(row.started_at).toISOString(),
        endedAt: row.ended_at ? new Date(row.ended_at).toISOString() : null,
      }));

      return {
        totalPatients,
        consultationsToday,
        pendingConsultations,
        totalConsultations,
        consultationsByDay: completeConsultationsByDay,
        recentConsultations,
      };
    } catch (error: any) {
      console.error('[DashboardDB] Erro ao obter estatísticas:', {
        error: error.message,
        stack: error.stack,
      });
      throw new Error(`Falha ao obter estatísticas do dashboard: ${error.message}`);
    }
  }
}

