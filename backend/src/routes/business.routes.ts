import { Router } from 'express';
import { authMiddleware } from '../middleware/auth.middleware';
import {
  getCredits,
  getDrugs,
  checkout,
  getTransactions,
} from '../controllers/business.controller';

const router = Router();

router.get('/drugs', getDrugs);
router.use(authMiddleware);
router.get('/credits', getCredits);
router.post('/checkout', checkout);
router.get('/transactions', getTransactions);

export default router;

