import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';
import 'package:figma_flutter_builder/infrastructure/codegen/backend/backend_config.dart';
import 'package:figma_flutter_builder/infrastructure/codegen/backend/openapi_generator.dart';
import 'package:figma_flutter_builder/domain/models.dart';

void main() {
  group('OpenApiGenerator', () {
    test('generates valid OpenAPI 3.1 JSON', () {
      final config = BackendConfig.fromSettings(
        GeneratorSettings(
          projectName: 'testapp',
          generateBackend: true,
          database: DatabaseType.postgres,
          authProviders: [AuthProviderType.emailPassword],
        ),
      );
      final json = OpenApiGenerator().generate(config);
      final spec = jsonDecode(json) as Map<String, dynamic>;

      expect(spec['openapi'], '3.1.0');
      expect(spec['info'], isNotNull);
      expect((spec['info'] as Map)['title'], 'testapp API');
    });

    test('includes register endpoint when emailPassword is enabled', () {
      final config = BackendConfig.fromSettings(
        GeneratorSettings(
          projectName: 'test',
          generateBackend: true,
          database: DatabaseType.postgres,
          authProviders: [AuthProviderType.emailPassword],
        ),
      );
      final json = OpenApiGenerator().generate(config);
      final spec = jsonDecode(json) as Map<String, dynamic>;
      final paths = spec['paths'] as Map<String, dynamic>;

      expect(paths.containsKey('/api/auth/register'), true);
      expect(paths.containsKey('/api/auth/login'), true);
    });

    test('does NOT include register endpoint when emailPassword is disabled', () {
      final config = BackendConfig.fromSettings(
        GeneratorSettings(
          projectName: 'test',
          generateBackend: true,
          database: DatabaseType.postgres,
          authProviders: [AuthProviderType.google],
        ),
      );
      final json = OpenApiGenerator().generate(config);
      final spec = jsonDecode(json) as Map<String, dynamic>;
      final paths = spec['paths'] as Map<String, dynamic>;

      expect(paths.containsKey('/api/auth/register'), false);
      expect(paths.containsKey('/api/auth/login'), false);
    });

    test('always includes refresh, logout, and me endpoints when auth is enabled', () {
      final config = BackendConfig.fromSettings(
        GeneratorSettings(
          projectName: 'test',
          generateBackend: true,
          database: DatabaseType.postgres,
          authProviders: [AuthProviderType.google],
        ),
      );
      final json = OpenApiGenerator().generate(config);
      final spec = jsonDecode(json) as Map<String, dynamic>;
      final paths = spec['paths'] as Map<String, dynamic>;

      expect(paths.containsKey('/api/auth/refresh'), true);
      expect(paths.containsKey('/api/auth/logout'), true);
      expect(paths.containsKey('/api/auth/me'), true);
    });

    test('includes verify-email endpoint only when email verification is enabled', () {
      final withVerification = BackendConfig.fromSettings(
        GeneratorSettings(
          projectName: 'test',
          generateBackend: true,
          database: DatabaseType.postgres,
          authProviders: [AuthProviderType.emailPassword],
          enableEmailVerification: true,
        ),
      );
      final withoutVerification = BackendConfig.fromSettings(
        GeneratorSettings(
          projectName: 'test',
          generateBackend: true,
          database: DatabaseType.postgres,
          authProviders: [AuthProviderType.emailPassword],
          enableEmailVerification: false,
        ),
      );

      final jsonWith = OpenApiGenerator().generate(withVerification);
      final jsonWithout = OpenApiGenerator().generate(withoutVerification);
      final specWith = jsonDecode(jsonWith) as Map<String, dynamic>;
      final specWithout = jsonDecode(jsonWithout) as Map<String, dynamic>;
      final pathsWith = specWith['paths'] as Map<String, dynamic>;
      final pathsWithout = specWithout['paths'] as Map<String, dynamic>;

      expect(pathsWith.containsKey('/api/auth/verify-email'), true);
      expect(pathsWithout.containsKey('/api/auth/verify-email'), false);
    });

    test('includes user and project endpoints', () {
      final config = BackendConfig.fromSettings(
        GeneratorSettings(
          projectName: 'test',
          generateBackend: true,
          database: DatabaseType.postgres,
          authProviders: [AuthProviderType.emailPassword],
        ),
      );
      final json = OpenApiGenerator().generate(config);
      final spec = jsonDecode(json) as Map<String, dynamic>;
      final paths = spec['paths'] as Map<String, dynamic>;

      expect(paths.containsKey('/api/users/me'), true);
      expect(paths.containsKey('/api/projects'), true);
    });

    test('includes bearerAuth security scheme', () {
      final config = BackendConfig.fromSettings(
        GeneratorSettings(
          projectName: 'test',
          generateBackend: true,
          database: DatabaseType.postgres,
          authProviders: [AuthProviderType.emailPassword],
        ),
      );
      final json = OpenApiGenerator().generate(config);
      final spec = jsonDecode(json) as Map<String, dynamic>;
      final components = spec['components'] as Map<String, dynamic>;
      final securitySchemes = components['securitySchemes'] as Map<String, dynamic>;
      final bearerAuth = securitySchemes['bearerAuth'] as Map<String, dynamic>;

      expect(bearerAuth['type'], 'http');
      expect(bearerAuth['scheme'], 'bearer');
    });
  });
}
