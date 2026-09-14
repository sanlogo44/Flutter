/// Generates the security middleware files:
/// - error-handler.ts
/// - security.ts (Helmet config, CORS)
/// - rate-limit.ts (express-rate-limit)
/// - request-validation.ts (Zod-based request body validation)
library;

import 'backend_config.dart';

class MiddlewareGenerator {
  MiddlewareGenerator();

  String errorHandler() => '''import { Request, Response, NextFunction } from 'express';
import { ZodError } from 'zod';
import { logger } from '../utils/logger';

export class ApiError extends Error {
  constructor(
    public statusCode: number,
    public message: string,
    public details?: unknown,
  ) {
    super(message);
    this.name = 'ApiError';
  }
}

export function errorHandler(
  err: Error,
  _req: Request,
  res: Response,
  _next: NextFunction,
): void {
  logger.error(\`Error: \${err.message}\`, { stack: err.stack });

  if (err instanceof ApiError) {
    res.status(err.statusCode).json({
      error: err.message,
      details: err.details,
    });
    return;
  }

  if (err instanceof ZodError) {
    res.status(400).json({
      error: 'Validation failed',
      details: err.flatten(),
    });
    return;
  }

  // Avoid leaking internal errors in production
  const message = process.env.NODE_ENV === 'production'
    ? 'Internal server error'
    : err.message;

  res.status(500).json({ error: message });
}

export function notFoundHandler(_req: Request, res: Response): void {
  res.status(404).json({ error: 'Resource not found' });
}
''';

  String security() => '''import { Request, Response, NextFunction } from 'express';

export function securityMiddleware(_req: Request, res: Response, next: NextFunction): void {
  // Additional security headers
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('X-Frame-Options', 'DENY');
  res.setHeader('X-XSS-Protection', '1; mode=block');
  res.setHeader('Referrer-Policy', 'strict-origin-when-cross-origin');
  res.setHeader('Permissions-Policy', 'geolocation=(), microphone=(), camera=()');
  next();
}
''';

  String rateLimit() => '''import rateLimit from 'express-rate-limit';
import { env } from '../config/env';

export const apiRateLimiter = rateLimit({
  windowMs: env.RATE_LIMIT_WINDOW_MS,
  max: env.RATE_LIMIT_MAX,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    error: 'Too many requests, please try again later.',
  },
});

export const authRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 10, // 10 auth attempts per window
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    error: 'Too many authentication attempts, please try again later.',
  },
});
''';

  String requestValidation() => '''import { Request, Response, NextFunction } from 'express';
import { ZodSchema } from 'zod';

export function validateBody(schema: ZodSchema) {
  return (req: Request, res: Response, next: NextFunction) => {
    const result = schema.safeParse(req.body);
    if (!result.success) {
      res.status(400).json({
        error: 'Validation failed',
        details: result.error.flatten(),
      });
      return;
    }
    req.body = result.data;
    next();
  };
}

export function validateQuery(schema: ZodSchema) {
  return (req: Request, res: Response, next: NextFunction) => {
    const result = schema.safeParse(req.query);
    if (!result.success) {
      res.status(400).json({
        error: 'Query validation failed',
        details: result.error.flatten(),
      });
      return;
    }
    req.query = result.data;
    next();
  };
}

export function validateParams(schema: ZodSchema) {
  return (req: Request, res: Response, next: NextFunction) => {
    const result = schema.safeParse(req.params);
    if (!result.success) {
      res.status(400).json({
        error: 'Parameter validation failed',
        details: result.error.flatten(),
      });
      return;
    }
    req.params = result.data;
    next();
  };
}
''';

  String authMiddleware() {
    final b = StringBuffer();
    b.writeln("import { Request, Response, NextFunction } from 'express';");
    b.writeln("import { verifyAccessToken } from '../auth/token.service';");
    b.writeln();
    b.writeln('export interface AuthenticatedRequest extends Request {');
    b.writeln('  user?: {');
    b.writeln('    id: string;');
    b.writeln('    email: string;');
    b.writeln('  };');
    b.writeln('}');
    b.writeln();
    b.writeln('export function requireAuth(req: AuthenticatedRequest, res: Response, next: NextFunction): void {');
    b.writeln("  const authHeader = req.headers.authorization;");
    b.writeln("  if (!authHeader || !authHeader.startsWith('Bearer ')) {");
    b.writeln("    res.status(401).json({ error: 'Authentication required' });");
    b.writeln('    return;');
    b.writeln('  }');
    b.writeln();
    b.writeln('  const token = authHeader.substring(7);');
    b.writeln('  try {');
    b.writeln('    const payload = verifyAccessToken(token);');
    b.writeln('    if (!payload) {');
    b.writeln("      res.status(401).json({ error: 'Invalid or expired token' });");
    b.writeln('      return;');
    b.writeln('    }');
    b.writeln('    req.user = {');
    b.writeln('      id: payload.sub,');
    b.writeln('      email: payload.email,');
    b.writeln('    };');
    b.writeln('    next();');
    b.writeln('  } catch {');
    b.writeln("    res.status(401).json({ error: 'Invalid or expired token' });");
    b.writeln('  }');
    b.writeln('}');
    return b.toString();
  }
}