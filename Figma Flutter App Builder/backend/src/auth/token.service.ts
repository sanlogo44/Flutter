import jwt from 'jsonwebtoken';
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
  const match = expiresIn.match(/^(\d+)(s|m|h|d)$/);
  if (!match) return 900; // default 15 min
  const num = parseInt(match[1], 10);
  const unit = match[2];
  const multipliers: Record<string, number> = { s: 1, m: 60, h: 3600, d: 86400 };
  return num * (multipliers[unit] || 1);
}
