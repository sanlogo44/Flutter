/// Exports a generated Flutter project to a ZIP archive or a folder.
library;

import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

import '../../domain/project_model.dart';
import '../codegen/project_generator.dart';

class ProjectExporter {
  ProjectExporter({ProjectGenerator? generator})
      : _generator = generator ?? ProjectGenerator();

  final ProjectGenerator _generator;

  /// Export the generated project to a ZIP file.
  Future<File> exportToZip(
    ProjectModel project,
    String outputPath,
  ) async {
    final result = _generator.generate(project);
    final archive = Archive();

    for (final file in result.files) {
      archive.addFile(
        ArchiveFile.string(file.path, file.content),
      );
    }

    final zipBytes = ZipEncoder().encode(archive);
    if (zipBytes == null) {
      throw Exception('Failed to encode ZIP archive.');
    }

    final file = File(outputPath);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(zipBytes);
    return file;
  }

  /// Export the generated project to a folder on disk.
  Future<Directory> exportToFolder(
    ProjectModel project,
    String outputDir,
  ) async {
    final result = _generator.generate(project);
    final dir = Directory(outputDir);
    await dir.create(recursive: true);

    for (final file in result.files) {
      final filePath = p.join(outputDir, file.path);
      final fileObj = File(filePath);
      await fileObj.parent.create(recursive: true);
      await fileObj.writeAsString(file.content);
    }

    return dir;
  }

  /// Get the list of generated files without writing to disk (for preview).
  List<GeneratedFile> preview(ProjectModel project) {
    return _generator.generate(project).files;
  }
}
