/// Orchestrates all backend generators and produces a complete backend project.
///
/// This is the main entry point for backend generation. It:
/// 1. Validates the configuration (supported providers)
/// 2. Calls each sub-generator
/// 3. Returns a [BackendGenerationResult] with all generated files
///
/// Integration: called by [ProjectGenerator] when `generateBackend` is true.
library;

import '../../../domain/models.dart' show GeneratorSettings, DataModel;
import '../project_generator.dart' show GeneratedFile;
import 'backend_config.dart';
import 'backend_generation_result.dart';
import 'prisma_schema_generator.dart';
import 'prisma_migration_generator.dart';
import 'package_json_generator.dart';
import 'typescript_backend_generator.dart';
import 'middleware_generator.dart';
import 'utils_generator.dart';
import 'auth_backend_generator.dart';
import 'auth_services_generator.dart';
import 'auth_routes_generator.dart';
import 'users_projects_generator.dart';
import 'openapi_generator.dart';
import 'flutter_api_client_generator.dart';

class BackendGenerator {
  BackendGenerator();

  BackendGenerationResult generate(
    GeneratorSettings settings, {
    List<DataModel>? dataModels,
  }) {
    final config = BackendConfig.fromSettings(settings, dataModels: dataModels);

    final files = <GeneratedFile>[];
    const backendDir = 'backend';

    // --- Config files ---
    files.add(GeneratedFile(
      path: '$backendDir/package.json',
      content: PackageJsonGenerator().generate(config),
    ));
    files.add(GeneratedFile(
      path: '$backendDir/tsconfig.json',
      content: TsConfigGenerator().generate(),
    ));
    files.add(GeneratedFile(
      path: '$backendDir/.env.example',
      content: EnvExampleGenerator().generate(config),
    ));
    files.add(GeneratedFile(
      path: '$backendDir/README.md',
      content: _generateReadme(config),
    ));

    // --- Prisma ---
    files.add(GeneratedFile(
      path: '$backendDir/prisma/schema.prisma',
      content: PrismaSchemaGenerator().generate(config),
    ));
    files.add(GeneratedFile(
      path: '$backendDir/prisma/migrations/0001_init/migration.sql',
      content: PrismaMigrationGenerator().generate(config),
    ));

    // --- Core TypeScript ---
    final tsGen = TypeScriptBackendGenerator();
    files.add(GeneratedFile(
      path: '$backendDir/src/main.ts',
      content: tsGen.mainTs(),
    ));
    files.add(GeneratedFile(
      path: '$backendDir/src/app.ts',
      content: tsGen.appTs(config),
    ));
    files.add(GeneratedFile(
      path: '$backendDir/src/config/env.ts',
      content: tsGen.envTs(config),
    ));
    files.add(GeneratedFile(
      path: '$backendDir/src/database/prisma.ts',
      content: tsGen.prismaTs(),
    ));

    // --- Utils ---
    final utilsGen = UtilsGenerator();
    files.add(GeneratedFile(
      path: '$backendDir/src/utils/logger.ts',
      content: utilsGen.logger(),
    ));
    files.add(GeneratedFile(
      path: '$backendDir/src/utils/health.ts',
      content: utilsGen.health(),
    ));

    // --- Middleware ---
    final mwGen = MiddlewareGenerator();
    files.add(GeneratedFile(
      path: '$backendDir/src/middleware/error-handler.ts',
      content: mwGen.errorHandler(),
    ));
    files.add(GeneratedFile(
      path: '$backendDir/src/middleware/security.ts',
      content: mwGen.security(),
    ));
    if (config.enableRateLimiting) {
      files.add(GeneratedFile(
        path: '$backendDir/src/middleware/rate-limit.ts',
        content: mwGen.rateLimit(),
      ));
    }
    files.add(GeneratedFile(
      path: '$backendDir/src/middleware/request-validation.ts',
      content: mwGen.requestValidation(),
    ));
    files.add(GeneratedFile(
      path: '$backendDir/src/middleware/auth.ts',
      content: mwGen.authMiddleware(),
    ));

    // --- Auth (only if any auth provider is enabled) ---
    if (config.hasAnyAuthProvider) {
      final authGen = AuthBackendGenerator();
      files.add(GeneratedFile(
        path: '$backendDir/src/auth/providers/auth-provider.ts',
        content: authGen.providerInterface(),
      ));

      if (config.hasEmailPassword) {
        files.add(GeneratedFile(
          path: '$backendDir/src/auth/providers/email-password.provider.ts',
          content: authGen.emailPasswordProvider(config),
        ));
      }

      // Auth services
      final servicesGen = AuthServicesGenerator();
      if (config.hasEmailPassword) {
        files.add(GeneratedFile(
          path: '$backendDir/src/auth/password.service.ts',
          content: servicesGen.passwordService(),
        ));
      }
      files.add(GeneratedFile(
        path: '$backendDir/src/auth/token.service.ts',
        content: servicesGen.tokenService(config),
      ));
      files.add(GeneratedFile(
        path: '$backendDir/src/auth/session.service.ts',
        content: servicesGen.sessionService(config),
      ));
      if (config.enableEmailVerification) {
        files.add(GeneratedFile(
          path: '$backendDir/src/auth/email-verification.service.ts',
          content: servicesGen.emailVerificationService(),
        ));
      }
      files.add(GeneratedFile(
        path: '$backendDir/src/auth/password-reset.service.ts',
        content: servicesGen.passwordResetService(),
      ));
      if (config.enableDisposableEmailProtection) {
        files.add(GeneratedFile(
          path: '$backendDir/src/auth/disposable-email.service.ts',
          content: servicesGen.disposableEmailService(),
        ));
      }

      // Auth routes
      final routesGen = AuthRoutesGenerator();
      files.add(GeneratedFile(
        path: '$backendDir/src/auth/auth.schemas.ts',
        content: routesGen.authSchemas(config),
      ));
      files.add(GeneratedFile(
        path: '$backendDir/src/auth/auth.controller.ts',
        content: routesGen.authController(config),
      ));
      files.add(GeneratedFile(
        path: '$backendDir/src/auth/auth.routes.ts',
        content: routesGen.authRoutes(config),
      ));
    }

    // --- Users module ---
    final upGen = UsersProjectsGenerator();
    files.add(GeneratedFile(
      path: '$backendDir/src/users/user.routes.ts',
      content: upGen.userRoutes(),
    ));
    files.add(GeneratedFile(
      path: '$backendDir/src/users/user.schemas.ts',
      content: upGen.userSchemas(),
    ));
    files.add(GeneratedFile(
      path: '$backendDir/src/users/user.controller.ts',
      content: upGen.userController(),
    ));

    // --- Projects module ---
    files.add(GeneratedFile(
      path: '$backendDir/src/projects/project.routes.ts',
      content: upGen.projectRoutes(),
    ));
    files.add(GeneratedFile(
      path: '$backendDir/src/projects/project.schemas.ts',
      content: upGen.projectSchemas(),
    ));
    files.add(GeneratedFile(
      path: '$backendDir/src/projects/project.controller.ts',
      content: upGen.projectController(),
    ));

    // --- OpenAPI ---
    files.add(GeneratedFile(
      path: '$backendDir/src/openapi/openapi.json',
      content: OpenApiGenerator().generate(config),
    ));

    // --- Flutter API Client (generated into the Flutter project) ---
    if (config.hasAnyAuthProvider) {
      final flutterGen = FlutterApiClientGenerator();
      files.add(GeneratedFile(
        path: 'lib/api/api_client.dart',
        content: flutterGen.apiClient(),
      ));
      files.add(GeneratedFile(
        path: 'lib/api/auth_models.dart',
        content: flutterGen.authModels(),
      ));
      files.add(GeneratedFile(
        path: 'lib/api/auth_api.dart',
        content: flutterGen.authApi(config),
      ));
      files.add(GeneratedFile(
        path: 'lib/api/auth_state.dart',
        content: flutterGen.authState(),
      ));
    }

    return BackendGenerationResult(files: files);
  }

  String _generateReadme(BackendConfig config) {
    final buf = StringBuffer();
    buf.writeln('# ${config.projectName} Backend');
    buf.writeln();
    buf.writeln('Generated backend for the ${config.projectName} Flutter app.');
    buf.writeln();
    buf.writeln('## Stack');
    buf.writeln('- Node.js + TypeScript');
    buf.writeln('- Express');
    buf.writeln('- Prisma ORM');
    buf.writeln('- PostgreSQL');
    buf.writeln();
    buf.writeln('## Setup');
    buf.writeln('```bash');
    buf.writeln('# Install dependencies');
    buf.writeln('npm install');
    buf.writeln();
    buf.writeln('# Copy env file');
    buf.writeln('cp .env.example .env');
    buf.writeln();
    buf.writeln('# Generate Prisma client');
    buf.writeln('npm run prisma:generate');
    buf.writeln();
    buf.writeln('# Run migrations');
    buf.writeln('npm run prisma:migrate');
    buf.writeln();
    buf.writeln('# Start dev server');
    buf.writeln('npm run dev');
    buf.writeln('```');
    buf.writeln();
    buf.writeln('## Auth Providers');
    for (final provider in config.authProviders) {
      buf.writeln('- ${provider.name}');
    }
    buf.writeln();
    if (config.enableRateLimiting) {
      buf.writeln('## Rate Limiting');
      buf.writeln('Enabled. Configurable via RATE_LIMIT_WINDOW_MS and RATE_LIMIT_MAX env vars.');
      buf.writeln();
    }
    if (config.enableDisposableEmailProtection) {
      buf.writeln('## Disposable Email Protection');
      buf.writeln('Enabled. Blocklist and allowlist configurable via env vars.');
      buf.writeln();
    }
    if (config.enableRefreshTokenRotation) {
      buf.writeln('## Refresh Token Rotation');
      buf.writeln('Enabled. Old refresh tokens are revoked on rotation.');
      buf.writeln();
    }
    buf.writeln('## Security');
    buf.writeln('- Passwords hashed with argon2id');
    buf.writeln('- JWT access + refresh tokens');
    buf.writeln('- Helmet security headers');
    buf.writeln('- CORS configuration');
    buf.writeln('- Zod request validation');
    buf.writeln('- Structured error handling');
    buf.writeln();

    return buf.toString();
  }
}
