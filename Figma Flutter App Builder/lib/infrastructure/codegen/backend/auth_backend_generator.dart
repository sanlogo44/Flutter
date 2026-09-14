/// Generates the auth provider interface and the email/password provider
/// implementation.
library;

import 'backend_config.dart';

class AuthBackendGenerator {
  AuthBackendGenerator();

  /// The provider interface that all auth providers implement.
  String providerInterface() => '''import { Request, Response } from 'express';

export interface AuthProvider {
  readonly name: string;

  // Initialize the provider (e.g. load OAuth config)
  initialize(): Promise<void>;

  // Register a new user or link to existing account
  // Returns the user ID
  authenticate(req: Request, res: Response): Promise<{ userId: string; refreshToken: string } | null>;

  // Get provider-specific routes (e.g. OAuth callback)
  getRoutes?(): { method: string; path: string; handler: (req: Request, res: Response) => Promise<void> }[];
}

export interface AuthResult {
  userId: string;
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
}
''';

  /// Email/password provider implementation using argon2 for hashing.
  String emailPasswordProvider(BackendConfig config) => '''import { Request, Response } from 'express';
import { prisma } from '../../database/prisma';
import { hashPassword, verifyPassword, validatePassword } from '../password.service';
import { env } from '../../config/env';
import type { AuthProvider, AuthResult } from './auth-provider';
import { createVerificationToken } from '../email-verification.service';
import { checkDisposableEmail } from '../disposable-email.service';
import { issueTokens } from '../token.service';
import { createSession } from '../session.service';

export class EmailPasswordProvider implements AuthProvider {
  readonly name = 'email-password';

  async initialize(): Promise<void> {
    // No async initialization needed for email/password.
  }

  async authenticate(req: Request, _res: Response): Promise<{ userId: string; refreshToken: string } | null> {
    // This provider is handled via explicit register/login routes,
    // not via a single authenticate() call.
    return null;
  }
}

export const emailPasswordProvider = new EmailPasswordProvider();

// --- Registration ---

export async function register(req: Request, res: Response): Promise<void> {
  const { email, password, displayName } = req.body;

  // Validate email format
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+\$/;
  if (!emailRegex.test(email)) {
    res.status(400).json({ error: 'Invalid email format' });
    return;
  }

  // Check disposable email if enabled
  if (config.enableDisposableEmailProtection) {
    // disposable email check
    await checkDisposableEmail(email);
  }

  // Validate password
  const passwordValidation = validatePassword(password);
  if (!passwordValidation.valid) {
    res.status(400).json({ error: passwordValidation.message });
    return;
  }

  // Check if user already exists
  const existing = await prisma.user.findUnique({ where: { email } });
  if (existing) {
    res.status(409).json({ error: 'An account with this email already exists' });
    return;
  }

  // Hash password
  const passwordHash = await hashPassword(password);

  // Create user + auth account in a transaction
  const user = await prisma.\$transaction(async (tx) => {
    const newUser = await tx.user.create({
      data: {
        email,
        displayName: displayName || null,
      },
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

  // Issue tokens
  const tokens = await issueTokens(user.id);

  // Create session
  await createSession(user.id, tokens.refreshToken, req);

  // Send verification email if enabled
  if (config.enableEmailVerification) {
    // email verification enabled
    await createVerificationToken(user.id, email);
  }

  const result: AuthResult = {
    userId: user.id,
    accessToken: tokens.accessToken,
    refreshToken: tokens.refreshToken,
    expiresIn: tokens.expiresIn,
  };

  res.status(201).json({
    user: { id: user.id, email: user.email, displayName: user.displayName },
    ...result,
  });
}

// --- Login ---

export async function login(req: Request, res: Response): Promise<void> {
  const { email, password } = req.body;

  // Find auth account
  const account = await prisma.authAccount.findFirst({
    where: { provider: 'email-password', providerAccountId: email },
    include: { user: true },
  });

  if (!account || !account.passwordHash) {
    // Use generic message to prevent account enumeration
    res.status(401).json({ error: 'Invalid email or password' });
    return;
  }

  // Verify password
  const valid = await verifyPassword(password, account.passwordHash);
  if (!valid) {
    res.status(401).json({ error: 'Invalid email or password' });
    return;
  }

  // Issue tokens
  const tokens = await issueTokens(account.user.id);

  // Create session
  await createSession(account.user.id, tokens.refreshToken, req);

  const result: AuthResult = {
    userId: account.user.id,
    accessToken: tokens.accessToken,
    refreshToken: tokens.refreshToken,
    expiresIn: tokens.expiresIn,
  };

  res.json({
    user: {
      id: account.user.id,
      email: account.user.email,
      displayName: account.user.displayName,
    },
    ...result,
  });
}
''';
}
