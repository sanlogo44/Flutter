import 'package:flutter_test/flutter_test.dart';
import 'package:figma_flutter_builder/infrastructure/codegen/backend/backend_config.dart';
import 'package:figma_flutter_builder/infrastructure/codegen/backend/package_json_generator.dart';
import 'package:figma_flutter_builder/domain/models.dart';

void main() {
  group('PackageJsonGenerator', () {
    test('generates valid JSON with required dependencies', () {
      final config = BackendConfig.fromSettings(
        GeneratorSettings(
          projectName: 'myapp',
          generateBackend: true,
          database: DatabaseType.postgres,
          authProviders: [AuthProviderType.emailPassword],
          enableRateLimiting: true,
        ),
      );
      final json = PackageJsonGenerator().generate(config);

      // Should be valid JSON
      expect(json.isNotEmpty, true);

      // Core deps
      expect(json, contains('"express"'));
      expect(json, contains('"@prisma/client"'));
      expect(json, contains('"helmet"'));
      expect(json, contains('"zod"'));
      expect(json, contains('"jsonwebtoken"'));

      // Email password → argon2
      expect(json, contains('"argon2"'));

      // Rate limiting → express-rate-limit
      expect(json, contains('"express-rate-limit"'));
    });

    test('does not include argon2 when emailPassword is disabled', () {
      final config = BackendConfig.fromSettings(
        GeneratorSettings(
          projectName: 'myapp',
          generateBackend: true,
          database: DatabaseType.postgres,
          authProviders: [AuthProviderType.google],
        ),
      );
      final json = PackageJsonGenerator().generate(config);

      expect(json, isNot(contains('argon2')));
    });

    test('does not include express-rate-limit when rate limiting is disabled', () {
      final config = BackendConfig.fromSettings(
        GeneratorSettings(
          projectName: 'myapp',
          generateBackend: true,
          database: DatabaseType.postgres,
          authProviders: [AuthProviderType.emailPassword],
          enableRateLimiting: false,
        ),
      );
      final json = PackageJsonGenerator().generate(config);

      expect(json, isNot(contains('express-rate-limit')));
    });
  });

  group('EnvExampleGenerator', () {
    test('includes DATABASE_URL and JWT_SECRET', () {
      final config = BackendConfig.fromSettings(
        GeneratorSettings(
          projectName: 'myapp',
          generateBackend: true,
          database: DatabaseType.postgres,
          authProviders: [AuthProviderType.emailPassword],
        ),
      );
      final env = EnvExampleGenerator().generate(config);

      expect(env, contains('DATABASE_URL'));
      expect(env, contains('JWT_SECRET'));
      expect(env, contains('PORT'));
    });

    test('includes rate limit vars when rate limiting is enabled', () {
      final config = BackendConfig.fromSettings(
        GeneratorSettings(
          projectName: 'myapp',
          generateBackend: true,
          database: DatabaseType.postgres,
          authProviders: [AuthProviderType.emailPassword],
          enableRateLimiting: true,
        ),
      );
      final env = EnvExampleGenerator().generate(config);

      expect(env, contains('RATE_LIMIT_WINDOW_MS'));
      expect(env, contains('RATE_LIMIT_MAX'));
    });

    test('does not include rate limit vars when disabled', () {
      final config = BackendConfig.fromSettings(
        GeneratorSettings(
          projectName: 'myapp',
          generateBackend: true,
          database: DatabaseType.postgres,
          authProviders: [AuthProviderType.emailPassword],
          enableRateLimiting: false,
        ),
      );
      final env = EnvExampleGenerator().generate(config);

      expect(env, isNot(contains('RATE_LIMIT_WINDOW_MS')));
    });

    test('includes disposable email vars when enabled', () {
      final config = BackendConfig.fromSettings(
        GeneratorSettings(
          projectName: 'myapp',
          generateBackend: true,
          database: DatabaseType.postgres,
          authProviders: [AuthProviderType.emailPassword],
          enableDisposableEmailProtection: true,
        ),
      );
      final env = EnvExampleGenerator().generate(config);

      expect(env, contains('DISPOSABLE_EMAIL_BLOCKLIST_PATH'));
      expect(env, contains('DISPOSABLE_EMAIL_ALLOWLIST_PATH'));
    });

    test('includes OAuth vars only for enabled providers', () {
      final config = BackendConfig.fromSettings(
        GeneratorSettings(
          projectName: 'myapp',
          generateBackend: true,
          database: DatabaseType.postgres,
          authProviders: [AuthProviderType.google, AuthProviderType.github],
        ),
      );
      final env = EnvExampleGenerator().generate(config);

      expect(env, contains('GOOGLE_CLIENT_ID'));
      expect(env, contains('GITHUB_CLIENT_ID'));
    });

    test('does not include OAuth vars when no OAuth providers', () {
      final config = BackendConfig.fromSettings(
        GeneratorSettings(
          projectName: 'myapp',
          generateBackend: true,
          database: DatabaseType.postgres,
          authProviders: [AuthProviderType.emailPassword],
        ),
      );
      final env = EnvExampleGenerator().generate(config);

      expect(env, isNot(contains('GOOGLE_CLIENT_ID')));
      expect(env, isNot(contains('GITHUB_CLIENT_ID')));
    });
  });

  group('BackendConfig', () {
    test('hasAnyAuthProvider returns false for empty providers', () {
      final config = BackendConfig.fromSettings(
        GeneratorSettings(
          projectName: 'test',
          generateBackend: true,
          database: DatabaseType.postgres,
          authProviders: [],
        ),
      );

      expect(config.hasAnyAuthProvider, false);
      expect(config.hasEmailPassword, false);
      expect(config.hasOAuthProvider, false);
    });

    test('hasOAuthProvider returns true for Google', () {
      final config = BackendConfig.fromSettings(
        GeneratorSettings(
          projectName: 'test',
          generateBackend: true,
          database: DatabaseType.postgres,
          authProviders: [AuthProviderType.google],
        ),
      );

      expect(config.hasOAuthProvider, true);
      expect(config.hasGoogle, true);
      expect(config.hasGithub, false);
      expect(config.hasEmailPassword, false);
    });

    test('hasOAuthProvider returns true for any OAuth provider', () {
      for (final provider in [
        AuthProviderType.google,
        AuthProviderType.github,
        AuthProviderType.microsoft,
        AuthProviderType.apple,
      ]) {
        final config = BackendConfig.fromSettings(
          GeneratorSettings(
            projectName: 'test',
            generateBackend: true,
            database: DatabaseType.postgres,
            authProviders: [provider],
          ),
        );

        expect(config.hasOAuthProvider, true, reason: '$provider should be an OAuth provider');
      }
    });
  });
}
