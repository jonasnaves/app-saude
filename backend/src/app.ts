import 'reflect-metadata';
import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { createServer } from 'http';
import { WebSocketServer } from 'ws';
import { AppDataSource } from './config/database';
import { errorMiddleware } from './middleware/error.middleware';
import { metricsMiddleware } from './middleware/metrics.middleware';
import { performanceMiddleware } from './middleware/performance.middleware';
import { analyticsMiddleware } from './middleware/analytics.middleware';
import { defaultRateLimit } from './middleware/rate-limit.middleware';
import authRoutes from './routes/auth.routes';
import clinicalRoutes from './routes/clinical.routes';
import supportRoutes from './routes/support.routes';
import businessRoutes from './routes/business.routes';
import dashboardRoutes from './routes/dashboard.routes';
import metricsRoutes from './routes/metrics.routes';
import analyticsRoutes from './routes/analytics.routes';
import performanceRoutes from './routes/performance.routes';
import notificationsRoutes from './routes/notifications.routes';
import { setupWebSocket } from './services/websocket.service';

dotenv.config();

const app = express();
const server = createServer(app);
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json({ limit: '50mb' })); // Aumentar limite para chunks de áudio
app.use(express.urlencoded({ extended: true, limit: '50mb' }));
app.use(defaultRateLimit); // Rate limiting
app.use(metricsMiddleware); // Métricas
app.use(performanceMiddleware); // Performance monitoring
app.use(analyticsMiddleware); // Analytics

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/clinical', clinicalRoutes);
app.use('/api/support', supportRoutes);
app.use('/api/business', businessRoutes);
app.use('/api/dashboard', dashboardRoutes);
app.use('/api/metrics', metricsRoutes);
app.use('/api/analytics', analyticsRoutes);
app.use('/api/performance', performanceRoutes);
app.use('/api/notifications', notificationsRoutes);

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

// Error middleware
app.use(errorMiddleware);

// Initialize database and start server
AppDataSource.initialize()
  .then(() => {
    console.log('Database connected');
    
    // Setup WebSocket server
    setupWebSocket(server);
    
    server.listen(PORT, () => {
      console.log(`Server running on port ${PORT}`);
      console.log(`WebSocket server ready`);
    });
  })
  .catch((error) => {
    console.error('Error initializing database:', error);
    process.exit(1);
  });

export default app;

