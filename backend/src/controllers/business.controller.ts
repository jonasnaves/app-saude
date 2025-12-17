import { Request, Response } from 'express';
import { AppDataSource } from '../config/database';
import { Drug } from '../models/Drug';
import { Transaction, TransactionType } from '../models/Transaction';
import { User } from '../models/User';
import { authMiddleware, AuthRequest } from '../middleware/auth.middleware';
import { In } from 'typeorm';
import { z } from 'zod';

export const getCredits = async (req: AuthRequest, res: Response) => {
  try {
    const userRepository = AppDataSource.getRepository(User);
    const user = await userRepository.findOne({ where: { id: req.user!.id } });

    res.json({ credits: user?.credits || 0 });
  } catch (error) {
    res.status(500).json({ error: 'Erro ao buscar créditos' });
  }
};

export const getDrugs = async (req: Request, res: Response) => {
  try {
    const { search } = req.query;
    const drugRepository = AppDataSource.getRepository(Drug);

    const queryBuilder = drugRepository.createQueryBuilder('drug');

    if (search) {
      queryBuilder.where(
        '(LOWER(drug.name) LIKE LOWER(:search) OR LOWER(drug.category) LIKE LOWER(:search))',
        { search: `%${search}%` }
      );
    }

    const drugs = await queryBuilder.getMany();
    res.json(drugs);
  } catch (error) {
    res.status(500).json({ error: 'Erro ao buscar medicamentos' });
  }
};

export const checkout = async (req: AuthRequest, res: Response) => {
  try {
    const { drugIds } = req.body;

    if (!Array.isArray(drugIds) || drugIds.length === 0) {
      return res.status(400).json({ error: 'Lista de medicamentos inválida' });
    }

    const drugRepository = AppDataSource.getRepository(Drug);
    const userRepository = AppDataSource.getRepository(User);
    const transactionRepository = AppDataSource.getRepository(Transaction);

    const drugs = await drugRepository.find({
      where: { id: In(drugIds) },
    });
    const totalAmount = drugs.reduce((sum, drug) => sum + (drug.price || 0), 0);

    const user = await userRepository.findOne({ where: { id: req.user!.id } });
    if (!user) {
      return res.status(404).json({ error: 'Usuário não encontrado' });
    }

    if (user.credits < totalAmount) {
      return res.status(400).json({ error: 'Créditos insuficientes' });
    }

    // Criar transação
    const transaction = transactionRepository.create({
      userId: user.id,
      type: TransactionType.DEBIT,
      amount: totalAmount,
      description: `Compra de ${drugs.length} medicamento(s)`,
    });

    await transactionRepository.save(transaction);

    // Atualizar créditos
    user.credits -= totalAmount;
    await userRepository.save(user);

    res.json({
      success: true,
      transactionId: transaction.id,
      remainingCredits: user.credits,
    });
  } catch (error) {
    res.status(500).json({ error: 'Erro ao processar checkout' });
  }
};

export const getTransactions = async (req: AuthRequest, res: Response) => {
  try {
    const transactionRepository = AppDataSource.getRepository(Transaction);
    const transactions = await transactionRepository.find({
      where: { userId: req.user!.id },
      order: { createdAt: 'DESC' },
    });

    res.json(transactions);
  } catch (error) {
    res.status(500).json({ error: 'Erro ao buscar transações' });
  }
};

