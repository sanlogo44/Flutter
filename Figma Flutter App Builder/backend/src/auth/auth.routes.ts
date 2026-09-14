import { Router } from 'express';
import { validateBody } from '../middleware/request-validation';
import { requireAuth } from '../middleware/auth';
import { authRateLimiter } from '../middleware/rate-limit';
import {
  registerSchema,
  loginSchema,
  refreshSchema,
  logoutSchema,
  verifyEmailSchema,
  forgotPasswordSchema,
  resetPasswordSchema,
  changePasswordSchema,
} from './auth.schemas';
import {
  registerController,
  loginController,
  refreshController,
  logoutController,
  logoutAllController,
  meController,
  verifyEmailController,
  forgotPasswordController,
  resetPasswordController,
  changePasswordController,
} from './auth.controller';

export const authRoutes = Router();

authRoutes.use(authRateLimiter);

  authRoutes.post('/register', validateBody(registerSchema), registerController);
  authRoutes.post('/login', validateBody(loginSchema), loginController);
  authRoutes.post('/refresh', validateBody(refreshSchema), refreshController);
  authRoutes.post('/logout', validateBody(logoutSchema), logoutController);
  authRoutes.post('/logout-all', requireAuth, logoutAllController);
  authRoutes.get('/me', requireAuth, meController);
  authRoutes.post('/verify-email', validateBody(verifyEmailSchema), verifyEmailController);
  authRoutes.post('/forgot-password', validateBody(forgotPasswordSchema), forgotPasswordController);
  authRoutes.post('/reset-password', validateBody(resetPasswordSchema), resetPasswordController);
  authRoutes.post('/change-password', requireAuth, validateBody(changePasswordSchema), changePasswordController);
