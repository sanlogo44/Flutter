import { prisma } from '../database/prisma';
import { generateToken, hashPassword } from './password.service';
import { validatePassword } from './password.service';
import { env } from '../config/env';

export async function createPasswordResetToken(
  userId: string,
): Promise<string> {
  // Invalidate previous tokens
  await prisma.passwordResetToken.updateMany({
    where: { userId, usedAt: null },
    data: { usedAt: new Date() },
  });

  const token = generateToken(32);
  const expiresAt = new Date();
  expiresAt.setHours(expiresAt.getHours() + 1); // 1 hour expiry

  await prisma.passwordResetToken.create({
    data: {
      userId,
      token,
      expiresAt,
    },
  });

  if (process.env.NODE_ENV === 'development') {
    console.log(`[DEV] Password reset token for user ${userId}: ${token}`);
  }

  return token;
}

export async function resetPassword(
  token: string,
  newPassword: string,
): Promise<boolean> {
  const resetToken = await prisma.passwordResetToken.findUnique({
    where: { token },
  });

  if (!resetToken || resetToken.usedAt || resetToken.expiresAt < new Date()) {
    return false;
  }

  // Validate new password
  const validation = validatePassword(newPassword);
  if (!validation.valid) {
    throw new Error(validation.message);
  }

  const passwordHash = await hashPassword(newPassword);

  await prisma.$transaction(async (tx) => {
    await tx.passwordResetToken.update({
      where: { id: resetToken.id },
      data: { usedAt: new Date() },
    });

    await tx.authAccount.updateMany({
      where: { userId: resetToken.userId, provider: 'email-password' },
      data: {
        passwordHash,
        passwordChangedAt: new Date(),
      },
    });
  });

  // Revoke all sessions for this user (security best practice)
  await prisma.session.updateMany({
    where: { userId: resetToken.userId },
    data: { revokedAt: new Date() },
  });

  return true;
}
