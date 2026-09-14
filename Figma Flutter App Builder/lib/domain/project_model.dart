library;

import 'models.dart';
import 'ui_node.dart';

export 'ui_node.dart' show UiNode, WidgetType, LayoutData, LayoutDirection, EdgeInsets, SizingMode, ColorValue, StyleData, TextData, WidgetConfiguration, ShadowData, GradientData, GradientStop;
export 'models.dart' show Variable, VariableScope, LogicNode, LogicCategory, LogicConnection, ComponentDef, ComponentParameter, NavRoute, ApiConfig, DataModel, DataField, DesignSystem, GeneratorSettings, DatabaseType, AuthProviderType, FigmaMetadata, ProjectPage;

/// The top-level project model that the builder edits, serializes and exports.

/// Represents a complete builder project.
///
/// This is the single source of truth for the editor. All UI mutations go
/// through [ProjectController], which holds an instance of this class and
/// supports undo/redo.
class ProjectModel {
  ProjectModel({
    String? id,
    required this.name,
    this.figmaMetadata,
    List<ProjectPage>? pages,
    List<ComponentDef>? components,
    DesignSystem? designSystem,
    List<Variable>? variables,
    List<LogicNode>? logicGraph,
    List<ApiConfig>? apiConfigs,
    List<NavRoute>? navigation,
    List<DataModel>? dataModels,
    required this.generatorSettings,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? '',
        pages = pages ?? [],
        components = components ?? [],
        designSystem = designSystem ?? DesignSystem(),
        variables = variables ?? [],
        logicGraph = logicGraph ?? [],
        apiConfigs = apiConfigs ?? [],
        navigation = navigation ?? [],
        dataModels = dataModels ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory ProjectModel.fromJson(Map<String, dynamic> json) => ProjectModel(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? 'Untitled Project',
        figmaMetadata: json['figmaMetadata'] != null
            ? FigmaMetadata.fromJson(
                json['figmaMetadata'] as Map<String, dynamic>)
            : null,
        pages: (json['pages'] as List<dynamic>? ?? [])
            .map((e) => ProjectPage.fromJson(e as Map<String, dynamic>))
            .toList(),
        components: (json['components'] as List<dynamic>? ?? [])
            .map((e) => ComponentDef.fromJson(e as Map<String, dynamic>))
            .toList(),
        designSystem: json['designSystem'] != null
            ? DesignSystem.fromJson(
                json['designSystem'] as Map<String, dynamic>)
            : null,
        variables: (json['variables'] as List<dynamic>? ?? [])
            .map((e) => Variable.fromJson(e as Map<String, dynamic>))
            .toList(),
        logicGraph: (json['logicGraph'] as List<dynamic>? ?? [])
            .map((e) => LogicNode.fromJson(e as Map<String, dynamic>))
            .toList(),
        apiConfigs: (json['apiConfigs'] as List<dynamic>? ?? [])
            .map((e) => ApiConfig.fromJson(e as Map<String, dynamic>))
            .toList(),
        navigation: (json['navigation'] as List<dynamic>? ?? [])
            .map((e) => NavRoute.fromJson(e as Map<String, dynamic>))
            .toList(),
        dataModels: (json['dataModels'] as List<dynamic>? ?? [])
            .map((e) => DataModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        generatorSettings: json['generatorSettings'] != null
            ? GeneratorSettings.fromJson(
                json['generatorSettings'] as Map<String, dynamic>)
            : GeneratorSettings(),
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : null,
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : null,
      );

  final String id;
  String name;
  FigmaMetadata? figmaMetadata;
  List<ProjectPage> pages;
  List<ComponentDef> components;
  DesignSystem designSystem;
  List<Variable> variables;
  List<LogicNode> logicGraph;
  List<ApiConfig> apiConfigs;
  List<NavRoute> navigation;
  List<DataModel> dataModels;
  GeneratorSettings generatorSettings;
  DateTime createdAt;
  DateTime updatedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (figmaMetadata != null) 'figmaMetadata': figmaMetadata!.toJson(),
        'pages': pages.map((e) => e.toJson()).toList(),
        'components': components.map((e) => e.toJson()).toList(),
        'designSystem': designSystem.toJson(),
        'variables': variables.map((e) => e.toJson()).toList(),
        'logicGraph': logicGraph.map((e) => e.toJson()).toList(),
        'apiConfigs': apiConfigs.map((e) => e.toJson()).toList(),
        'navigation': navigation.map((e) => e.toJson()).toList(),
        'dataModels': dataModels.map((e) => e.toJson()).toList(),
        'generatorSettings': generatorSettings.toJson(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  /// Create an empty default project with one home page.
  factory ProjectModel.empty() {
    final now = DateTime.now();
    return ProjectModel(
      id: '',
      name: 'New Project',
      pages: [
        ProjectPage(
          id: 'page_home',
          name: 'Home',
          root: UiNode(
            id: 'root',
            name: 'Scaffold',
            type: WidgetType.container,
            layout: LayoutData(direction: LayoutDirection.vertical),
          ),
          isHome: true,
        ),
      ],
      generatorSettings: GeneratorSettings(),
      createdAt: now,
      updatedAt: now,
    );
  }
}
