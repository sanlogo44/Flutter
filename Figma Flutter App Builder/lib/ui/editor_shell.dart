import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../application/project_controller.dart';
import '../application/providers.dart';
import '../domain/project_model.dart' hide EdgeInsets;
import '../domain/ui_node.dart' hide EdgeInsets;
import 'toolbar.dart';
import 'layer_tree.dart';
import 'canvas.dart';
import 'inspector.dart';
import 'logic_editor.dart';
import 'code_preview.dart';
import 'command_palette.dart';

/// The main editor shell – a three-panel layout (Layer Tree | Canvas | Inspector)
/// with a toolbar on top and a bottom panel that can switch between Logic
/// Editor and Code Preview.
class EditorShell extends ConsumerStatefulWidget {
  const EditorShell({super.key});

  @override
  ConsumerState<EditorShell> createState() => _EditorShellState();
}

class _EditorShellState extends ConsumerState<EditorShell> {
  BottomPanelMode _bottomMode = BottomPanelMode.logic;
  String? _selectedPageId;
  String? _selectedNodeId;
  bool _commandPaletteOpen = false;

  @override
  void initState() {
    super.initState();
    final project = ref.read(projectControllerProvider).project;
    _selectedPageId = project.pages.isNotEmpty ? project.pages.first.id : null;
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(projectControllerProvider);
    final project = controller.project;
    final page = project.pages.firstWhere(
      (p) => p.id == _selectedPageId,
      orElse: () => project.pages.first,
    );
    final selectedNode = _selectedNodeId != null
        ? page.root.findById(_selectedNodeId!)
        : null;

    return KeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.keyK &&
              (HardwareKeyboard.instance.isControlPressed)) {
            setState(() => _commandPaletteOpen = true);
          } else if (event.logicalKey == LogicalKeyboardKey.keyZ &&
              (HardwareKeyboard.instance.isControlPressed)) {
            if (HardwareKeyboard.instance.isShiftPressed) {
              controller.redo();
            } else {
              controller.undo();
            }
          }
        }
      },
      child: Scaffold(
        body: Column(
          children: [
            Toolbar(
              onCommandPalette: () =>
                  setState(() => _commandPaletteOpen = true),
              onUndo: () => controller.undo(),
              onRedo: () => controller.redo(),
              canUndo: controller.undoRedo.canUndo,
              canRedo: controller.undoRedo.canRedo,
            ),
            Expanded(
              child: Row(
                children: [
                  // Left: Layer Tree
                  SizedBox(
                    width: 260,
                    child: LayerTree(
                      project: project,
                      selectedPageId: _selectedPageId,
                      selectedNodeId: _selectedNodeId,
                      onPageSelected: (id) =>
                          setState(() => _selectedPageId = id),
                      onNodeSelected: (id) =>
                          setState(() => _selectedNodeId = id),
                      onAddPage: (name) => controller.addPage(name),
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  // Center: Canvas
                  Expanded(
                    child: Canvas(
                      page: page,
                      selectedNodeId: _selectedNodeId,
                      onNodeSelected: (id) =>
                          setState(() => _selectedNodeId = id),
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  // Right: Inspector
                  SizedBox(
                    width: 300,
                    child: Inspector(
                      node: selectedNode,
                      pageId: page.id,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Bottom: Logic Editor or Code Preview
            SizedBox(
              height: 220,
              child: _bottomMode == BottomPanelMode.logic
                  ? LogicEditor(
                      project: project,
                      onSwitchToCode: () => setState(
                          () => _bottomMode = BottomPanelMode.code),
                    )
                  : CodePreview(
                      project: project,
                      onSwitchToLogic: () => setState(
                          () => _bottomMode = BottomPanelMode.logic),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

enum BottomPanelMode { logic, code }
