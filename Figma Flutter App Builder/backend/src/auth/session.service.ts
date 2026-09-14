import { prisma } from '../database/prisma';
import { env } from '../config/env';
import { hashToken } from './token.service';
import type { Request } from 'express';

export async function createSession(
  userId: string,
  refreshToken: string,
  req: Request,
): Promise<void> {
  const refreshHash = hashToken(refreshToken);
  const expiresAt = new Date();
  const days = parseInt(env.REFRESH_TOKEN_EXPIRES_IN.match(/\d+/)?.[0] || '7', 10);
  expiresAt.setDate(expiresAt.getDate() + days);

  await prisma.session.create({
    data: {
      userId,
      refreshTokenHash: refreshHash,
      userAgent: req.get('User-Agent') || null,
      ipAddress: req.ip || null,
      expiresAt,
    },
  });
}

export async function validateSession(refreshToken: string): Promise<string | null> {
  const refreshHash = hashToken(refreshToken);
  const session = await prisma.session.findUnique({
    where: { refreshTokenHash: refreshHash },
  });

  if (!session) return null;
  if (session.revokedAt) return null;
  if (session.expiresAt < new Date()) return null;

  return session.userId;
}

export async function rotateSession(
  oldRefreshToken: string,
  newRefreshToken: string,
): Promise<string | null> {
  const oldHash = hashToken(oldRefreshToken);
  const newHash = hashToken(newRefreshToken);

  // Find and validate the old session
  const session = await prisma.session.findUnique({
    where: { refreshTokenHash: oldHash },
  });

  if (!session || session.revokedAt || session.expiresAt < new Date()) {
    return null;
  }

  // Revoke old session and create new one
  await prisma.$transaction(async (tx) => {
    await tx.session.update({
      where: { id: session.id },
      data: { revokedAt: new Date() },
    });

    const expiresAt = new Date();
    const days = parseInt(env.REFRESH_TOKEN_EXPIRES_IN.match(/\d+/)?.[0] || '7', 10);
    expiresAt.setDate(expiresAt.getDate() + days);

    await tx.session.create({
      data: {
        userId: session.userId,
        refreshTokenHash: newHash,
        userAgent: session.userAgent,
        ipAddress: session.ipAddress,
        rotatedFrom: oldHash,
        expiresAt,
      },
    });
  });

  return session.userId;
}


export async function revokeSession(refreshToken: string): Promise<void> {
  const refreshHash = hashToken(refreshToken);
  await prisma.session.updateMany({
    where: { refreshTokenHash: refreshHash },
    data: { revokedAt: new Date() },
  });
}

export async function revokeAllUserSessions(userId: string): Promise<void> {
  await prisma.session.updateMany({
    where: { userId },
    data: { revokedAt: new Date() },
  });
}

export async function cleanupExpiredSessions(): Promise<number> {
  const result = await prisma.session.deleteMany({
    where: { expiresAt: { lt: new Date() } },
  });
  return result.count;
}
