import fs from 'fs';
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
        .split('\n')
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
