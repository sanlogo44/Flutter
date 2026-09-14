import { prisma } from '../database/prisma';
import { generateToken } from './password.service';

export async function createVerificationToken(
  userId: string,
  email: string,
): Promise<string> {
  // Invalidate previous tokens
  await prisma.verificationToken.updateMany({
    where: { userId, type: 'email_verification', usedAt: null },
    data: { usedAt: new Date() },
  });

  const token = generateToken(32);
  const expiresAt = new Date();
  expiresAt.setHours(expiresAt.getHours() + 24);

  await prisma.verificationToken.create({
    data: {
      userId,
      token,
      type: 'email_verification',
      identifier: email,
      expiresAt,
    },
  });

  // In a real implementation, send the verification email here via SMTP.
  // For now, return the token (in dev mode) or send via email service.
  if (process.env.NODE_ENV === 'development') {
    console.log(`[DEV] Email verification token for ${email}: ${token}`);
  }

  return token;
}

export async function verifyEmail(token: string): Promise<boolean> {
  const verification = await prisma.verificationToken.findUnique({
    where: { token },
  });

  if (!verification || verification.usedAt || verification.expiresAt < new Date()) {
    return false;
  }

  if (verification.type !== 'email_verification') {
    return false;
  }

  await prisma.$transaction(async (tx) => {
    await tx.verificationToken.update({
      where: { id: verification.id },
      data: { usedAt: new Date() },
    });

    await tx.user.update({
      where: { id: verification.userId },
      data: { emailVerified: new Date() },
    });
  });

  return true;
}
