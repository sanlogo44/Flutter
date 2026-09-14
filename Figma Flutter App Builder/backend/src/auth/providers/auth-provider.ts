import { Request, Response } from 'express';

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
