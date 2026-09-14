import 'package:flutter_test/flutter_test.dart';
import 'package:figma_flutter_builder/infrastructure/codegen/backend/backend_config.dart';
import 'package:figma_flutter_builder/infrastructure/codegen/backend/backend_generator.dart';
import 'package:figma_flutter_builder/domain/models.dart';

void main() {
  group('Provider Toggle: Disabled providers leave no trace', () {
    test('email-only config generates passwordHash and email-password provider', () {
      final result = BackendGenerator().generate(
        GeneratorSettings(
          projectName: 'test',
          generateBackend: true,
          database: DatabaseType.postgres,
          authProviders: [AuthProviderType.emailPassword],
        ),
      );

      final filePaths = result.files.map((f) => f.path).toSet();

      // Should have email-password provider file
      expect(filePaths, contains('backend/src/auth/providers/email-password.provider.ts'));
      // Should have password service
      expect(filePaths, contains('backend/src/auth/password.service.ts'));
      // Should have auth schemas with register/login
      final schemasContent = result.files
          .firstWhere((f) => f.path == 'backend/src/auth/auth.schemas.ts')
          .content;
      expect(schemasContent, contains('registerSchema'));
      expect(schemasContent, contains('loginSchema'));
    });

    test('Google-only config does NOT generate passwordHash or email-password provider', () {
      final result = BackendGenerator().generate(
        GeneratorSettings(
          projectName: 'test',
          generateBackend: true,
          database: DatabaseType.postgres,
          authProviders: [AuthProviderType.google],
        ),
      );

      final filePaths = result.files.map((f) => f.path).toSet();

      // Should NOT have email-password provider
      expect(filePaths, isNot(contains('backend/src/auth/providers/email-password.provider.ts')));
      // Should NOT have password service
      expect(filePaths, isNot(contains('backend/src/auth/password.service.ts')));

      // Prisma schema should not have passwordHash
      final prismaContent = result.files
          .firstWhere((f) => f.path == 'backend/prisma/schema.prisma')
          .content;
      expect(prismaContent, isNot(contains('passwordHash')));

      // Auth schemas should NOT have register/login
      final schemasContent = result.files
          .firstWhere((f) => f.path == 'backend/src/auth/auth.schemas.ts')
          .content;
      expect(schemasContent, isNot(contains('registerSchema')));
      expect(schemasContent, isNot(contains('loginSchema')));
    });

    test('No auth providers does NOT generate any auth files', () {
      final result = BackendGenerator().generate(
        GeneratorSettings(
          projectName: 'test',
          generateBackend: true,
          database: DatabaseType.postgres,
          authProviders: [],
        ),
      );

      final filePaths = result.files.map((f) => f.path).toSet();

      // Should NOT have any auth files
      expect(filePaths, isNot(contains('backend/src/auth/auth.routes.ts')));
      expect(filePaths, isNot(contains('backend/src/auth/auth.controller.ts')));
      expect(filePaths, isNot(contains('backend/src/auth/auth.schemas.ts')));
      expect(filePaths, isNot(contains('backend/src/auth/providers/auth-provider.ts')));

      // But should still have users, projects, and core files
      expect(filePaths, contains('backend/src/users/user.routes.ts'));
      expect(filePaths, contains('backend/src/projects/project.routes.ts'));
      expect(filePaths, contains('backend/src/main.ts'));
    });

    test('Rate limiting disabled: no rate-limit middleware file', () {
      final result = BackendGenerator().generate(
        GeneratorSettings(
          projectName: 'test',
          generateBackend: true,
          database: DatabaseType.postgres,
          authProviders: [AuthProviderType.emailPassword],
          enableRateLimiting: false,
        ),
      );

      final filePaths = result.files.map((f) => f.path).toSet();
      expect(filePaths, isNot(contains('backend/src/middleware/rate-limit.ts')));
    });

    test('Rate limiting enabled: rate-limit middleware file present', () {
      final result = BackendGenerator().generate(
        GeneratorSettings(
          projectName: 'test',
          generateBackend: true,
          database: DatabaseType.postgres,
          authProviders: [AuthProviderType.emailPassword],
          enableRateLimiting: true,
        ),
      );

      final filePaths = result.files.map((f) => f.path).toSet();
      expect(filePaths, contains('backend/src/middleware/rate-limit.ts'));
    });

    test('Disposable email protection disabled: no disposable-email service', () {
      final result = BackendGenerator().generate(
        GeneratorSettings(
          projectName: 'test',
          generateBackend: true,
          database: DatabaseType.postgres,
          authProviders: [AuthProviderType.emailPassword],
          enableDisposableEmailProtection: false,
        ),
      );

      final filePaths = result.files.map((f) => f.path).toSet();
      expect(filePaths, isNot(contains('backend/src/auth/disposable-email.service.ts')));
    });

    test('Disposable email protection enabled: disposable-email service present', () {
      final result = BackendGenerator().generate(
        GeneratorSettings(
          projectName: 'test',
          generateBackend: true,
          database: DatabaseType.postgres,
          authProviders: [AuthProviderType.emailPassword],
          enableDisposableEmailProtection: true,
        ),
      );

      final filePaths = result.files.map((f) => f.path).toSet();
      expect(filePaths, contains('backend/src/auth/disposable-email.service.ts'));
    });

    test('Email verification disabled: no email-verification service', () {
      final result = BackendGenerator().generate(
        GeneratorSettings(
          projectName: 'test',
          generateBackend: true,
          database: DatabaseType.postgres,
          authProviders: [AuthProviderType.emailPassword],
          enableEmailVerification: false,
        ),
      );

      final filePaths = result.files.map((f) => f.path).toSet();
      expect(filePaths, isNot(contains('backend/src/auth/email-verification.service.ts')));
    });

    test('Email verification enabled: email-verification service present', () {
      final result = BackendGenerator().generate(
        GeneratorSettings(
          projectName: 'test',
          generateBackend: true,
          database: DatabaseType.postgres,
          authProviders: [AuthProviderType.emailPassword],
          enableEmailVerification: true,
        ),
      );

      final filePaths = result.files.map((f) => f.path).toSet();
      expect(filePaths, contains('backend/src/auth/email-verification.service.ts'));
    });

    test('Flutter API client files generated when auth is enabled', () {
      final result = BackendGenerator().generate(
        GeneratorSettings(
          projectName: 'test',
          generateBackend: true,
          database: DatabaseType.postgres,
          authProviders: [AuthProviderType.emailPassword],
        ),
      );

      final filePaths = result.files.map((f) => f.path).toSet();
      expect(filePaths, contains('lib/api/api_client.dart'));
      expect(filePaths, contains('lib/api/auth_models.dart'));
      expect(filePaths, contains('lib/api/auth_api.dart'));
      expect(filePaths, contains('lib/api/auth_state.dart'));
    });

    test('Flutter API client files NOT generated when no auth providers', () {
      final result = BackendGenerator().generate(
        GeneratorSettings(
          projectName: 'test',
          generateBackend: true,
          database: DatabaseType.postgres,
          authProviders: [],
        ),
      );

      final filePaths = result.files.map((f) => f.path).toSet();
      expect(filePaths, isNot(contains('lib/api/api_client.dart')));
      expect(filePaths, isNot(contains('lib/api/auth_api.dart')));
    });

    test('package.json only includes argon2 when emailPassword is enabled', () {
      final withEmail = BackendGenerator().generate(
        GeneratorSettings(
          projectName: 'test',
          generateBackend: true,
          database: DatabaseType.postgres,
          authProviders: [AuthProviderType.emailPassword],
        ),
      );
      final withoutEmail = BackendGenerator().generate(
        GeneratorSettings(
          projectName: 'test',
          generateBackend: true,
          database: DatabaseType.postgres,
          authProviders: [AuthProviderType.google],
        ),
      );

      final pkgWithEmail = withEmail.files
          .firstWhere((f) => f.path == 'backend/package.json')
          .content;
      final pkgWithoutEmail = withoutEmail.files
          .firstWhere((f) => f.path == 'backend/package.json')
          .content;

      expect(pkgWithEmail, contains('argon2'));
      expect(pkgWithoutEmail, isNot(contains('argon2')));
    });

    test('package.json includes express-rate-limit only when rate limiting is enabled', () {
      final withRateLimit = BackendGenerator().generate(
        GeneratorSettings(
          projectName: 'test',
          generateBackend: true,
          database: DatabaseType.postgres,
          authProviders: [AuthProviderType.emailPassword],
          enableRateLimiting: true,
        ),
      );
      final withoutRateLimit = BackendGenerator().generate(
        GeneratorSettings(
          projectName: 'test',
          generateBackend: true,
          database: DatabaseType.postgres,
          authProviders: [AuthProviderType.emailPassword],
          enableRateLimiting: false,
        ),
      );

      final pkgWith = withRateLimit.files
          .firstWhere((f) => f.path == 'backend/package.json')
          .content;
      final pkgWithout = withoutRateLimit.files
          .firstWhere((f) => f.path == 'backend/package.json')
          .content;

      expect(pkgWith, contains('express-rate-limit'));
      expect(pkgWithout, isNot(contains('express-rate-limit')));
    });
  });
}
