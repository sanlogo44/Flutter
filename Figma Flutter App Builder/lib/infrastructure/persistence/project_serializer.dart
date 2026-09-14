/// Serializes and deserializes a [ProjectModel] to/from JSON.
///
/// The builder project format is a single JSON document (`.builder.json`)
/// that captures the complete editor state including the UI tree, components,
/// styles, variables, logic graph, API configs and generator settings.
library;

import 'dart:convert';
import 'dart:io';

import '../../domain/project_model.dart';

class ProjectSerializer {
  ProjectSerializer();

  /// Serialize a project to a JSON string.
  String toJsonString(ProjectModel project) {
    return const JsonEncoder.withIndent('  ').convert(project.toJson());
  }

  /// Deserialize a project from a JSON string.
  ProjectModel fromJsonString(String jsonStr) {
    final json = jsonDecode(jsonStr) as Map<String, dynamic>;
    return ProjectModel.fromJson(json);
  }

  /// Save a project to a `.builder.json` file.
  Future<File> saveToFile(ProjectModel project, String filePath) async {
    final file = File(filePath);
    final dir = file.parent;
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return file.writeAsString(toJsonString(project));
  }

  /// Load a project from a `.builder.json` file.
  Future<ProjectModel> loadFromFile(String filePath) async {
    final file = File(filePath);
    final contents = await file.readAsString();
    return fromJsonString(contents);
  }

  /// Create a deep copy of a project (for undo/redo snapshots).
  ProjectModel clone(ProjectModel project) {
    return fromJsonString(toJsonString(project));
  }
}
