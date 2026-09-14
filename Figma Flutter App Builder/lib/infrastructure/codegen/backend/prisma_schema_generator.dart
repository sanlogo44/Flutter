/// Generates a Prisma schema file from the backend configuration.
///
/// The schema includes the core auth models (User, AuthAccount, Session,
/// VerificationToken, PasswordResetToken), project models (Project,
/// ProjectMember), and any custom data models defined in the project.
///
/// Only auth-provider-specific fields (e.g. passwordHash for emailPassword)
/// are included when the corresponding provider is enabled.
library;

import 'backend_config.dart';
import '../../../domain/models.dart' show DataModel, DataField, DatabaseType;

class PrismaSchemaGenerator {
  PrismaSchemaGenerator();

  String generate(BackendConfig config) {
    final buf = StringBuffer();

    // Generator + datasource.
    buf.writeln('generator client {');
    buf.writeln('  provider = "prisma-client-js"');
    buf.writeln('}');
    buf.writeln();

    final dbProvider = _dbProvider(config.database);
    buf.writeln('datasource db {');
    buf.writeln('  provider = "$dbProvider"');
    buf.writeln('  url      = env("DATABASE_URL")');
    buf.writeln('}');
    buf.writeln();

    // Core models.
    _writeUser(buf, config);
    _writeAuthAccount(buf, config);
    _writeSession(buf, config);
    _writeVerificationToken(buf, config);
    _writePasswordResetToken(buf, config);
    _writeProject(buf, config);
    _writeProjectMember(buf, config);

    // Custom data models from project definition.
    for (final model in config.dataModels) {
      _writeDataModel(buf, model);
    }

    return buf.toString();
  }

  void _writeUser(StringBuffer buf, BackendConfig config) {
    buf.writeln('model User {');
    buf.writeln('  id            String   @id @default(cuid())');
    buf.writeln('  email         String   @unique');
    buf.writeln('  emailVerified DateTime?');
    buf.writeln('  displayName   String?');
    buf.writeln('  avatarUrl     String?');
    buf.writeln('  createdAt     DateTime @default(now())');
    buf.writeln('  updatedAt     DateTime @updatedAt');
    buf.writeln();
    buf.writeln('  accounts         AuthAccount[]');
    buf.writeln('  sessions         Session[]');
    buf.writeln('  passwordResetTokens PasswordResetToken[]');
    buf.writeln('  ownedProjects   Project[]      @relation("OwnedProjects")');
    buf.writeln('  projectMemberships ProjectMember[]');
    buf.writeln();
    buf.writeln('  @@index([email])');
    buf.writeln('}');
    buf.writeln();
  }

  void _writeAuthAccount(StringBuffer buf, BackendConfig config) {
    buf.writeln('model AuthAccount {');
    buf.writeln('  id                String   @id @default(cuid())');
    buf.writeln('  userId            String');
    buf.writeln('  provider          String');
    buf.writeln('  providerAccountId String');
    buf.writeln('  providerMetadata  Json?');

    // Password hash only when email/password auth is enabled.
    if (config.hasEmailPassword) {
      buf.writeln('  passwordHash      String?');
      buf.writeln('  passwordChangedAt DateTime?');
    }

    buf.writeln('  createdAt         DateTime @default(now())');
    buf.writeln('  updatedAt         DateTime @updatedAt');
    buf.writeln();
    buf.writeln('  user User @relation(fields: [userId], references: [id], onDelete: Cascade)');
    buf.writeln();
    buf.writeln('  @@unique([provider, providerAccountId])');
    buf.writeln('  @@index([userId])');
    buf.writeln('  @@index([provider])');
    buf.writeln('}');
    buf.writeln();
  }

  void _writeSession(StringBuffer buf, BackendConfig config) {
    buf.writeln('model Session {');
    buf.writeln('  id             String   @id @default(cuid())');
    buf.writeln('  userId         String');
    buf.writeln('  refreshTokenHash String  @unique');
    buf.writeln('  userAgent      String?');
    buf.writeln('  ipAddress      String?');

    if (config.enableRefreshTokenRotation) {
      buf.writeln('  rotatedFrom    String?  // previous refresh token hash');
    }

    buf.writeln('  expiresAt      DateTime');
    buf.writeln('  revokedAt     DateTime?');
    buf.writeln('  createdAt      DateTime @default(now())');
    buf.writeln('  updatedAt      DateTime @updatedAt');
    buf.writeln();
    buf.writeln('  user User @relation(fields: [userId], references: [id], onDelete: Cascade)');
    buf.writeln();
    buf.writeln('  @@index([userId])');
    buf.writeln('  @@index([expiresAt])');
    buf.writeln('}');
    buf.writeln();
  }

  void _writeVerificationToken(StringBuffer buf, BackendConfig config) {
    buf.writeln('model VerificationToken {');
    buf.writeln('  id        String   @id @default(cuid())');
    buf.writeln('  userId    String');
    buf.writeln('  token     String   @unique');
    buf.writeln('  type      String   // "email_verification" | "magic_link" | "phone_otp"');
    buf.writeln('  identifier String  // email or phone');
    buf.writeln('  expiresAt DateTime');
    buf.writeln('  usedAt    DateTime?');
    buf.writeln('  createdAt DateTime @default(now())');
    buf.writeln();
    buf.writeln('  @@index([userId])');
    buf.writeln('  @@index([identifier, type])');
    buf.writeln('}');
    buf.writeln();
  }

  void _writePasswordResetToken(StringBuffer buf, BackendConfig config) {
    buf.writeln('model PasswordResetToken {');
    buf.writeln('  id        String   @id @default(cuid())');
    buf.writeln('  userId    String');
    buf.writeln('  token     String   @unique');
    buf.writeln('  expiresAt DateTime');
    buf.writeln('  usedAt    DateTime?');
    buf.writeln('  createdAt DateTime @default(now())');
    buf.writeln();
    buf.writeln('  user User @relation(fields: [userId], references: [id], onDelete: Cascade)');
    buf.writeln();
    buf.writeln('  @@index([userId])');
    buf.writeln('}');
    buf.writeln();
  }

  void _writeProject(StringBuffer buf, BackendConfig config) {
    buf.writeln('model Project {');
    buf.writeln('  id          String   @id @default(cuid())');
    buf.writeln('  name        String');
    buf.writeln('  description String?');
    buf.writeln('  ownerId     String');
    buf.writeln('  metadata    Json?');
    buf.writeln('  createdAt   DateTime @default(now())');
    buf.writeln('  updatedAt   DateTime @updatedAt');
    buf.writeln();
    buf.writeln('  owner  User            @relation("OwnedProjects", fields: [ownerId], references: [id])');
    buf.writeln('  members ProjectMember[]');
    buf.writeln();
    buf.writeln('  @@index([ownerId])');
    buf.writeln('}');
    buf.writeln();
  }

  void _writeProjectMember(StringBuffer buf, BackendConfig config) {
    buf.writeln('model ProjectMember {');
    buf.writeln('  id        String   @id @default(cuid())');
    buf.writeln('  projectId String');
    buf.writeln('  userId    String');
    buf.writeln('  role      String   @default("member") // "owner" | "admin" | "editor" | "viewer"');
    buf.writeln('  createdAt DateTime @default(now())');
    buf.writeln('  updatedAt DateTime @updatedAt');
    buf.writeln();
    buf.writeln('  project Project @relation(fields: [projectId], references: [id], onDelete: Cascade)');
    buf.writeln('  user    User    @relation(fields: [userId], references: [id], onDelete: Cascade)');
    buf.writeln();
    buf.writeln('  @@unique([projectId, userId])');
    buf.writeln('  @@index([userId])');
    buf.writeln('}');
    buf.writeln();
  }

  void _writeDataModel(StringBuffer buf, DataModel model) {
    buf.writeln('model ${model.name} {');
    buf.writeln('  id        String   @id @default(cuid())');
    buf.writeln('  createdAt DateTime @default(now())');
    buf.writeln('  updatedAt DateTime @updatedAt');
    for (final field in model.fields) {
      final prismaType = _toPrismaType(field.type, field.nullable);
      buf.writeln('  ${field.name} $prismaType');
    }
    buf.writeln('}');
    buf.writeln();
  }

  String _toPrismaType(String dartType, bool nullable) {
    final base = switch (dartType) {
      'String' => 'String',
      'int' => 'Int',
      'double' => 'Float',
      'bool' => 'Boolean',
      'DateTime' => 'DateTime',
      'List' => 'Json',
      'Map' => 'Json',
      _ => 'Json',
    };
    return nullable ? '$base?' : base;
  }

  String _dbProvider(DatabaseType type) {
    return switch (type) {
      DatabaseType.postgres => 'postgresql',
      DatabaseType.mysql => 'mysql',
      DatabaseType.mongodb => 'mongodb',
    };
  }
}
