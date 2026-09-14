/// Parses a Figma file URL or raw file ID into a normalized file key.
///
/// Supported inputs:
///   - https://www.figma.com/design/FILE_ID/Project-Name
///   - https://www.figma.com/file/FILE_ID/Project-Name
///   - https://www.figma.com/proto/FILE_ID/Project-Name
///   - FILE_ID (raw)
class FigmaLinkParser {
  FigmaLinkParser._();

  /// Extract the Figma file ID from a URL or raw string.
  ///
  /// Returns null if the input is empty or does not contain a valid file ID.
  /// Figma file IDs are URL-safe base64-like strings (typically 20+ chars).
  static String? parseFileId(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    // Try URL parsing first.
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      final uri = Uri.tryParse(trimmed);
      if (uri == null) return null;
      final segments = uri.pathSegments;
      // Expected: ['design', 'FILE_ID', 'Project-Name'] or ['file', 'FILE_ID', ...]
      if (segments.length >= 2) {
        final fileId = segments[1];
        if (_isValidFileId(fileId)) return fileId;
      }
      // Fallback: query param
      final queryId = uri.queryParameters['fileId'];
      if (queryId != null && _isValidFileId(queryId)) return queryId;
    }

    // Raw file ID.
    if (_isValidFileId(trimmed)) return trimmed;

    return null;
  }

  /// Extract an optional node-id query parameter (deep-link to a specific frame).
  static String? parseNodeId(String input) {
    final uri = Uri.tryParse(input);
    if (uri == null) return null;
    final nodeId = uri.queryParameters['node-id'];
    return nodeId;
  }

  static bool _isValidFileId(String id) {
    // Figma file IDs are alphanumeric with possible '-' and ':'.
    // Minimum length sanity check.
    if (id.length < 8) return false;
    final valid = RegExp(r'^[A-Za-z0-9\-:]+$');
    return valid.hasMatch(id);
  }
}
