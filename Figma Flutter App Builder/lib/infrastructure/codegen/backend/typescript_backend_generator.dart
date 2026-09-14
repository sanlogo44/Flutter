/// Generates the core TypeScript backend files: main.ts, app.ts, config/env.ts,
/// database/prisma.ts.
library;

import 'backend_config.dart';

class TypeScriptBackendGenerator {
  TypeScriptBackendGenerator();

  String mainTs() {
    final b = StringBuffer();
    b.writeln("import 'dotenv/config';");
    b.writeln("import { app } from './app';");
    b.writeln("import { logger } from './utils/logger';");
    b.writeln();
    b.writeln('const PORT = process.env.PORT || 3000;');
    b.writeln();
    b.writeln('const server = app.listen(PORT, () => {');
    b.writeln('  logger.info(`Server running on port \${PORT}`);');
    b.writeln('});');
    b.writeln();
    b.writeln("process.on('SIGTERM', () => {");
    b.writeln("  logger.info('SIGTERM received, shutting down gracefully');");
    b.writeln('  server.close(() => {');
    b.writeln("    logger.info('Server closed');");
    b.writeln('    process.exit(0);');
    b.writeln('  });');
    b.writeln('});');
    b.writeln();
    b.writeln("process.on('SIGINT', () => {");
    b.writeln("  logger.info('SIGINT received, shutting down gracefully');");
    b.writeln('  server.close(() => {');
    b.writeln('    process.exit(0);');
    b.writeln('  });');
    b.writeln('});');
    return b.toString();
  }

  String appTs(BackendConfig config) {
    final routes = <String>[];

    if (config.hasAnyAuthProvider) {
      routes.add("app.use('/api/auth', authRoutes);");
    }
    routes.add("app.use('/api/users', userRoutes);");
    routes.add("app.use('/api/projects', projectRoutes);");
    routes.add("app.use('/api/health', healthRouter);");

    final b = StringBuffer();
    b.writeln("import express from 'express';");
    b.writeln("import cors from 'cors';");
    b.writeln("import helmet from 'helmet';");
    b.writeln("import morgan from 'morgan';");
    b.writeln("import { errorHandler } from './middleware/error-handler';");
    b.writeln("import { securityMiddleware } from './middleware/security';");
    if (config.enableRateLimiting) {
      b.writeln("import { apiRateLimiter } from './middleware/rate-limit';");
    }
    b.writeln("import { authRoutes } from './auth/auth.routes';");
    b.writeln("import { userRoutes } from './users/user.routes';");
    b.writeln("import { projectRoutes } from './projects/project.routes';");
    b.writeln("import { healthRouter } from './utils/health';");
    b.writeln();
    b.writeln('export const app = express();');
    b.writeln();
    b.writeln('// Security middleware');
    b.writeln('app.use(helmet());');
    b.writeln('app.use(cors({');
    b.writeln("  origin: process.env.CORS_ORIGIN || '*',");
    b.writeln('  credentials: true,');
    b.writeln('}));');
    b.writeln("app.use(express.json({ limit: '10mb' }));");
    b.writeln('app.use(express.urlencoded({ extended: true }));');
    b.writeln("app.use(morgan('combined'));");
    b.writeln();
    if (config.enableRateLimiting) {
      b.writeln("app.use('/api', apiRateLimiter);");
      b.writeln();
    }
    b.writeln('// Routes');
    for (final route in routes) {
      b.writeln(route);
    }
    b.writeln();
    b.writeln('// Error handling (must be last)');
    b.writeln('app.use(errorHandler);');
    return b.toString();
  }

  String envTs(BackendConfig config) {
    final b = StringBuffer();
    b.writeln("import { z } from 'zod';");
    b.writeln();
    b.writeln('const envSchema = z.object({');
    b.writeln('  DATABASE_URL: z.string().url(),');
    b.writeln("  JWT_SECRET: z.string().min(32, 'JWT_SECRET must be at least 32 characters'),");
    b.writeln("  JWT_EXPIRES_IN: z.string().default('15m'),");
    b.writeln("  REFRESH_TOKEN_EXPIRES_IN: z.string().default('7d'),");
    b.writeln('  PORT: z.coerce.number().default(3000),');
    b.writeln("  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),");
    b.writeln("  CORS_ORIGIN: z.string().default('*'),");
    if (config.enableRateLimiting) {
      b.writeln('  RATE_LIMIT_WINDOW_MS: z.coerce.number().default(900000),');
      b.writeln('  RATE_LIMIT_MAX: z.coerce.number().default(100),');
    }
    if (config.hasEmailPassword) {
      b.writeln('  PASSWORD_MIN_LENGTH: z.coerce.number().default(8),');
      b.writeln('  PASSWORD_REQUIRE_UPPERCASE: z.coerce.boolean().default(true),');
      b.writeln('  PASSWORD_REQUIRE_LOWERCASE: z.coerce.boolean().default(true),');
      b.writeln('  PASSWORD_REQUIRE_NUMBER: z.coerce.boolean().default(true),');
      b.writeln('  PASSWORD_REQUIRE_SPECIAL: z.coerce.boolean().default(true),');
    }
    if (config.enableDisposableEmailProtection) {
      b.writeln('  DISPOSABLE_EMAIL_BLOCKLIST_PATH: z.string().optional(),');
      b.writeln('  DISPOSABLE_EMAIL_ALLOWLIST_PATH: z.string().optional(),');
    }
    if (config.hasGoogle) {
      b.writeln('  GOOGLE_CLIENT_ID: z.string().optional(),');
      b.writeln('  GOOGLE_CLIENT_SECRET: z.string().optional(),');
      b.writeln('  GOOGLE_REDIRECT_URI: z.string().optional(),');
    }
    if (config.hasGithub) {
      b.writeln('  GITHUB_CLIENT_ID: z.string().optional(),');
      b.writeln('  GITHUB_CLIENT_SECRET: z.string().optional(),');
      b.writeln('  GITHUB_REDIRECT_URI: z.string().optional(),');
    }
    b.writeln('  SMTP_HOST: z.string().optional(),');
    b.writeln('  SMTP_PORT: z.coerce.number().optional(),');
    b.writeln('  SMTP_USER: z.string().optional(),');
    b.writeln('  SMTP_PASSWORD: z.string().optional(),');
    b.writeln('  FROM_EMAIL: z.string().optional(),');
    b.writeln('});');
    b.writeln();
    b.writeln('export type Env = z.infer<typeof envSchema>;');
    b.writeln();
    b.writeln('const parsed = envSchema.safeParse(process.env);');
    b.writeln();
    b.writeln('if (!parsed.success) {');
    b.writeln("  console.error('Invalid environment variables:', parsed.error.format());");
    b.writeln('  process.exit(1);');
    b.writeln('}');
    b.writeln();
    b.writeln('export const env = parsed.data;');
    return b.toString();
  }

  String prismaTs() {
    final dollar = '\$';
    final b = StringBuffer();
    b.writeln("import { PrismaClient } from '@prisma/client';");
    b.writeln();
    b.writeln('export const prisma = new PrismaClient({');
    b.writeln("  log: process.env.NODE_ENV === 'development' ? ['query', 'error', 'warn'] : ['error'],");
    b.writeln('});');
    b.writeln();
    b.writeln('export async function connectDatabase(): Promise<void> {');
    b.writeln('  try {');
    b.writeln('    await prisma.${dollar}queryRaw`SELECT 1`;');
    b.writeln("    console.log('Database connected successfully');");
    b.writeln('  } catch (error) {');
    b.writeln("    console.error('Database connection failed:', error);");
    b.writeln('    process.exit(1);');
    b.writeln('  }');
    b.writeln('}');
    b.writeln();
    b.writeln('export async function disconnectDatabase(): Promise<void> {');
    b.writeln('  await prisma.${dollar}disconnect();');
    b.writeln('}');
    return b.toString();
  }
}
