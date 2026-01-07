import express from 'express';
import cors from 'cors';
import cookieParser from 'cookie-parser';
import path from 'path';
import clinicalRoutes from './routes/clinical.routes';
import patientRoutes from './routes/patient.routes';
import authRoutes from './routes/auth.routes';
import supportRoutes from './routes/support.routes';
import dashboardRoutes from './routes/dashboard.routes';

const app = express();

// Middlewares
app.use(cors({
  origin: (origin, callback) => {
    // Permitir todas as origens localhost em desenvolvimento
    if (!origin || origin.startsWith('http://localhost:') || origin.startsWith('http://127.0.0.1:')) {
      callback(null, true);
    } else {
      callback(new Error('Not allowed by CORS'));
    }
  },
  credentials: true, // Permitir cookies
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));
app.use(cookieParser());
app.use(express.json({ limit: '50mb' })); // Aumentar limite para chunks de áudio
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

// Servir arquivos estáticos de uploads
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

// Rotas
app.use('/api/auth', authRoutes);
app.use('/api/clinical', clinicalRoutes);
app.use('/api/patients', patientRoutes);
app.use('/api/support', supportRoutes);
app.use('/api/dashboard', dashboardRoutes);

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

// Error handler
app.use(
  (
    err: any,
    req: express.Request,
    res: express.Response,
    next: express.NextFunction
  ) => {
    console.error('Erro não tratado:', err);
    res.status(500).json({
      error: 'Erro interno do servidor',
      message: err.message,
    });
  }
);

export default app;

