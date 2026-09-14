/// Central controller for the open project.
///
/// Holds the current [ProjectModel], exposes mutation methods and manages
/// undo/redo. All UI panels read from and write to this controller.
library;

import 'package:uuid/uuid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/project_model.dart';
import '../domain/ui_node.dart';
import '../infrastructure/figma/figma_link_parser.dart';
import '../infrastructure/figma/figma_api_client.dart';
import '../infrastructure/figma/figma_parser.dart';
import '../infrastructure/persistence/project_serializer.dart';
import '../infrastructure/persistence/project_exporter.dart';
import '../infrastructure/validation/project_validator.dart';
import '../infrastructure/codegen/project_generator.dart';
import 'undo_redo.dart';

class ProjectController {
  ProjectController({
    ProjectModel? project,
    UndoRedoStack? undoRedo,
  })  : _project = project ?? ProjectModel.empty(),
        _undoRedo = undoRedo ?? UndoRedoStack() {
    _undoRedo.reset(_project);
  }

  ProjectModel _project;
  final UndoRedoStack _undoRedo;
  final ProjectSerializer _serializer = ProjectSerializer();
  final FigmaApiClient _figmaClient = FigmaApiClient();
  final FigmaParser _figmaParser = FigmaParser();
  final ProjectValidator _validator = ProjectValidator();

  ProjectModel get project => _project;
  UndoRedoStack get undoRedo => _undoRedo;

  /// Replace the entire project (e.g. when opening a file).
  void loadProject(ProjectModel newProject) {
    _project = newProject;
    _undoRedo.reset(_project);
  }

  // --- Page operations ---

  /// Add a new page.
  void addPage(String name) {
    _undoRedo.pushState(_project);
    _project.pages.add(ProjectPage(
      id: const Uuid().v4(),
      name: name,
      root: UiNode(
        id: const Uuid().v4(),
        name: 'Scaffold',
        type: WidgetType.container,
        layout: LayoutData(direction: LayoutDirection.vertical),
      ),
    ));
    _project.updatedAt = DateTime.now();
  }

  /// Remove a page by id.
  void removePage(String pageId) {
    _undoRedo.pushState(_project);
    _project.pages.removeWhere((p) => p.id == pageId);
    _project.updatedAt = DateTime.now();
  }

  /// Rename a page.
  void renamePage(String pageId, String newName) {
    _undoRedo.pushState(_project);
    final page = _project.pages.firstWhere((p) => p.id == pageId);
    page.name = newName;
    _project.updatedAt = DateTime.now();
  }

  // --- Node operations ---

  /// Add a child node to a parent node in a specific page.
  void addNode(String pageId, String parentId, UiNode node) {
    _undoRedo.pushState(_project);
    final page = _project.pages.firstWhere((p) => p.id == pageId);
    final parent = page.root.findById(parentId) ?? page.root;
    parent.addChild(node);
    _project.updatedAt = DateTime.now();
  }

  /// Remove a node from a page.
  void removeNode(String pageId, String nodeId) {
    _undoRedo.pushState(_project);
    final page = _project.pages.firstWhere((p) => p.id == pageId);
    page.root.removeChild(nodeId);
    _project.updatedAt = DateTime.now();
  }

  /// Update a node's widget type.
  void setNodeWidgetType(String pageId, String nodeId, WidgetType type) {
    _undoRedo.pushState(_project);
    final page = _project.pages.firstWhere((p) => p.id == pageId);
    final node = page.root.findById(nodeId);
    if (node != null) {
      node.type = type;
      if (type != WidgetType.text) {
        node.text = null;
      }
      if (type == WidgetType.text && node.text == null) {
        node.text = TextData(text: 'Text');
      }
    }
    _project.updatedAt = DateTime.now();
  }

  /// Update a node's name.
  void renameNode(String pageId, String nodeId, String newName) {
    _undoRedo.pushState(_project);
    final page = _project.pages.firstWhere((p) => p.id == pageId);
    final node = page.root.findById(nodeId);
    if (node != null) {
      node.name = newName;
    }
    _project.updatedAt = DateTime.now();
  }

  /// Update a node's text content.
  void setNodeText(String pageId, String nodeId, String text) {
    _undoRedo.pushState(_project);
    final page = _project.pages.firstWhere((p) => p.id == pageId);
    final node = page.root.findById(nodeId);
    if (node != null) {
      if (node.text == null) {
        node.text = TextData(text: text);
      } else {
        node.text!.text = text;
      }
      node.type = WidgetType.text;
    }
    _project.updatedAt = DateTime.now();
  }

  /// Update a node's fill color.
  void setNodeFillColor(String pageId, String nodeId, ColorValue color) {
    _undoRedo.pushState(_project);
    final page = _project.pages.firstWhere((p) => p.id == pageId);
    final node = page.root.findById(nodeId);
    if (node != null) {
      node.style.fillColor = color;
    }
    _project.updatedAt = DateTime.now();
  }

  /// Update a node's border radius.
  void setNodeBorderRadius(String pageId, String nodeId, double radius) {
    _undoRedo.pushState(_project);
    final page = _project.pages.firstWhere((p) => p.id == pageId);
    final node = page.root.findById(nodeId);
    if (node != null) {
      node.style.borderRadius = radius;
    }
    _project.updatedAt = DateTime.now();
  }

  /// Update a node's layout direction.
  void setNodeLayoutDirection(
      String pageId, String nodeId, LayoutDirection direction) {
    _undoRedo.pushState(_project);
    final page = _project.pages.firstWhere((p) => p.id == pageId);
    final node = page.root.findById(nodeId);
    if (node != null) {
      node.layout.direction = direction;
      node.type = switch (direction) {
        LayoutDirection.horizontal => WidgetType.row,
        LayoutDirection.vertical => WidgetType.column,
        LayoutDirection.none => WidgetType.container,
      };
    }
    _project.updatedAt = DateTime.now();
  }

  /// Set a node's widget configuration (typing it as a specific Flutter widget).
  void setNodeWidgetConfig(
      String pageId, String nodeId, WidgetConfiguration config) {
    _undoRedo.pushState(_project);
    final page = _project.pages.firstWhere((p) => p.id == pageId);
    final node = page.root.findById(nodeId);
    if (node != null) {
      node.widgetConfiguration = config;
    }
    _project.updatedAt = DateTime.now();
  }

  // --- Undo/Redo ---

  bool undo() {
    final prev = _undoRedo.undo(_project);
    if (prev != null) {
      _project = prev;
      return true;
    }
    return false;
  }

  bool redo() {
    final next = _undoRedo.redo(_project);
    if (next != null) {
      _project = next;
      return true;
    }
    return false;
  }

  // --- Additional node property setters ---

  void setNodePadding(String pageId, String nodeId, double top, double right,
      double bottom, double left) {
    _undoRedo.pushState(_project);
    final page = _project.pages.firstWhere((p) => p.id == pageId);
    final node = page.root.findById(nodeId);
    if (node != null) {
      node.layout.padding = EdgeInsets.fromLTRB(left, top, right, bottom);
    }
    _project.updatedAt = DateTime.now();
  }

  void setNodeSpacing(String pageId, String nodeId, double spacing) {
    _undoRedo.pushState(_project);
    final page = _project.pages.firstWhere((p) => p.id == pageId);
    final node = page.root.findById(nodeId);
    if (node != null) {
      node.layout.spacing = spacing;
    }
    _project.updatedAt = DateTime.now();
  }

  void setNodeOpacity(String pageId, String nodeId, double opacity) {
    _undoRedo.pushState(_project);
    final page = _project.pages.firstWhere((p) => p.id == pageId);
    final node = page.root.findById(nodeId);
    if (node != null) {
      node.style.opacity = opacity;
    }
    _project.updatedAt = DateTime.now();
  }

  void setNodeFontSize(String pageId, String nodeId, double size) {
    _undoRedo.pushState(_project);
    final page = _project.pages.firstWhere((p) => p.id == pageId);
    final node = page.root.findById(nodeId);
    if (node != null && node.text != null) {
      node.text!.fontSize = size;
    }
    _project.updatedAt = DateTime.now();
  }

  void setNodeFontWeight(String pageId, String nodeId, int weight) {
    _undoRedo.pushState(_project);
    final page = _project.pages.firstWhere((p) => p.id == pageId);
    final node = page.root.findById(nodeId);
    if (node != null && node.text != null) {
      node.text!.fontWeight = weight;
    }
    _project.updatedAt = DateTime.now();
  }

  // --- Figma import ---

  Future<void> importFromFigma({
    required String fileUrlOrId,
    required String accessToken,
  }) async {
    final fileId = FigmaLinkParser.parseFileId(fileUrlOrId);
    if (fileId == null) {
      throw Exception('Could not parse a valid Figma file ID from input.');
    }
    if (accessToken.isEmpty) {
      throw Exception('A Figma access token is required for import.');
    }

    final credentials = FigmaCredentials(accessToken: accessToken);
    final fileJson = await _figmaClient.getFile(
      credentials: credentials,
      fileKey: fileId,
    );

    final result = _figmaParser.parseFile(fileJson);
    if (result.pages.isEmpty) {
      throw Exception('No pages found in Figma file.');
    }

    _undoRedo.pushState(_project);

    // Replace pages with imported ones.
    _project.pages.clear();
    for (var i = 0; i < result.pages.length; i++) {
      final pageNode = result.pages[i];
      _project.pages.add(ProjectPage(
        id: pageNode.id,
        name: pageNode.name,
        root: pageNode,
        isHome: i == 0,
      ));
    }
    _project.figmaMetadata = FigmaMetadata(
      fileId: fileId,
      fileUrl: fileUrlOrId.startsWith('http') ? fileUrlOrId : null,
      lastSynced: DateTime.now().toIso8601String(),
    );
    _project.updatedAt = DateTime.now();
    _undoRedo.reset(_project);
  }

  // --- Persistence ---

  Future<void> saveProject() async {
    // In a real app this would open a file save dialog.
    // For now, we serialize to the project's working directory.
    await _serializer.saveToFile(_project, 'project.builder.json');
  }

  Future<void> loadProjectFromFile() async {
    // In a real app this would open a file picker.
    // For now, we load from the default path.
    final loaded = await _serializer.loadFromFile('project.builder.json');
    loadProject(loaded);
  }

  // --- Code generation & export ---

  void generateCode() {
    final gen = ProjectGenerator();
    _generatedFiles = gen.generate(_project).files;
  }

  List<GeneratedFile>? _generatedFiles;
  List<GeneratedFile>? get generatedFiles => _generatedFiles;

  Future<void> exportToZip() async {
    final exporter = ProjectExporter();
    await exporter.exportToZip(_project, 'output.zip');
  }

  // --- Validation ---

  ValidationResult validateProject() {
    return _validator.validate(_project);
  }
}
