import 'package:flutter_test/flutter_test.dart';
import 'package:figma_flutter_builder/infrastructure/codegen/backend/backend_config.dart';
import 'package:figma_flutter_builder/infrastructure/codegen/backend/prisma_schema_generator.dart';
import 'package:figma_flutter_builder/domain/models.dart';

void main() {
  group('PrismaSchemaGenerator', () {
    test('generates User model with required fields', () {
      final config = BackendConfig.fromSettings(
        GeneratorSettings(
          projectName: 'test',
          generateBackend: true,
          database: DatabaseType.postgres,
          authProviders: [AuthProviderType.emailPassword],
        ),
      );
      final schema = PrismaSchemaGenerator().generate(config);

      expect(schema, contains('model User {'));
      expect(schema, contains('id            String   @id @default(cuid())'));
      expect(schema, contains('email         String   @unique'));
      expect(schema, contains('emailVerified DateTime?'));
      expect(schema, contains('createdAt     DateTime @default(now())'));
    });

    test('includes passwordHash only when emailPassword is enabled', () {
      final withPassword = BackendConfig.fromSettings(
        GeneratorSettings(
          projectName: 'test',
          generateBackend: true,
          database: DatabaseType.postgres,
          authProviders: [AuthProviderType.emailPassword],
        ),
      );
      final withoutPassword = BackendConfig.fromSettings(
        GeneratorSettings(
          projectName: 'test',
          generateBackend: true,
          database: DatabaseType.postgres,
          authProviders: [AuthProviderType.google],
        ),
      );

      final schemaWith = PrismaSchemaGenerator().generate(withPassword);
      final schemaWithout = PrismaSchemaGenerator().generate(withoutPassword);

      expect(schemaWith, contains('passwordHash'));
      expect(schemaWithout, isNot(contains('passwordHash')));
    });

    test('includes rotatedFrom field when refresh token rotation is enabled', () {
      final config = BackendConfig.fromSettings(
        GeneratorSettings(
          projectName: 'test',
          generateBackend: true,
          database: DatabaseType.postgres,
          authProviders: [AuthProviderType.emailPassword],
          enableRefreshTokenRotation: true,
        ),
      );
      final schema = PrismaSchemaGenerator().generate(config);

      expect(schema, contains('rotatedFrom'));
    });

    test('does not include rotatedFrom when rotation is disabled', () {
      final config = BackendConfig.fromSettings(
        GeneratorSettings(
          projectName: 'test',
          generateBackend: true,
          database: DatabaseType.postgres,
          authProviders: [AuthProviderType.emailPassword],
          enableRefreshTokenRotation: false,
        ),
      );
      final schema = PrismaSchemaGenerator().generate(config);

      expect(schema, isNot(contains('rotatedFrom')));
    });

    test('uses postgresql provider for Postgres database', () {
      final config = BackendConfig.fromSettings(
        GeneratorSettings(
          projectName: 'test',
          generateBackend: true,
          database: DatabaseType.postgres,
          authProviders: [AuthProviderType.emailPassword],
        ),
      );
      final schema = PrismaSchemaGenerator().generate(config);

      expect(schema, contains('provider = "postgresql"'));
    });

    test('uses mysql provider for MySQL database', () {
      final config = BackendConfig.fromSettings(
        GeneratorSettings(
          projectName: 'test',
          generateBackend: true,
          database: DatabaseType.mysql,
          authProviders: [AuthProviderType.emailPassword],
        ),
      );
      final schema = PrismaSchemaGenerator().generate(config);

      expect(schema, contains('provider = "mysql"'));
    });

    test('includes custom data models', () {
      final config = BackendConfig.fromSettings(
        GeneratorSettings(
          projectName: 'test',
          generateBackend: true,
          database: DatabaseType.postgres,
          authProviders: [AuthProviderType.emailPassword],
        ),
        dataModels: [
          DataModel(
            name: 'Task',
            fields: [
              DataField(name: 'title', type: 'String', nullable: false),
              DataField(name: 'completed', type: 'bool', nullable: false),
              DataField(name: 'dueDate', type: 'DateTime', nullable: true),
            ],
          ),
        ],
      );
      final schema = PrismaSchemaGenerator().generate(config);

      expect(schema, contains('model Task {'));
      expect(schema, contains('title String'));
      expect(schema, contains('completed Boolean'));
      expect(schema, contains('dueDate DateTime?'));
    });

    test('includes all core models', () {
      final config = BackendConfig.fromSettings(
        GeneratorSettings(
          projectName: 'test',
          generateBackend: true,
          database: DatabaseType.postgres,
          authProviders: [AuthProviderType.emailPassword],
        ),
      );
      final schema = PrismaSchemaGenerator().generate(config);

      expect(schema, contains('model User {'));
      expect(schema, contains('model AuthAccount {'));
      expect(schema, contains('model Session {'));
      expect(schema, contains('model VerificationToken {'));
      expect(schema, contains('model PasswordResetToken {'));
      expect(schema, contains('model Project {'));
      expect(schema, contains('model ProjectMember {'));
    });
  });
}
