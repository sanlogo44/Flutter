/// Generates all auth service files:
/// - password.service.ts (argon2 hashing + password validation)
/// - token.service.ts (JWT access + refresh tokens)
/// - session.service.ts (DB-backed sessions with rotation)
/// - email-verification.service.ts
/// - password-reset.service.ts
/// - disposable-email.service.ts
library;

import 'backend_config.dart';

class AuthServicesGenerator {
  AuthServicesGenerator();

  String passwordService() => '''import argon2 from 'argon2';
import crypto from 'crypto';
import { env } from '../config/env';

export async function hashPassword(password: string): Promise<string> {
  return argon2.hash(password, {
    type: argon2.argon2id,
    memoryCost: 65536, // 64 MB
    timeCost: 3,
    parallelism: 4,
  });
}

export async function verifyPassword(password: string, hash: string): Promise<boolean> {
  try {
    return await argon2.verify(hash, password);
  } catch {
    return false;
  }
}

export interface PasswordValidationResult {
  valid: boolean;
  message: string;
}

export function validatePassword(password: string): PasswordValidationResult {
  if (password.length < env.PASSWORD_MIN_LENGTH) {
    return { valid: false, message: `Password must be at least \${env.PASSWORD_MIN_LENGTH} characters long` };
  }

  if (env.PASSWORD_REQUIRE_UPPERCASE && !/[A-Z]/.test(password)) {
    return { valid: false, message: 'Password must contain at least one uppercase letter' };
  }

  if (env.PASSWORD_REQUIRE_LOWERCASE && !/[a-z]/.test(password)) {
    return { valid: false, message: 'Password must contain at least one lowercase letter' };
  }

  if (env.PASSWORD_REQUIRE_NUMBER && !/\\d/.test(password)) {
    return { valid: false, message: 'Password must contain at least one number' };
  }

  if (env.PASSWORD_REQUIRE_SPECIAL && !/[!@#\$%^&*()_+\\-=\\[\\]{};':"\\\\|,.<>\\/?]/.test(password)) {
    return { valid: false, message: 'Password must contain at least one special character' };
  }

  return { valid: true, message: 'Password is valid' };
}

export function generateToken(length: number = 32): string {
  return crypto.randomBytes(length).toString('hex');
}
''';

  String tokenService(BackendConfig config) => '''import jwt from 'jsonwebtoken';
import crypto from 'crypto';
import { env } from '../config/env';

export interface TokenPair {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
}

export function issueTokens(userId: string, email: string): TokenPair {
  const accessToken = jwt.sign(
    { sub: userId, email, type: 'access' },
    env.JWT_SECRET,
    { expiresIn: env.JWT_EXPIRES_IN as unknown as never },
  );

  const refreshToken = generateRefreshToken();

  return {
    accessToken,
    refreshToken,
    expiresIn: getExpiresInSeconds(env.JWT_EXPIRES_IN as string),
  };
}

export function verifyAccessToken(token: string): { sub: string; email: string } | null {
  try {
    const payload = jwt.verify(token, env.JWT_SECRET) as { sub: string; email: string; type: string };
    if (payload.type !== 'access') return null;
    return { sub: payload.sub, email: payload.email };
  } catch {
    return null;
  }
}

export function generateRefreshToken(): string {
  return crypto.randomBytes(48).toString('hex');
}

export function hashToken(token: string): string {
  return crypto.createHash('sha256').update(token).digest('hex');
}

function getExpiresInSeconds(expiresIn: string): number {
  const match = expiresIn.match(/^(\\d+)(s|m|h|d)\$/);
  if (!match) return 900; // default 15 min
  const num = parseInt(match[1], 10);
  const unit = match[2];
  const multipliers: Record<string, number> = { s: 1, m: 60, h: 3600, d: 86400 };
  return num * (multipliers[unit] || 1);
}
''';

  String sessionService(BackendConfig config) => '''import { prisma } from '../database/prisma';
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
  const days = parseInt(env.REFRESH_TOKEN_EXPIRES_IN.match(/\\d+/)?.[0] || '7', 10);
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

${config.enableRefreshTokenRotation ? '''
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
  await prisma.\$transaction(async (tx) => {
    await tx.session.update({
      where: { id: session.id },
      data: { revokedAt: new Date() },
    });

    const expiresAt = new Date();
    const days = parseInt(env.REFRESH_TOKEN_EXPIRES_IN.match(/\\d+/)?.[0] || '7', 10);
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
''' : '''
export async function rotateSession(
  _oldRefreshToken: string,
  _newRefreshToken: string,
): Promise<string | null> {
  // Refresh token rotation is disabled in configuration.
  return null;
}
'''}

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
''';

  String emailVerificationService() => '''import { prisma } from '../database/prisma';
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
    console.log(\`[DEV] Email verification token for \${email}: \${token}\`);
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

  await prisma.\$transaction(async (tx) => {
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
''';

  String passwordResetService() => '''import { prisma } from '../database/prisma';
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
    console.log(\`[DEV] Password reset token for user \${userId}: \${token}\`);
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

  await prisma.\$transaction(async (tx) => {
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
''';

  String disposableEmailService() => '''import fs from 'fs';
import path from 'path';
import { env } from '../config/env';

// Built-in disposable domains blocklist (subset).
// In production, load from an external file or API.
const BUILTIN_DISPOSABLE_DOMAINS = new Set<string>([
  'mailinator.com',
  'tempmail.com',
  'guerrillamail.com',
  'throwaway.email',
  '10minutemail.com',
  'trashmail.com',
  'fakeinbox.com',
  'sharklasers.com',
  'guerrillamailblock.com',
  'dispostable.com',
  'mailnesia.com',
  'maildrop.cc',
  'getnada.com',
  'temp-mail.org',
  'emailondeck.com',
  'trashmail.net',
]);

let customBlocklist: Set<string> | null = null;
let customAllowlist: Set<string> | null = null;

function loadCustomList(filePath: string | undefined): Set<string> {
  if (!filePath) return new Set();
  try {
    const content = fs.readFileSync(path.resolve(filePath), 'utf-8');
    return new Set(
      content
        .split('\\n')
        .map((line) => line.trim().toLowerCase())
        .filter((line) => line && !line.startsWith('#')),
    );
  } catch {
    return new Set();
  }
}

function getBlocklist(): Set<string> {
  if (customBlocklist === null) {
    customBlocklist = loadCustomList(env.DISPOSABLE_EMAIL_BLOCKLIST_PATH);
    for (const domain of BUILTIN_DISPOSABLE_DOMAINS) {
      customBlocklist.add(domain);
    }
  }
  return customBlocklist;
}

function getAllowlist(): Set<string> {
  if (customAllowlist === null) {
    customAllowlist = loadCustomList(env.DISPOSABLE_EMAIL_ALLOWLIST_PATH);
  }
  return customAllowlist;
}

function normalizeDomain(email: string): string {
  const parts = email.split('@');
  if (parts.length !== 2) return '';
  return parts[1].toLowerCase().trim();
}

export async function checkDisposableEmail(email: string): Promise<boolean> {
  const domain = normalizeDomain(email);
  if (!domain) return true; // Invalid email → block

  // Check allowlist first (overrides blocklist)
  const allowlist = getAllowlist();
  if (allowlist.has(domain)) return false;

  // Check blocklist
  const blocklist = getBlocklist();
  if (blocklist.has(domain)) return true;

  // Check for common disposable patterns
  if (domain.startsWith('temp.') || domain.includes('disposable')) {
    return true;
  }

  return false;
}

export function refreshBlocklists(): void {
  customBlocklist = null;
  customAllowlist = null;
}
''';
}
