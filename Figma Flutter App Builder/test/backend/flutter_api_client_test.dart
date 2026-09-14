import 'package:flutter_test/flutter_test.dart';
import 'package:figma_flutter_builder/infrastructure/codegen/backend/backend_config.dart';
import 'package:figma_flutter_builder/infrastructure/codegen/backend/flutter_api_client_generator.dart';
import 'package:figma_flutter_builder/domain/models.dart';

void main() {
  group('FlutterApiClientGenerator', () {
    test('api_client.dart contains retry logic', () {
      final config = BackendConfig.fromSettings(
        GeneratorSettings(
          projectName: 'test',
          generateBackend: true,
          database: DatabaseType.postgres,
          authProviders: [AuthProviderType.emailPassword],
        ),
      );
      final code = FlutterApiClientGenerator().apiClient();

      expect(code, contains('class ApiClient'));
      expect(code, contains('maxRetries'));
      expect(code, contains('onTokenExpired'));
      expect(code, contains('TimeoutException'));
    });

    test('auth_models.dart contains AuthUser and AuthResponse', () {
      final code = FlutterApiClientGenerator().authModels();

      expect(code, contains('class AuthUser'));
      expect(code, contains('class AuthResponse'));
      expect(code, contains('class TokenResponse'));
      expect(code, contains('fromJson'));
    });

    test('auth_api.dart includes register and login when emailPassword is enabled', () {
      final config = BackendConfig.fromSettings(
        GeneratorSettings(
          projectName: 'test',
          generateBackend: true,
          database: DatabaseType.postgres,
          authProviders: [AuthProviderType.emailPassword],
        ),
      );
      final code = FlutterApiClientGenerator().authApi(config);

      expect(code, contains('Future<AuthResponse> register'));
      expect(code, contains('Future<AuthResponse> login'));
      expect(code, contains('Future<TokenResponse> refreshToken'));
      expect(code, contains('Future<void> logout'));
    });

    test('auth_api.dart does NOT include register/login when emailPassword is disabled', () {
      final config = BackendConfig.fromSettings(
        GeneratorSettings(
          projectName: 'test',
          generateBackend: true,
          database: DatabaseType.postgres,
          authProviders: [AuthProviderType.google],
        ),
      );
      final code = FlutterApiClientGenerator().authApi(config);

      expect(code, isNot(contains('register')));
      expect(code, isNot(contains('login')));
      // But should still have refresh and logout
      expect(code, contains('refreshToken'));
      expect(code, contains('logout'));
    });

    test('auth_state.dart contains AuthStateManager', () {
      final code = FlutterApiClientGenerator().authState();

      expect(code, contains('class AuthStateManager'));
      expect(code, contains('sealed class AuthState'));
      expect(code, contains('class Authenticated'));
      expect(code, contains('class Unauthenticated'));
    });

    test('auth_api.dart includes verifyEmail when email verification is enabled', () {
      final config = BackendConfig.fromSettings(
        GeneratorSettings(
          projectName: 'test',
          generateBackend: true,
          database: DatabaseType.postgres,
          authProviders: [AuthProviderType.emailPassword],
          enableEmailVerification: true,
        ),
      );
      final code = FlutterApiClientGenerator().authApi(config);

      expect(code, contains('verifyEmail'));
    });

    test('auth_api.dart does NOT include verifyEmail when email verification is disabled', () {
      final config = BackendConfig.fromSettings(
        GeneratorSettings(
          projectName: 'test',
          generateBackend: true,
          database: DatabaseType.postgres,
          authProviders: [AuthProviderType.emailPassword],
          enableEmailVerification: false,
        ),
      );
      final code = FlutterApiClientGenerator().authApi(config);

      expect(code, isNot(contains('verifyEmail')));
    });
  });
}
