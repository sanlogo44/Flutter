# SampleApp Backend

Generated backend for the SampleApp Flutter app.

## Stack
- Node.js + TypeScript
- Express
- Prisma ORM
- PostgreSQL

## Setup
```bash
# Install dependencies
npm install

# Copy env file
cp .env.example .env

# Generate Prisma client
npm run prisma:generate

# Run migrations
npm run prisma:migrate

# Start dev server
npm run dev
```

## Auth Providers
- emailPassword
- google

## Rate Limiting
Enabled. Configurable via RATE_LIMIT_WINDOW_MS and RATE_LIMIT_MAX env vars.

## Disposable Email Protection
Enabled. Blocklist and allowlist configurable via env vars.

## Refresh Token Rotation
Enabled. Old refresh tokens are revoked on rotation.

## Security
- Passwords hashed with argon2id
- JWT access + refresh tokens
- Helmet security headers
- CORS configuration
- Zod request validation
- Structured error handling

