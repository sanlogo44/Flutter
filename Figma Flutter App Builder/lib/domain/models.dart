/// State, variable, logic graph, component, navigation, API and design-system
/// models that together form the full [ProjectModel].
library;

import 'ui_node.dart';

/// A typed variable in the project (app/page/component/local scope).
class Variable {
  Variable({
    required this.name,
    required this.type,
    this.value,
    this.scope = VariableScope.app,
  });

  factory Variable.fromJson(Map<String, dynamic> json) => Variable(
        name: json['name'] as String,
        type: json['type'] as String,
        value: json['value'],
        scope: VariableScope.values.firstWhere(
          (e) => e.name == (json['scope'] as String? ?? 'app'),
          orElse: () => VariableScope.app,
        ),
      );

  String name;
  String type; // 'String', 'int', 'double', 'bool', 'List', 'Map', custom
  dynamic value;
  VariableScope scope;

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type,
        'value': value,
        'scope': scope.name,
      };
}

enum VariableScope { app, page, component, local }

/// A logic node in the visual logic graph.
class LogicNode {
  LogicNode({
    required this.id,
    required this.type,
    required this.category,
    this.label,
    this.properties = const {},
    this.connections = const [],
  });

  factory LogicNode.fromJson(Map<String, dynamic> json) => LogicNode(
        id: json['id'] as String,
        type: json['type'] as String,
        category: LogicCategory.values.firstWhere(
          (e) => e.name == (json['category'] as String),
          orElse: () => LogicCategory.action,
        ),
        label: json['label'] as String?,
        properties: json['properties'] as Map<String, dynamic>? ?? {},
        connections: (json['connections'] as List<dynamic>? ?? [])
            .map((e) => LogicConnection.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  String id;
  String type; // e.g. 'onTap', 'navigate', 'if', 'apiRequest'
  LogicCategory category;
  String? label;
  Map<String, dynamic> properties;
  List<LogicConnection> connections;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'category': category.name,
        if (label != null) 'label': label,
        'properties': properties,
        'connections': connections.map((e) => e.toJson()).toList(),
      };
}

enum LogicCategory { event, action, logic, data }

class LogicConnection {
  LogicConnection({
    required this.fromId,
    required this.toId,
    this.label,
  });

  factory LogicConnection.fromJson(Map<String, dynamic> json) => LogicConnection(
        fromId: json['fromId'] as String,
        toId: json['toId'] as String,
        label: json['label'] as String?,
      );

  final String fromId;
  final String toId;
  final String? label;

  Map<String, dynamic> toJson() => {
        'fromId': fromId,
        'toId': toId,
        if (label != null) 'label': label,
      };
}

/// A reusable component definition.
class ComponentDef {
  ComponentDef({
    required this.id,
    required this.name,
    required this.rootNode,
    this.parameters = const [],
  });

  factory ComponentDef.fromJson(Map<String, dynamic> json) => ComponentDef(
        id: json['id'] as String,
        name: json['name'] as String,
        rootNode: UiNode.fromJson(json['rootNode'] as Map<String, dynamic>),
        parameters: (json['parameters'] as List<dynamic>? ?? [])
            .map((e) => ComponentParameter.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  String id;
  String name;
  UiNode rootNode;
  List<ComponentParameter> parameters;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'rootNode': rootNode.toJson(),
        'parameters': parameters.map((e) => e.toJson()).toList(),
      };
}

class ComponentParameter {
  ComponentParameter({
    required this.name,
    required this.type,
    this.defaultValue,
  });

  factory ComponentParameter.fromJson(Map<String, dynamic> json) =>
      ComponentParameter(
        name: json['name'] as String,
        type: json['type'] as String,
        defaultValue: json['defaultValue'],
      );

  String name;
  String type;
  dynamic defaultValue;

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type,
        'defaultValue': defaultValue,
      };
}

/// A navigation route in the app.
class NavRoute {
  NavRoute({
    required this.id,
    required this.name,
    required this.pageId,
    this.path,
    this.parentId,
  });

  factory NavRoute.fromJson(Map<String, dynamic> json) => NavRoute(
        id: json['id'] as String,
        name: json['name'] as String,
        pageId: json['pageId'] as String,
        path: json['path'] as String?,
        parentId: json['parentId'] as String?,
      );

  String id;
  String name;
  String pageId;
  String? path;
  String? parentId;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'pageId': pageId,
        if (path != null) 'path': path,
        if (parentId != null) 'parentId': parentId,
      };
}

/// A REST API endpoint configuration.
class ApiConfig {
  ApiConfig({
    required this.id,
    required this.name,
    required this.method,
    required this.url,
    this.headers = const {},
    this.queryParams = const {},
    this.body,
    this.responseModelName,
    this.authRequired = false,
  });

  factory ApiConfig.fromJson(Map<String, dynamic> json) => ApiConfig(
        id: json['id'] as String,
        name: json['name'] as String,
        method: json['method'] as String,
        url: json['url'] as String,
        headers: (json['headers'] as Map<String, dynamic>?) ?? {},
        queryParams: (json['queryParams'] as Map<String, dynamic>?) ?? {},
        body: json['body'],
        responseModelName: json['responseModelName'] as String?,
        authRequired: json['authRequired'] as bool? ?? false,
      );

  String id;
  String name;
  String method; // GET, POST, PUT, DELETE
  String url;
  Map<String, dynamic> headers;
  Map<String, dynamic> queryParams;
  dynamic body;
  String? responseModelName;
  bool authRequired;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'method': method,
        'url': url,
        'headers': headers,
        'queryParams': queryParams,
        if (body != null) 'body': body,
        if (responseModelName != null) 'responseModelName': responseModelName,
        'authRequired': authRequired,
      };
}

/// A generated data model (Dart class with fields).
class DataModel {
  DataModel({
    required this.name,
    required this.fields,
  });

  factory DataModel.fromJson(Map<String, dynamic> json) => DataModel(
        name: json['name'] as String,
        fields: (json['fields'] as List<dynamic>)
            .map((e) => DataField.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  String name;
  List<DataField> fields;

  Map<String, dynamic> toJson() => {
        'name': name,
        'fields': fields.map((e) => e.toJson()).toList(),
      };
}

class DataField {
  DataField({required this.name, required this.type, this.nullable = false});

  factory DataField.fromJson(Map<String, dynamic> json) => DataField(
        name: json['name'] as String,
        type: json['type'] as String,
        nullable: json['nullable'] as bool? ?? false,
      );

  String name;
  String type;
  bool nullable;

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type,
        'nullable': nullable,
      };
}

/// Design system tokens (colors, typography, spacing, etc.).
class DesignSystem {
  DesignSystem({
    this.colors = const {},
    this.typography = const {},
    this.spacing = const [],
    this.borderRadii = const [],
    this.shadows = const [],
  });

  factory DesignSystem.fromJson(Map<String, dynamic> json) => DesignSystem(
        colors: (json['colors'] as Map<String, dynamic>?) ?? {},
        typography: (json['typography'] as Map<String, dynamic>?) ?? {},
        spacing: (json['spacing'] as List<dynamic>? ?? [])
            .map((e) => (e as num).toDouble())
            .toList(),
        borderRadii: (json['borderRadii'] as List<dynamic>? ?? [])
            .map((e) => (e as num).toDouble())
            .toList(),
        shadows: (json['shadows'] as List<dynamic>? ?? [])
            .map((e) => ShadowData.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> colors; // name -> hex
  Map<String, dynamic> typography; // style name -> {fontFamily, fontSize, ...}
  List<double> spacing;
  List<double> borderRadii;
  List<ShadowData> shadows;

  Map<String, dynamic> toJson() => {
        'colors': colors,
        'typography': typography,
        'spacing': spacing,
        'borderRadii': borderRadii,
        'shadows': shadows.map((e) => e.toJson()).toList(),
      };
}

/// Settings that control the code generator and backend generator.
class GeneratorSettings {
  GeneratorSettings({
    this.projectName = 'my_flutter_app',
    this.generateBackend = false,
    this.database = DatabaseType.postgres,
    this.authProviders = const [],
    this.enableEmailVerification = false,
    this.enableDisposableEmailProtection = false,
    this.enableRateLimiting = false,
    this.enableRefreshTokenRotation = false,
    this.enableCharts = false,
    this.enableResponsive = true,
  });

  factory GeneratorSettings.fromJson(Map<String, dynamic> json) =>
      GeneratorSettings(
        projectName: json['projectName'] as String? ?? 'my_flutter_app',
        generateBackend: json['generateBackend'] as bool? ?? false,
        database: DatabaseType.values.firstWhere(
          (e) => e.name == (json['database'] as String? ?? 'postgres'),
          orElse: () => DatabaseType.postgres,
        ),
        authProviders: (json['authProviders'] as List<dynamic>? ?? [])
            .map((e) => AuthProviderType.values.firstWhere(
                  (a) => a.name == e,
                  orElse: () => AuthProviderType.emailPassword,
                ))
            .toList(),
        enableEmailVerification:
            json['enableEmailVerification'] as bool? ?? false,
        enableDisposableEmailProtection:
            json['enableDisposableEmailProtection'] as bool? ?? false,
        enableRateLimiting: json['enableRateLimiting'] as bool? ?? false,
        enableRefreshTokenRotation:
            json['enableRefreshTokenRotation'] as bool? ?? false,
        enableCharts: json['enableCharts'] as bool? ?? false,
        enableResponsive: json['enableResponsive'] as bool? ?? true,
      );

  String projectName;
  bool generateBackend;
  DatabaseType database;
  List<AuthProviderType> authProviders;
  bool enableEmailVerification;
  bool enableDisposableEmailProtection;
  bool enableRateLimiting;
  bool enableRefreshTokenRotation;
  bool enableCharts;
  bool enableResponsive;

  Map<String, dynamic> toJson() => {
        'projectName': projectName,
        'generateBackend': generateBackend,
        'database': database.name,
        'authProviders': authProviders.map((e) => e.name).toList(),
        'enableEmailVerification': enableEmailVerification,
        'enableDisposableEmailProtection': enableDisposableEmailProtection,
        'enableRateLimiting': enableRateLimiting,
        'enableRefreshTokenRotation': enableRefreshTokenRotation,
        'enableCharts': enableCharts,
        'enableResponsive': enableResponsive,
      };
}

enum DatabaseType { postgres, mysql, mongodb }
enum AuthProviderType {
  emailPassword,
  magicLink,
  google,
  github,
  microsoft,
  apple,
  passkey,
  phoneOtp,
}

/// Metadata about the Figma source of this project.
class FigmaMetadata {
  FigmaMetadata({this.fileId, this.fileName, this.fileUrl, this.lastSynced});

  factory FigmaMetadata.fromJson(Map<String, dynamic> json) => FigmaMetadata(
        fileId: json['fileId'] as String?,
        fileName: json['fileName'] as String?,
        fileUrl: json['fileUrl'] as String?,
        lastSynced: json['lastSynced'] as String?,
      );

  String? fileId;
  String? fileName;
  String? fileUrl;
  String? lastSynced;

  Map<String, dynamic> toJson() => {
        if (fileId != null) 'fileId': fileId,
        if (fileName != null) 'fileName': fileName,
        if (fileUrl != null) 'fileUrl': fileUrl,
        if (lastSynced != null) 'lastSynced': lastSynced,
      };
}

/// A page in the project (a top-level frame that becomes a Flutter page).
class ProjectPage {
  ProjectPage({
    required this.id,
    required this.name,
    required this.root,
    this.isHome = false,
  });

  factory ProjectPage.fromJson(Map<String, dynamic> json) => ProjectPage(
        id: json['id'] as String,
        name: json['name'] as String,
        root: UiNode.fromJson(json['root'] as Map<String, dynamic>),
        isHome: json['isHome'] as bool? ?? false,
      );

  String id;
  String name;
  UiNode root;
  bool isHome;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'root': root.toJson(),
        'isHome': isHome,
      };
}
