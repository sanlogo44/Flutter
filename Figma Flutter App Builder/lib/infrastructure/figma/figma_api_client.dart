/// HTTP client for the Figma REST API.
///
/// This client abstracts authentication and network calls so that the rest of
/// the builder never touches HTTP directly. It supports both Personal Access
/// Tokens (PAT) and OAuth bearer tokens. Secrets are never persisted by this
/// class – the caller is responsible for providing them at runtime.
library;

import 'dart:convert';
import 'package:http/http.dart' as http;

/// Hierarchy of errors thrown by the Figma API client.
sealed class FigmaApiError implements Exception {
  FigmaApiError(this.message);
  final String message;
  @override
  String toString() => '$runtimeType: $message';
}

class FigmaAuthError extends FigmaApiError {
  FigmaAuthError([super.message = 'Authentication failed. Check your Figma token.']);
}

class FigmaNetworkError extends FigmaApiError {
  FigmaNetworkError([super.message = 'Network error while contacting the Figma API.']);
}

class FigmaNotFoundError extends FigmaApiError {
  FigmaNotFoundError([super.message = 'The requested Figma file or node was not found.']);
}

class FigmaRateLimitError extends FigmaApiError {
  FigmaRateLimitError([super.message = 'Figma API rate limit exceeded.']);
}

class FigmaServerError extends FigmaApiError {
  FigmaServerError([super.message = 'Figma API returned a server error.']);
}

class FigmaUnknownError extends FigmaApiError {
  FigmaUnknownError(super.message);
}

/// Credentials supplied at runtime – never stored in source code.
class FigmaCredentials {
  FigmaCredentials({required this.accessToken});
  final String accessToken;
}

/// A node to fetch from a Figma file (by id or all top-level nodes).
class FigmaNodeFetch {
  FigmaNodeFetch({this.nodeId, this.depth});
  final String? nodeId;
  final int? depth;
}

/// Thin wrapper over the Figma REST API.
class FigmaApiClient {
  FigmaApiClient({
    this.baseUrl = 'https://api.figma.com/v1',
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  final String baseUrl;
  final http.Client _httpClient;

  void close() => _httpClient.close();

  /// Fetch a complete file (document tree + components + styles).
  ///
  /// Throws [FigmaApiError] subtypes on failure.
  Future<Map<String, dynamic>> getFile({
    required FigmaCredentials credentials,
    required String fileKey,
    FigmaNodeFetch? fetch,
  }) async {
    final params = <String, String>{};
    if (fetch?.nodeId != null) params['ids'] = fetch!.nodeId!;
    if (fetch?.depth != null) params['depth'] = fetch!.depth.toString();

    final uri = Uri.parse('$baseUrl/files/$fileKey')
        .replace(queryParameters: params.isNotEmpty ? params : null);

    try {
      final response = await _httpClient.get(
        uri,
        headers: {
          'X-Figma-Token': credentials.accessToken,
          'Accept': 'application/json',
        },
      );

      return _handleResponse(response);
    } on http.ClientException {
      throw FigmaNetworkError();
    }
  }

  /// Fetch images (PNG/SVG/JPG/PDF) for specific node IDs.
  Future<Map<String, dynamic>> getImages({
    required FigmaCredentials credentials,
    required String fileKey,
    required List<String> nodeIds,
    String format = 'png',
    int? scale,
  }) async {
    final params = {
      'ids': nodeIds.join(','),
      'format': format,
      if (scale != null) 'scale': scale.toString(),
    };
    final uri = Uri.parse('$baseUrl/images/$fileKey')
        .replace(queryParameters: params);

    try {
      final response = await _httpClient.get(
        uri,
        headers: {
          'X-Figma-Token': credentials.accessToken,
          'Accept': 'application/json',
        },
      );
      return _handleResponse(response);
    } on http.ClientException {
      throw FigmaNetworkError();
    }
  }

  /// Fetch user info (used to validate a token).
  Future<Map<String, dynamic>> getMe({
    required FigmaCredentials credentials,
  }) async {
    final uri = Uri.parse('$baseUrl/me');
    try {
      final response = await _httpClient.get(
        uri,
        headers: {
          'X-Figma-Token': credentials.accessToken,
          'Accept': 'application/json',
        },
      );
      return _handleResponse(response);
    } on http.ClientException {
      throw FigmaNetworkError();
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    final body = utf8.decode(response.bodyBytes);
    Map<String, dynamic>? json;
    try {
      json = body.isEmpty ? null : jsonDecode(body) as Map<String, dynamic>;
    } on FormatException {
      // Non-JSON response.
    }

    if (statusCode == 200 || statusCode == 201) {
      if (json == null) {
        throw FigmaUnknownError('Figma API returned an empty body.');
      }
      return json;
    }

    // Error responses.
    final figmaMessage = json?['err'] as String? ?? json?['message'] as String?;

    switch (statusCode) {
      case 401:
      case 403:
        throw FigmaAuthError(figmaMessage ?? 'Authentication failed');
      case 404:
        throw FigmaNotFoundError(figmaMessage ?? 'Resource not found');
      case 429:
        throw FigmaRateLimitError(figmaMessage ?? 'Rate limit exceeded');
      case 500:
      case 502:
      case 503:
        throw FigmaServerError(figmaMessage ?? 'Server error');
      default:
        throw FigmaUnknownError(
          'Figma API error $statusCode: ${figmaMessage ?? body}',
        );
    }
  }
}
