import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import { errorHandler } from './middleware/error-handler';
import { securityMiddleware } from './middleware/security';
import { apiRateLimiter } from './middleware/rate-limit';
import { authRoutes } from './auth/auth.routes';
import { userRoutes } from './users/user.routes';
import { projectRoutes } from './projects/project.routes';
import { healthRouter } from './utils/health';

export const app = express();

// Security middleware
app.use(helmet());
app.use(cors({
  origin: process.env.CORS_ORIGIN || '*',
  credentials: true,
}));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));
app.use(morgan('combined'));

app.use('/api', apiRateLimiter);

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/projects', projectRoutes);
app.use('/api/health', healthRouter);

// Error handling (must be last)
app.use(errorHandler);
