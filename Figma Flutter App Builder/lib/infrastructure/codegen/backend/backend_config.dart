/// Configuration derived from a [ProjectModel]'s [GeneratorSettings] that
/// controls which backend modules are generated.
///
/// Only enabled modules produce files, dependencies, routes, or environment
/// variables. Disabled providers leave no trace in the generated project.
library;

import '../../../domain/models.dart';

/// A fully resolved backend configuration.
class BackendConfig {
  BackendConfig({
    required this.projectName,
    required this.database,
    required this.authProviders,
    required this.enableEmailVerification,
    required this.enableDisposableEmailProtection,
    required this.enableRateLimiting,
    required this.enableRefreshTokenRotation,
    required this.dataModels,
  });

  factory BackendConfig.fromSettings(GeneratorSettings settings,
      {List<DataModel>? dataModels}) {
    // Validate that only supported providers are enabled.
    const supported = {
      AuthProviderType.emailPassword,
      AuthProviderType.magicLink,
      AuthProviderType.google,
      AuthProviderType.github,
      AuthProviderType.microsoft,
      AuthProviderType.apple,
      AuthProviderType.passkey,
      AuthProviderType.phoneOtp,
    };
    final unsupported = settings.authProviders.toSet().difference(supported);
    if (unsupported.isNotEmpty) {
      throw UnsupportedAuthProvidersException(unsupported.toList());
    }

    return BackendConfig(
      projectName: settings.projectName,
      database: settings.database,
      authProviders: List.unmodifiable(settings.authProviders),
      enableEmailVerification: settings.enableEmailVerification,
      enableDisposableEmailProtection:
          settings.enableDisposableEmailProtection,
      enableRateLimiting: settings.enableRateLimiting,
      enableRefreshTokenRotation: settings.enableRefreshTokenRotation,
      dataModels: List.unmodifiable(dataModels ?? []),
    );
  }

  final String projectName;
  final DatabaseType database;
  final List<AuthProviderType> authProviders;
  final bool enableEmailVerification;
  final bool enableDisposableEmailProtection;
  final bool enableRateLimiting;
  final bool enableRefreshTokenRotation;
  final List<DataModel> dataModels;

  bool get hasEmailPassword =>
      authProviders.contains(AuthProviderType.emailPassword);
  bool get hasMagicLink =>
      authProviders.contains(AuthProviderType.magicLink);
  bool get hasGoogle => authProviders.contains(AuthProviderType.google);
  bool get hasGithub => authProviders.contains(AuthProviderType.github);
  bool get hasMicrosoft =>
      authProviders.contains(AuthProviderType.microsoft);
  bool get hasApple => authProviders.contains(AuthProviderType.apple);
  bool get hasPasskey => authProviders.contains(AuthProviderType.passkey);
  bool get hasPhoneOtp => authProviders.contains(AuthProviderType.phoneOtp);

  bool get hasOAuthProvider => hasGoogle || hasGithub || hasMicrosoft || hasApple;
  bool get hasAnyAuthProvider => authProviders.isNotEmpty;
}

/// Thrown when the project enables auth providers that the generator does
/// not yet support.
class UnsupportedAuthProvidersException implements Exception {
  UnsupportedAuthProvidersException(this.providers);
  final List<AuthProviderType> providers;

  @override
  String toString() =>
      'Unsupported auth providers in current generator: '
      '${providers.map((p) => p.name).join(', ')}. '
      'Supported: emailPassword, magicLink (planned), google (planned), '
      'github (planned), microsoft (planned), apple (planned), '
      'passkey (planned), phoneOtp (planned). '
      'Disable unsupported providers or wait for future generator support.';
}
