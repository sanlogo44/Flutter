/// Generates the initial SQL migration file from the Prisma schema.
library;

import 'backend_config.dart';

class PrismaMigrationGenerator {
  PrismaMigrationGenerator();

  String generate(BackendConfig config) {
    final buf = StringBuffer();
    buf.writeln('-- CreateTable');
    buf.writeln('CREATE TABLE "User" (');
    buf.writeln('    "id" TEXT NOT NULL,');
    buf.writeln('    "email" TEXT NOT NULL,');
    buf.writeln('    "emailVerified" TIMESTAMP(3),');
    buf.writeln('    "displayName" TEXT,');
    buf.writeln('    "avatarUrl" TEXT,');
    buf.writeln('    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,');
    buf.writeln('    "updatedAt" TIMESTAMP(3) NOT NULL,');
    buf.writeln();
    buf.writeln('    CONSTRAINT "User_pkey" PRIMARY KEY ("id")');
    buf.writeln(');');
    buf.writeln();
    buf.writeln('-- CreateIndex');
    buf.writeln('CREATE UNIQUE INDEX "User_email_key" ON "User"("email");');
    buf.writeln('CREATE INDEX "User_email_idx" ON "User"("email");');
    buf.writeln();

    // AuthAccount
    buf.writeln('CREATE TABLE "AuthAccount" (');
    buf.writeln('    "id" TEXT NOT NULL,');
    buf.writeln('    "userId" TEXT NOT NULL,');
    buf.writeln('    "provider" TEXT NOT NULL,');
    buf.writeln('    "providerAccountId" TEXT NOT NULL,');
    buf.writeln('    "providerMetadata" JSONB,');
    if (config.hasEmailPassword) {
      buf.writeln('    "passwordHash" TEXT,');
      buf.writeln('    "passwordChangedAt" TIMESTAMP(3),');
    }
    buf.writeln('    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,');
    buf.writeln('    "updatedAt" TIMESTAMP(3) NOT NULL,');
    buf.writeln();
    buf.writeln('    CONSTRAINT "AuthAccount_pkey" PRIMARY KEY ("id")');
    buf.writeln(');');
    buf.writeln();
    buf.writeln('CREATE UNIQUE INDEX "AuthAccount_provider_providerAccountId_key" ON "AuthAccount"("provider", "providerAccountId");');
    buf.writeln('CREATE INDEX "AuthAccount_userId_idx" ON "AuthAccount"("userId");');
    buf.writeln('CREATE INDEX "AuthAccount_provider_idx" ON "AuthAccount"("provider");');
    buf.writeln();

    // Session
    buf.writeln('CREATE TABLE "Session" (');
    buf.writeln('    "id" TEXT NOT NULL,');
    buf.writeln('    "userId" TEXT NOT NULL,');
    buf.writeln('    "refreshTokenHash" TEXT NOT NULL,');
    buf.writeln('    "userAgent" TEXT,');
    buf.writeln('    "ipAddress" TEXT,');
    if (config.enableRefreshTokenRotation) {
      buf.writeln('    "rotatedFrom" TEXT,');
    }
    buf.writeln('    "expiresAt" TIMESTAMP(3) NOT NULL,');
    buf.writeln('    "revokedAt" TIMESTAMP(3),');
    buf.writeln('    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,');
    buf.writeln('    "updatedAt" TIMESTAMP(3) NOT NULL,');
    buf.writeln();
    buf.writeln('    CONSTRAINT "Session_pkey" PRIMARY KEY ("id")');
    buf.writeln(');');
    buf.writeln();
    buf.writeln('CREATE UNIQUE INDEX "Session_refreshTokenHash_key" ON "Session"("refreshTokenHash");');
    buf.writeln('CREATE INDEX "Session_userId_idx" ON "Session"("userId");');
    buf.writeln('CREATE INDEX "Session_expiresAt_idx" ON "Session"("expiresAt");');
    buf.writeln();

    // VerificationToken
    buf.writeln('CREATE TABLE "VerificationToken" (');
    buf.writeln('    "id" TEXT NOT NULL,');
    buf.writeln('    "userId" TEXT NOT NULL,');
    buf.writeln('    "token" TEXT NOT NULL,');
    buf.writeln('    "type" TEXT NOT NULL,');
    buf.writeln('    "identifier" TEXT NOT NULL,');
    buf.writeln('    "expiresAt" TIMESTAMP(3) NOT NULL,');
    buf.writeln('    "usedAt" TIMESTAMP(3),');
    buf.writeln('    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,');
    buf.writeln();
    buf.writeln('    CONSTRAINT "VerificationToken_pkey" PRIMARY KEY ("id")');
    buf.writeln(');');
    buf.writeln();
    buf.writeln('CREATE UNIQUE INDEX "VerificationToken_token_key" ON "VerificationToken"("token");');
    buf.writeln('CREATE INDEX "VerificationToken_userId_idx" ON "VerificationToken"("userId");');
    buf.writeln('CREATE INDEX "VerificationToken_identifier_type_idx" ON "VerificationToken"("identifier", "type");');
    buf.writeln();

    // PasswordResetToken
    buf.writeln('CREATE TABLE "PasswordResetToken" (');
    buf.writeln('    "id" TEXT NOT NULL,');
    buf.writeln('    "userId" TEXT NOT NULL,');
    buf.writeln('    "token" TEXT NOT NULL,');
    buf.writeln('    "expiresAt" TIMESTAMP(3) NOT NULL,');
    buf.writeln('    "usedAt" TIMESTAMP(3),');
    buf.writeln('    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,');
    buf.writeln();
    buf.writeln('    CONSTRAINT "PasswordResetToken_pkey" PRIMARY KEY ("id")');
    buf.writeln(');');
    buf.writeln();
    buf.writeln('CREATE UNIQUE INDEX "PasswordResetToken_token_key" ON "PasswordResetToken"("token");');
    buf.writeln('CREATE INDEX "PasswordResetToken_userId_idx" ON "PasswordResetToken"("userId");');
    buf.writeln();

    // Project
    buf.writeln('CREATE TABLE "Project" (');
    buf.writeln('    "id" TEXT NOT NULL,');
    buf.writeln('    "name" TEXT NOT NULL,');
    buf.writeln('    "description" TEXT,');
    buf.writeln('    "ownerId" TEXT NOT NULL,');
    buf.writeln('    "metadata" JSONB,');
    buf.writeln('    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,');
    buf.writeln('    "updatedAt" TIMESTAMP(3) NOT NULL,');
    buf.writeln();
    buf.writeln('    CONSTRAINT "Project_pkey" PRIMARY KEY ("id")');
    buf.writeln(');');
    buf.writeln();
    buf.writeln('CREATE INDEX "Project_ownerId_idx" ON "Project"("ownerId");');
    buf.writeln();

    // ProjectMember
    buf.writeln('CREATE TABLE "ProjectMember" (');
    buf.writeln('    "id" TEXT NOT NULL,');
    buf.writeln('    "projectId" TEXT NOT NULL,');
    buf.writeln('    "userId" TEXT NOT NULL,');
    buf.writeln('    "role" TEXT NOT NULL DEFAULT \'member\',');
    buf.writeln('    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,');
    buf.writeln('    "updatedAt" TIMESTAMP(3) NOT NULL,');
    buf.writeln();
    buf.writeln('    CONSTRAINT "ProjectMember_pkey" PRIMARY KEY ("id")');
    buf.writeln(');');
    buf.writeln();
    buf.writeln('CREATE UNIQUE INDEX "ProjectMember_projectId_userId_key" ON "ProjectMember"("projectId", "userId");');
    buf.writeln('CREATE INDEX "ProjectMember_userId_idx" ON "ProjectMember"("userId");');
    buf.writeln();

    // Foreign Keys
    buf.writeln('-- AddForeignKey');
    buf.writeln('ALTER TABLE "AuthAccount" ADD CONSTRAINT "AuthAccount_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE;');
    buf.writeln();
    buf.writeln('ALTER TABLE "Session" ADD CONSTRAINT "Session_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE;');
    buf.writeln();
    buf.writeln('ALTER TABLE "PasswordResetToken" ADD CONSTRAINT "PasswordResetToken_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE;');
    buf.writeln();
    buf.writeln('ALTER TABLE "Project" ADD CONSTRAINT "Project_ownerId_fkey" FOREIGN KEY ("ownerId") REFERENCES "User"("id");');
    buf.writeln();
    buf.writeln('ALTER TABLE "ProjectMember" ADD CONSTRAINT "ProjectMember_projectId_fkey" FOREIGN KEY ("projectId") REFERENCES "Project"("id") ON DELETE CASCADE;');
    buf.writeln();
    buf.writeln('ALTER TABLE "ProjectMember" ADD CONSTRAINT "ProjectMember_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE;');

    return buf.toString();
  }
}
