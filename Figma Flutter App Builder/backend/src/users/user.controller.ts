import { Request, Response } from 'express';
import { prisma } from '../database/prisma';
import { ApiError } from '../middleware/error-handler';

export async function getUserController(req: Request, res: Response): Promise<void> {
  const userId = (req as any).user?.id;
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: {
      id: true,
      email: true,
      displayName: true,
      avatarUrl: true,
      emailVerified: true,
      createdAt: true,
      updatedAt: true,
    },
  });

  if (!user) {
    throw new ApiError(404, 'User not found');
  }

  res.json({ user });
}

export async function updateUserController(req: Request, res: Response): Promise<void> {
  const userId = (req as any).user?.id;
  const { displayName, avatarUrl } = req.body;

  const updated = await prisma.user.update({
    where: { id: userId },
    data: {
      ...(displayName !== undefined && { displayName }),
      ...(avatarUrl !== undefined && { avatarUrl }),
    },
    select: {
      id: true,
      email: true,
      displayName: true,
      avatarUrl: true,
      updatedAt: true,
    },
  });

  res.json({ user: updated });
}
