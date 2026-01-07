import { Request, Response } from 'express';
import { DashboardDBService } from '../services/dashboard-db.service';

const dashboardDB = new DashboardDBService();

/**
 * GET /api/dashboard/stats
 * Retorna estatísticas do dashboard
 */
export const getDashboardStats = async (req: Request, res: Response) => {
  try {
    const userId = req.userId; // Do middleware de autenticação

    console.log('[DashboardController] getDashboardStats chamado:', { userId });

    const stats = await dashboardDB.getDashboardStats(userId);

    console.log('[DashboardController] Estatísticas obtidas:', {
      totalPatients: stats.totalPatients,
      consultationsToday: stats.consultationsToday,
      pendingConsultations: stats.pendingConsultations,
      totalConsultations: stats.totalConsultations,
      consultationsByDayCount: stats.consultationsByDay.length,
      recentConsultationsCount: stats.recentConsultations.length,
    });

    res.json(stats);
  } catch (error: any) {
    console.error('[DashboardController] Erro ao obter estatísticas:', {
      error: error.message,
      stack: error.stack,
    });
    res.status(500).json({
      error: 'Erro ao obter estatísticas do dashboard',
      message: error.message,
    });
  }
};

