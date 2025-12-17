import { Request, Response } from 'express';
import { AppDataSource } from '../config/database';
import { Consultation } from '../models/Consultation';
import { authMiddleware, AuthRequest } from '../middleware/auth.middleware';

export const getStats = async (req: AuthRequest, res: Response) => {
  try {
    const consultationRepository = AppDataSource.getRepository(Consultation);
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const consultationsToday = await consultationRepository
      .createQueryBuilder('consultation')
      .where('consultation.userId = :userId', { userId: req.user!.id })
      .andWhere('consultation.startedAt >= :today', { today })
      .getCount();

    // Estatísticas mockadas - pode ser expandido com dados reais
    const stats = {
      patientsToday: consultationsToday,
      pending: 3,
      estimatedEarnings: 4200,
      shifts: 1,
    };

    res.json(stats);
  } catch (error) {
    res.status(500).json({ error: 'Erro ao buscar estatísticas' });
  }
};

export const getSchedule = async (req: AuthRequest, res: Response) => {
  try {
    // Mock data - pode ser expandido com sistema de agendamento real
    const schedule = [
      { id: '1', name: 'Ana Silva', lastVisit: '2024-05-10', nextAppointment: '14:30' },
      { id: '2', name: 'João Pereira', lastVisit: '2024-04-22', nextAppointment: '15:15' },
      { id: '3', name: 'Maria Santos', lastVisit: '2024-05-12', nextAppointment: '16:00' },
    ];

    res.json(schedule);
  } catch (error) {
    res.status(500).json({ error: 'Erro ao buscar agenda' });
  }
};

