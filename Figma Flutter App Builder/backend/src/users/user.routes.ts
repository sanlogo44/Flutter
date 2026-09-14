import { Router } from 'express';
import { requireAuth } from '../middleware/auth';
import { getUserController, updateUserController } from './user.controller';
import { validateBody } from '../middleware/request-validation';
import { updateUserSchema } from './user.schemas';

export const userRoutes = Router();

userRoutes.get('/me', requireAuth, getUserController);
userRoutes.put('/me', requireAuth, validateBody(updateUserSchema), updateUserController);
