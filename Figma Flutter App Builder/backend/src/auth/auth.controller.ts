import { Request, Response, NextFunction } from 'express';
import { prisma } from '../database/prisma';
import { verifyAccessToken, generateRefreshToken, issueTokens } from './token.service';
import { createSession, validateSession, rotateSession, revokeSession, revokeAllUserSessions } from './session.service';
import { validatePassword, hashPassword, verifyPassword } from './password.service';
import { createVerificationToken, verifyEmail } from './email-verification.service';
import { createPasswordResetToken, resetPassword } from './password-reset.service';
import { checkDisposableEmail } from './disposable-email.service';
import { ApiError } from '../middleware/error-handler';
import { env } from '../config/env';

// Auth middleware: validates JWT access token
export function requireAuth(req: Request, _res: Response, next: NextFunction): void {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    throw new ApiError(401, 'Missing or invalid authorization header');
  }

  const token = authHeader.substring(7);
  const payload = verifyAccessToken(token);
  if (!payload) {
    throw new ApiError(401, 'Invalid or expired access token');
  }

  (req as any).userId = payload.sub;
  next();
}

// Register
export async function registerController(req: Request, res: Response): Promise<void> {
  const { email, password, displayName } = req.body;

  // Check disposable email
  const isDisposable = await checkDisposableEmail(email);
  if (isDisposable) {
    throw new ApiError(400, 'Disposable email addresses are not allowed');
  }

  // Validate password
  const validation = validatePassword(password);
  if (!validation.valid) {
    throw new ApiError(400, validation.message);
  }

  // Check existing user
  const existing = await prisma.user.findUnique({ where: { email } });
  if (existing) {
    throw new ApiError(409, 'An account with this email already exists');
  }

  const passwordHash = await hashPassword(password);

  const user = await prisma.$transaction(async (tx) => {
    const newUser = await tx.user.create({
      data: { email, displayName: displayName || null },
    });

    await tx.authAccount.create({
      data: {
        userId: newUser.id,
        provider: 'email-password',
        providerAccountId: email,
        passwordHash,
        passwordChangedAt: new Date(),
      },
    });

    return newUser;
  });

  const tokens = issueTokens(user.id, user.email);
  await createSession(user.id, tokens.refreshToken, req);

  await createVerificationToken(user.id, email);

  res.status(201).json({
    user: { id: user.id, email: user.email, displayName: user.displayName },
    ...tokens,
  });
}

// Login
export async function loginController(req: Request, res: Response): Promise<void> {
  const { email, password } = req.body;

  const account = await prisma.authAccount.findFirst({
    where: { provider: 'email-password', providerAccountId: email },
    include: { user: true },
  });

  if (!account || !account.passwordHash) {
    throw new ApiError(401, 'Invalid email or password');
  }

  const valid = await verifyPassword(password, account.passwordHash);
  if (!valid) {
    throw new ApiError(401, 'Invalid email or password');
  }

  const tokens = issueTokens(account.user.id, account.user.email);
  await createSession(account.user.id, tokens.refreshToken, req);

  res.json({
    user: {
      id: account.user.id,
      email: account.user.email,
      displayName: account.user.displayName,
    },
    ...tokens,
  });
}

// Refresh
export async function refreshController(req: Request, res: Response): Promise<void> {
  const { refreshToken } = req.body;

    const newRefreshToken = generateRefreshToken();
  const userId = await rotateSession(refreshToken, newRefreshToken);
  if (!userId) {
    throw new ApiError(401, 'Invalid or expired refresh token');
  }

  const user = await prisma.user.findUnique({ where: { id: userId } });
  if (!user) {
    throw new ApiError(401, 'Invalid or expired refresh token');
  }

  const tokens = issueTokens(userId, user.email);
  await createSession(userId, newRefreshToken, req);

  res.json({
    accessToken: tokens.accessToken,
    refreshToken: newRefreshToken,
    expiresIn: tokens.expiresIn,
  });

}

// Logout
export async function logoutController(req: Request, res: Response): Promise<void> {
  const { refreshToken } = req.body;
  await revokeSession(refreshToken);
  res.json({ success: true });
}

// Logout from all devices
export async function logoutAllController(req: Request, res: Response): Promise<void> {
  const userId = (req as any).userId;
  await revokeAllUserSessions(userId);
  res.json({ success: true });
}

// Verify email
export async function verifyEmailController(req: Request, res: Response): Promise<void> {
  const { token } = req.body;
  const success = await verifyEmail(token);
  if (!success) {
    throw new ApiError(400, 'Invalid or expired verification token');
  }
  res.json({ success: true });
}


// Forgot password
export async function forgotPasswordController(req: Request, res: Response): Promise<void> {
  const { email } = req.body;

  const user = await prisma.user.findUnique({ where: { email } });
  if (!user) {
    // Return success to prevent account enumeration
    res.json({ success: true });
    return;
  }

  await createPasswordResetToken(user.id);
  res.json({ success: true });
}

// Reset password
export async function resetPasswordController(req: Request, res: Response): Promise<void> {
  const { token, newPassword } = req.body;
  const success = await resetPassword(token, newPassword);
  if (!success) {
    throw new ApiError(400, 'Invalid or expired reset token');
  }
  res.json({ success: true });
}

// Change password (authenticated)
export async function changePasswordController(req: Request, res: Response): Promise<void> {
  const userId = (req as any).userId;
  const { currentPassword, newPassword } = req.body;

  const account = await prisma.authAccount.findFirst({
    where: { userId, provider: 'email-password' },
  });

  if (!account || !account.passwordHash) {
    throw new ApiError(404, 'No password account found');
  }

  const valid = await verifyPassword(currentPassword, account.passwordHash);
  if (!valid) {
    throw new ApiError(401, 'Current password is incorrect');
  }

  const validation = validatePassword(newPassword);
  if (!validation.valid) {
    throw new ApiError(400, validation.message);
  }

  const passwordHash = await hashPassword(newPassword);
  await prisma.authAccount.update({
    where: { id: account.id },
    data: { passwordHash, passwordChangedAt: new Date() },
  });

  // Revoke all sessions
  await revokeAllUserSessions(userId);

  res.json({ success: true });
}

// Get current user
export async function meController(req: Request, res: Response): Promise<void> {
  const userId = (req as any).userId;
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { id: true, email: true, displayName: true, avatarUrl: true, emailVerified: true, createdAt: true },
  });

  if (!user) {
    throw new ApiError(404, 'User not found');
  }

  res.json({ user });
}
