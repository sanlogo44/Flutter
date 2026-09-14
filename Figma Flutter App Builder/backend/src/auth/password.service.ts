import argon2 from 'argon2';
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
    return { valid: false, message: `Password must be at least ${env.PASSWORD_MIN_LENGTH} characters long` };
  }

  if (env.PASSWORD_REQUIRE_UPPERCASE && !/[A-Z]/.test(password)) {
    return { valid: false, message: 'Password must contain at least one uppercase letter' };
  }

  if (env.PASSWORD_REQUIRE_LOWERCASE && !/[a-z]/.test(password)) {
    return { valid: false, message: 'Password must contain at least one lowercase letter' };
  }

  if (env.PASSWORD_REQUIRE_NUMBER && !/\d/.test(password)) {
    return { valid: false, message: 'Password must contain at least one number' };
  }

  if (env.PASSWORD_REQUIRE_SPECIAL && !/[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]/.test(password)) {
    return { valid: false, message: 'Password must contain at least one special character' };
  }

  return { valid: true, message: 'Password is valid' };
}

export function generateToken(length: number = 32): string {
  return crypto.randomBytes(length).toString('hex');
}
