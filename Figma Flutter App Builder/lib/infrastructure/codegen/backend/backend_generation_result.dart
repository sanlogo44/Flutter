/// Result of a backend generation run.
library;

import '../project_generator.dart';

class BackendGenerationResult {
  BackendGenerationResult({
    required this.files,
    this.warnings = const [],
  });
  final List<GeneratedFile> files;
  final List<String> warnings;
}
