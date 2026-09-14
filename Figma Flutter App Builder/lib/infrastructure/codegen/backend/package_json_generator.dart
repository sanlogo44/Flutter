/// Generates package.json, tsconfig.json, and .env.example for the backend.
library;

import 'backend_config.dart';

class PackageJsonGenerator {
  PackageJsonGenerator();

  String generate(BackendConfig config) {
    final deps = <String, String>{
      '@prisma/client': '^5.20.0',
      'express': '^4.21.0',
      'cors': '^2.8.5',
      'helmet': '^8.0.0',
      'morgan': '^1.10.0',
      'zod': '^3.23.8',
      'jsonwebtoken': '^9.0.2',
      'uuid': '^10.0.0',
    };

    if (config.hasEmailPassword) {
      deps['argon2'] = '^0.41.1';
    }

    if (config.enableRateLimiting) {
      deps['express-rate-limit'] = '^7.4.1';
    }

    if (config.enableDisposableEmailProtection) {
      // No external dependency needed – uses internal blocklist.
    }

    if (config.hasOAuthProvider) {
      deps['dotenv'] = '^16.4.5';
    }

    final devDeps = <String, String>{
      'typescript': '^5.6.3',
      '@types/express': '^5.0.0',
      '@types/cors': '^2.8.17',
      '@types/morgan': '^1.9.9',
      '@types/jsonwebtoken': '^9.0.7',
      '@types/uuid': '^10.0.0',
      'prisma': '^5.20.0',
      'ts-node': '^10.9.2',
      '@types/node': '^22.7.5',
    };

    final buf = StringBuffer();
    buf.writeln('{');
    buf.writeln('  "name": "${config.projectName}-backend",');
    buf.writeln('  "version": "1.0.0",');
    buf.writeln('  "description": "Generated backend for ${config.projectName}",');
    buf.writeln('  "main": "dist/main.js",');
    buf.writeln('  "scripts": {');
    buf.writeln('    "dev": "ts-node src/main.ts",');
    buf.writeln('    "build": "tsc",');
    buf.writeln('    "start": "node dist/main.js",');
    buf.writeln('    "prisma:migrate": "prisma migrate dev",');
    buf.writeln('    "prisma:generate": "prisma generate",');
    buf.writeln('    "test": "jest"');
    buf.writeln('  },');
    buf.writeln('  "dependencies": {');
    final sortedDeps = deps.keys.toList()..sort();
    for (var i = 0; i < sortedDeps.length; i++) {
      final comma = i < sortedDeps.length - 1 ? ',' : '';
      buf.writeln('    "${sortedDeps[i]}": "${deps[sortedDeps[i]]}"$comma');
    }
    buf.writeln('  },');
    buf.writeln('  "devDependencies": {');
    final sortedDevDeps = devDeps.keys.toList()..sort();
    for (var i = 0; i < sortedDevDeps.length; i++) {
      final comma = i < sortedDevDeps.length - 1 ? ',' : '';
      buf.writeln('    "${sortedDevDeps[i]}": "${devDeps[sortedDevDeps[i]]}"$comma');
    }
    buf.writeln('  }');
    buf.writeln('}');

    return buf.toString();
  }
}

class TsConfigGenerator {
  TsConfigGenerator();

  String generate() {
    return '''{
  "compilerOptions": {
    "target": "ES2022",
    "module": "commonjs",
    "lib": ["ES2022"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["src/**/*.ts"],
  "exclude": ["node_modules", "dist", "tests"]
}
''';
  }
}

class EnvExampleGenerator {
  EnvExampleGenerator();

  String generate(BackendConfig config) {
    final buf = StringBuffer();
    buf.writeln('# Backend Environment Variables');
    buf.writeln('# Copy this file to .env and fill in real values.');
    buf.writeln('# NEVER commit the real .env file.');
    buf.writeln();
    buf.writeln('# Database');
    buf.writeln('DATABASE_URL="postgresql://user:password@localhost:5432/${config.projectName}?schema=public"');
    buf.writeln();
    buf.writeln('# JWT');
    buf.writeln('JWT_SECRET="change-me-to-a-very-long-random-string"');
    buf.writeln('JWT_EXPIRES_IN="15m"');
    buf.writeln('REFRESH_TOKEN_EXPIRES_IN="7d"');
    buf.writeln();
    buf.writeln('# Server');
    buf.writeln('PORT=3000');
    buf.writeln('NODE_ENV="development"');
    buf.writeln('CORS_ORIGIN="http://localhost:8080"');
    buf.writeln();

    if (config.enableRateLimiting) {
      buf.writeln('# Rate Limiting');
      buf.writeln('RATE_LIMIT_WINDOW_MS="900000"');
      buf.writeln('RATE_LIMIT_MAX="100"');
      buf.writeln();
    }

    if (config.enableDisposableEmailProtection) {
      buf.writeln('# Disposable Email Protection');
      buf.writeln('DISPOSABLE_EMAIL_BLOCKLIST_PATH="./config/disposable-domains.txt"');
      buf.writeln('DISPOSABLE_EMAIL_ALLOWLIST_PATH="./config/allowed-domains.txt"');
      buf.writeln();
    }

    if (config.hasEmailPassword) {
      buf.writeln('# Password Policy');
      buf.writeln('PASSWORD_MIN_LENGTH="8"');
      buf.writeln('PASSWORD_REQUIRE_UPPERCASE="true"');
      buf.writeln('PASSWORD_REQUIRE_LOWERCASE="true"');
      buf.writeln('PASSWORD_REQUIRE_NUMBER="true"');
      buf.writeln('PASSWORD_REQUIRE_SPECIAL="true"');
      buf.writeln();
    }

    if (config.hasOAuthProvider) {
      buf.writeln('# OAuth Providers');
      if (config.hasGoogle) {
        buf.writeln('GOOGLE_CLIENT_ID=""');
        buf.writeln('GOOGLE_CLIENT_SECRET=""');
        buf.writeln('GOOGLE_REDIRECT_URI="http://localhost:3000/auth/callback/google"');
      }
      if (config.hasGithub) {
        buf.writeln('GITHUB_CLIENT_ID=""');
        buf.writeln('GITHUB_CLIENT_SECRET=""');
        buf.writeln('GITHUB_REDIRECT_URI="http://localhost:3000/auth/callback/github"');
      }
      buf.writeln();
    }

    buf.writeln('# Email Service (for verification / reset / magic link)');
    buf.writeln('SMTP_HOST=""');
    buf.writeln('SMTP_PORT="587"');
    buf.writeln('SMTP_USER=""');
    buf.writeln('SMTP_PASSWORD=""');
    buf.writeln('FROM_EMAIL="noreply@example.com"');

    return buf.toString();
  }
}
