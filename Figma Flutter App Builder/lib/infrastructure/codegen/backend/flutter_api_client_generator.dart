/// Generates the Flutter API client files that connect the generated Flutter
/// app to the backend.
///
/// Files produced:
/// - api_client.dart: HTTP client with auth, retry, timeout, error handling
/// - auth_models.dart: request/response models for auth
/// - auth_api.dart: typed auth API methods
/// - auth_state.dart: auth state management
library;

import 'backend_config.dart';

class FlutterApiClientGenerator {
  FlutterApiClientGenerator();

  String apiClient() => '''import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

/// Generic API error with HTTP status code.
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, dynamic>? details;

  ApiException(this.statusCode, this.message, {this.details});

  @override
  String toString() => 'ApiException(\$statusCode): \$message';
}

/// Configuration for the API client.
class ApiClientConfig {
  final String baseUrl;
  final Duration timeout;
  final int maxRetries;

  const ApiClientConfig({
    required this.baseUrl,
    this.timeout = const Duration(seconds: 30),
    this.maxRetries = 3,
  });
}

/// Low-level HTTP client with auth token injection, timeout, and retry.
class ApiClient {
  final ApiClientConfig config;
  final http.Client _httpClient;

  String? _accessToken;
  String? _refreshToken;
  final void Function(String? accessToken, String? refreshToken)?
      onTokenUpdate;
  final Future<bool> Function()? onTokenExpired;

  ApiClient({
    required this.config,
    http.Client? httpClient,
    this.onTokenUpdate,
    this.onTokenExpired,
  }) : _httpClient = httpClient ?? http.Client();

  void setTokens({String? accessToken, String? refreshToken}) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    onTokenUpdate?.call(accessToken, refreshToken);
  }

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;

  Future<Map<String, dynamic>> get(String path,
      {Map<String, String>? query, bool requiresAuth = true}) {
    return _request('GET', path, query: query, requiresAuth: requiresAuth);
  }

  Future<Map<String, dynamic>> post(String path,
      {Map<String, dynamic>? body, bool requiresAuth = true}) {
    return _request('POST', path, body: body, requiresAuth: requiresAuth);
  }

  Future<Map<String, dynamic>> put(String path,
      {Map<String, dynamic>? body, bool requiresAuth = true}) {
    return _request('PUT', path, body: body, requiresAuth: requiresAuth);
  }

  Future<Map<String, dynamic>> delete(String path,
      {Map<String, dynamic>? body, bool requiresAuth = true}) {
    return _request('DELETE', path, body: body, requiresAuth: requiresAuth);
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
    bool requiresAuth = true,
  }) async {
    final uri = Uri.parse('\${config.baseUrl}\$path').replace(queryParameters: query);

    int attempts = 0;
    while (true) {
      attempts++;
      try {
        final headers = <String, String>{
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        };

        if (requiresAuth && _accessToken != null) {
          headers['Authorization'] = 'Bearer \$_accessToken';
        }

        final response = await _httpClient
            .send(http.Request(method, uri)
              ..headers.addAll(headers)
              ..body = body != null ? jsonEncode(body) : '')
            .timeout(config.timeout);

        // Handle 401 → try token refresh
        if (response.statusCode == 401 &&
            requiresAuth &&
            _refreshToken != null &&
            onTokenExpired != null &&
            attempts <= config.maxRetries) {
          final refreshed = await onTokenExpired!();
          if (refreshed) continue;
        }

        final responseBody = await response.stream.bytesToString();
        final json = responseBody.isNotEmpty
            ? jsonDecode(responseBody) as Map<String, dynamic>
            : <String, dynamic>{};

        if (response.statusCode >= 200 && response.statusCode < 300) {
          return json;
        }

        throw ApiException(
          response.statusCode,
          json['error'] as String? ?? 'Request failed',
          details: json['details'] as Map<String, dynamic>?,
        );
      } on TimeoutException {
        if (attempts > config.maxRetries) {
          throw ApiException(408, 'Request timed out');
        }
      } on http.ClientException {
        if (attempts > config.maxRetries) {
          rethrow;
        }
      }
    }
  }

  void dispose() {
    _httpClient.close();
  }
}
''';

  String authModels() => '''/// Data models for authentication requests and responses.

class AuthUser {
  final String id;
  final String email;
  final String? displayName;
  final String? avatarUrl;
  final DateTime? emailVerified;
  final DateTime? createdAt;

  AuthUser({
    required this.id,
    required this.email,
    this.displayName,
    this.avatarUrl,
    this.emailVerified,
    this.createdAt,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      emailVerified: json['emailVerified'] != null
          ? DateTime.parse(json['emailVerified'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    if (displayName != null) 'displayName': displayName,
    if (avatarUrl != null) 'avatarUrl': avatarUrl,
  };
}

class AuthResponse {
  final AuthUser user;
  final String accessToken;
  final String refreshToken;
  final int expiresIn;

  AuthResponse({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresIn: json['expiresIn'] as int,
    );
  }
}

class TokenResponse {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;

  TokenResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  factory TokenResponse.fromJson(Map<String, dynamic> json) {
    return TokenResponse(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresIn: json['expiresIn'] as int,
    );
  }
}
''';

  String authApi(BackendConfig config) {
    final methods = <String>[];

    if (config.hasEmailPassword) {
      methods.add('''
  /// Register a new user with email and password.
  Future<AuthResponse> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final json = await _client.post('/api/auth/register', body: {
      'email': email,
      'password': password,
      if (displayName != null) 'displayName': displayName,
    }, requiresAuth: false);
    return AuthResponse.fromJson(json);
  }
''');
      methods.add('''
  /// Login with email and password.
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final json = await _client.post('/api/auth/login', body: {
      'email': email,
      'password': password,
    }, requiresAuth: false);
    final response = AuthResponse.fromJson(json);
    _client.setTokens(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
    );
    return response;
  }
''');
    }

    methods.add('''
  /// Refresh the access token using a refresh token.
  Future<TokenResponse> refreshToken(String refreshToken) async {
    final json = await _client.post('/api/auth/refresh', body: {
      'refreshToken': refreshToken,
    }, requiresAuth: false);
    final response = TokenResponse.fromJson(json);
    _client.setTokens(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
    );
    return response;
  }
''');

    methods.add('''
  /// Logout (revoke current session).
  Future<void> logout(String refreshToken) async {
    await _client.post('/api/auth/logout', body: {
      'refreshToken': refreshToken,
    }, requiresAuth: false);
    _client.setTokens(accessToken: null, refreshToken: null);
  }
''');

    methods.add('''
  /// Get current user.
  Future<AuthUser> getCurrentUser() async {
    final json = await _client.get('/api/auth/me');
    return AuthUser.fromJson(json['user'] as Map<String, dynamic>);
  }
''');

    if (config.enableEmailVerification) {
      methods.add('''
  /// Verify email with token.
  Future<void> verifyEmail(String token) async {
    await _client.post('/api/auth/verify-email', body: {
      'token': token,
    }, requiresAuth: false);
  }
''');
    }

    methods.add('''
  /// Request a password reset email.
  Future<void> forgotPassword(String email) async {
    await _client.post('/api/auth/forgot-password', body: {
      'email': email,
    }, requiresAuth: false);
  }
''');

    methods.add('''
  /// Reset password with token.
  Future<void> resetPassword(String token, String newPassword) async {
    await _client.post('/api/auth/reset-password', body: {
      'token': token,
      'newPassword': newPassword,
    }, requiresAuth: false);
  }
''');

    methods.add('''
  /// Change password (requires authentication).
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    await _client.post('/api/auth/change-password', body: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }
''');

    return '''import 'api_client.dart';
import 'auth_models.dart';

/// Typed API methods for authentication.
class AuthApi {
  final ApiClient _client;

  AuthApi(this._client);

${methods.join('\n')}
}
''';
  }

  String authState() => '''import 'dart:async';
import 'api_client.dart';
import 'auth_models.dart';

/// Manages authentication state: token storage, refresh, and session restoration.
class AuthStateManager {
  final ApiClient _client;
  AuthUser? _currentUser;
  bool _isAuthenticated = false;

  final _authStateController = StreamController<AuthState>.broadcast();
  Stream<AuthState> get authState => _authStateController.stream;

  AuthUser? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;

  AuthStateManager(this._client) {
    _client.onTokenUpdate = (accessToken, refreshToken) {
      if (accessToken == null) {
        _currentUser = null;
        _isAuthenticated = false;
        _authStateController.add(AuthState.unauthenticated);
      }
    };
  }

  /// Initialize with stored tokens (call on app start).
  Future<void> initialize({
    required String? storedAccessToken,
    required String? storedRefreshToken,
  }) async {
    if (storedAccessToken != null && storedRefreshToken != null) {
      _client.setTokens(
        accessToken: storedAccessToken,
        refreshToken: storedRefreshToken,
      );

      try {
        _currentUser = await AuthApi(_client).getCurrentUser();
        _isAuthenticated = true;
        _authStateController.add(AuthState.authenticated(_currentUser!));
      } catch (_) {
        // Token might be expired, try refresh
        try {
          await _client.onTokenExpired?.call();
          _currentUser = await AuthApi(_client).getCurrentUser();
          _isAuthenticated = true;
          _authStateController.add(AuthState.authenticated(_currentUser!));
        } catch (_) {
          _isAuthenticated = false;
          _authStateController.add(AuthState.unauthenticated);
        }
      }
    } else {
      _authStateController.add(AuthState.unauthenticated);
    }
  }

  /// Called when the access token is used and might be expired.
  Future<bool> handleTokenExpiry() async {
    final refreshToken = _client.refreshToken;
    if (refreshToken == null) return false;

    try {
      final response = await AuthApi(_client).refreshToken(refreshToken);
      return true;
    } catch (_) {
      _currentUser = null;
      _isAuthenticated = false;
      _authStateController.add(AuthState.unauthenticated);
      return false;
    }
  }

  /// Set up the API client's token expiry handler.
  void configureTokenRefresh() {
    // Wire up the onTokenExpired callback
    // This is done via the constructor parameter in a real implementation
  }

  void dispose() {
    _authStateController.close();
  }
}

/// Authentication state.
sealed class AuthState {
  const AuthState();
}

class Authenticated extends AuthState {
  final AuthUser user;
  const Authenticated(this.user);
}

class Unauthenticated extends AuthState {
  const Unauthenticated();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}
''';
}
