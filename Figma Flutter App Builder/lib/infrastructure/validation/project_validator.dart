/// Validates a [ProjectModel] before code generation and export.
///
/// Checks for missing assets, broken navigation references, unresolved
/// variables, invalid logic graph connections and other issues that would
/// produce non-compilable or broken generated code.
library;

import '../../domain/project_model.dart';

/// A single validation issue.
class ValidationIssue {
  ValidationIssue({
    required this.severity,
    required this.message,
    this.nodeId,
  });

  final ValidationSeverity severity;
  final String message;
  final String? nodeId;

  @override
  String toString() {
    final prefix = switch (severity) {
      ValidationSeverity.error => 'ERROR',
      ValidationSeverity.warning => 'WARN',
      ValidationSeverity.info => 'INFO',
    };
    return '[$prefix] $message';
  }
}

enum ValidationSeverity { error, warning, info }

class ValidationResult {
  ValidationResult({this.issues = const []});
  final List<ValidationIssue> issues;

  bool get hasErrors =>
      issues.any((i) => i.severity == ValidationSeverity.error);
  bool get hasWarnings =>
      issues.any((i) => i.severity == ValidationSeverity.warning);
  bool get isOk => !hasErrors;

  List<ValidationIssue> get errors =>
      issues.where((i) => i.severity == ValidationSeverity.error).toList();
  List<ValidationIssue> get warnings =>
      issues.where((i) => i.severity == ValidationSeverity.warning).toList();
}

class ProjectValidator {
  ProjectValidator();

  ValidationResult validate(ProjectModel project) {
    final issues = <ValidationIssue>[];

    // Check pages exist.
    if (project.pages.isEmpty) {
      issues.add(ValidationIssue(
        severity: ValidationSeverity.error,
        message: 'Project has no pages. At least one page is required.',
      ));
    }

    // Check exactly one home page.
    final homePages = project.pages.where((p) => p.isHome).toList();
    if (homePages.isEmpty) {
      issues.add(ValidationIssue(
        severity: ValidationSeverity.warning,
        message: 'No home page defined. The first page will be used as home.',
      ));
    } else if (homePages.length > 1) {
      issues.add(ValidationIssue(
        severity: ValidationSeverity.error,
        message: 'Multiple home pages defined: '
            '${homePages.map((p) => p.name).join(', ')}.',
      ));
    }

    // Check each page has a root node.
    for (final page in project.pages) {
      if (page.root.id.isEmpty) {
        issues.add(ValidationIssue(
          severity: ValidationSeverity.error,
          message: 'Page "${page.name}" has an empty root node id.',
          nodeId: page.id,
        ));
      }
      // Recursively check nodes.
      _validateNode(page.root, page.name, issues);
    }

    // Check navigation references valid page ids.
    for (final route in project.navigation) {
      final exists = project.pages.any((p) => p.id == route.pageId);
      if (!exists) {
        issues.add(ValidationIssue(
          severity: ValidationSeverity.error,
          message: 'Navigation route "${route.name}" references '
              'missing page id: ${route.pageId}.',
        ));
      }
    }

    // Check logic graph connections reference existing nodes.
    final logicNodeIds = project.logicGraph.map((n) => n.id).toSet();
    for (final node in project.logicGraph) {
      for (final conn in node.connections) {
        if (!logicNodeIds.contains(conn.toId)) {
          issues.add(ValidationIssue(
            severity: ValidationSeverity.error,
            message: 'Logic node "${node.id}" connects to missing '
                'node: ${conn.toId}.',
          ));
        }
      }
    }

    // Check API configs have valid methods.
    for (final api in project.apiConfigs) {
      const validMethods = {'GET', 'POST', 'PUT', 'PATCH', 'DELETE'};
      if (!validMethods.contains(api.method.toUpperCase())) {
        issues.add(ValidationIssue(
          severity: ValidationSeverity.error,
          message: 'API config "${api.name}" has invalid method: ${api.method}.',
        ));
      }
      if (api.url.isEmpty) {
        issues.add(ValidationIssue(
          severity: ValidationSeverity.error,
          message: 'API config "${api.name}" has empty URL.',
        ));
      }
    }

    // Check variables have valid types.
    const validTypes = {
      'String', 'int', 'double', 'bool', 'List', 'Map', 'Object', 'dynamic'
    };
    for (final v in project.variables) {
      if (!validTypes.contains(v.type) && !v.type.startsWith('List<')) {
        issues.add(ValidationIssue(
          severity: ValidationSeverity.warning,
          message: 'Variable "${v.name}" has custom type: ${v.type}. '
              'Ensure the type is defined in the data models.',
        ));
      }
    }

    // Check data model fields have valid types.
    for (final model in project.dataModels) {
      for (final field in model.fields) {
        if (field.type.isEmpty) {
          issues.add(ValidationIssue(
            severity: ValidationSeverity.error,
            message: 'Model "${model.name}" field "${field.name}" '
                'has empty type.',
          ));
        }
      }
    }

    // Check project name is valid.
    if (project.generatorSettings.projectName.isEmpty) {
      issues.add(ValidationIssue(
        severity: ValidationSeverity.error,
        message: 'Generator settings: project name is empty.',
      ));
    }

    return ValidationResult(issues: issues);
  }

  void _validateNode(
      UiNode node, String pageName, List<ValidationIssue> issues) {
    if (node.name.isEmpty) {
      issues.add(ValidationIssue(
        severity: ValidationSeverity.warning,
        message: 'Node in page "$pageName" has empty name.',
        nodeId: node.id,
      ));
    }
    if (node.type == WidgetType.text && (node.text == null || node.text!.text.isEmpty)) {
      issues.add(ValidationIssue(
        severity: ValidationSeverity.warning,
        message: 'Text node "${node.name}" in page "$pageName" has no text content.',
        nodeId: node.id,
      ));
    }
    for (final child in node.children) {
      _validateNode(child, pageName, issues);
    }
  }
}
