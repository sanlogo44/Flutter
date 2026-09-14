import 'package:flutter/material.dart';

import '../domain/ui_node.dart' hide EdgeInsets;
import '../domain/project_model.dart' hide EdgeInsets;

/// Center panel: a visual, interactive preview of the widget tree.
///
/// This is the editor preview – it renders the [UiNode] tree using Flutter
/// widgets directly (not generated code), so the user sees immediate updates.
class Canvas extends StatelessWidget {
  const Canvas({
    super.key,
    required this.page,
    required this.selectedNodeId,
    required this.onNodeSelected,
  });

  final ProjectPage page;
  final String? selectedNodeId;
  final ValueChanged<String> onNodeSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          // Canvas toolbar
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Row(
              children: [
                Text('Canvas – ${page.name}',
                    style: const TextStyle(fontSize: 12)),
                const Spacer(),
                const Icon(Icons.zoom_out, size: 16),
                const SizedBox(width: 4),
                const Text('100%', style: TextStyle(fontSize: 11)),
                const SizedBox(width: 4),
                const Icon(Icons.zoom_in, size: 16),
              ],
            ),
          ),
          // Canvas area with scrollable preview
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: Theme.of(context).dividerColor),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: _renderNode(context, page.root, isRoot: true),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _renderNode(BuildContext context, UiNode node,
      {bool isRoot = false}) {
    final isSelected = node.id == selectedNodeId;

    Widget content;

    switch (node.type) {
      case WidgetType.text:
        content = Text(
          node.text?.text ?? node.name,
          style: TextStyle(
            fontSize: node.text?.fontSize,
            fontWeight: node.text?.fontWeight != null
                ? FontWeight.values.firstWhere(
                    (w) => w.index == (node.text!.fontWeight ~/ 100).clamp(0, 8),
                    orElse: () => FontWeight.normal,
                  )
                : null,
            color: _color(context, node.text?.color),
          ),
          textAlign: node.text?.textAlign == 'center'
              ? TextAlign.center
              : TextAlign.left,
        );
        break;
      case WidgetType.row:
        final children = node.children
            .map((c) => _renderNode(context, c))
            .toList();
        content = Row(
          mainAxisAlignment: _mainAxis(node.layout.mainAxisAlignment),
          crossAxisAlignment: _crossAxis(node.layout.crossAxisAlignment),
          children: children,
        );
        break;
      case WidgetType.column:
        final children = node.children
            .map((c) => _renderNode(context, c))
            .toList();
        content = Column(
          mainAxisAlignment: _mainAxis(node.layout.mainAxisAlignment),
          crossAxisAlignment: _crossAxis(node.layout.crossAxisAlignment),
          children: children,
        );
        break;
      case WidgetType.stack:
        content = Stack(
          children: node.children.map((c) => _renderNode(context, c)).toList(),
        );
        break;
      case WidgetType.button:
        content = ElevatedButton(
          onPressed: () {},
          child: Text(node.text?.text ?? node.widgetConfiguration?.label ?? 'Button'),
        );
        break;
      case WidgetType.textField:
        content = TextField(
          decoration: InputDecoration(
            hintText: node.text?.text ?? node.name,
          ),
        );
        break;
      case WidgetType.divider:
        content = const Divider();
        break;
      default:
        // Container fallback
        final children = node.children
            .map((c) => _renderNode(context, c))
            .toList();
        if (children.isEmpty) {
          content = SizedBox(
            width: node.width,
            height: node.height,
          );
        } else if (children.length == 1) {
          content = children.first;
        } else {
          content = Column(children: children);
        }
    }

    // Wrap with container for styling.
    if (node.style.fillColor != null ||
        node.style.borderRadius > 0 ||
        node.style.borderColor != null) {
      content = Container(
        decoration: BoxDecoration(
          color: _color(context, node.style.fillColor),
          borderRadius: node.style.borderRadius > 0
              ? BorderRadius.circular(node.style.borderRadius)
              : null,
          border: node.style.borderColor != null
              ? Border.all(color: _color(context, node.style.borderColor)!)
              : null,
        ),
        padding: EdgeInsets.only(
          left: node.layout.padding.left,
          top: node.layout.padding.top,
          right: node.layout.padding.right,
          bottom: node.layout.padding.bottom,
        ),
        child: content,
      );
    }

    // Selection highlight.
    if (isSelected && !isRoot) {
      content = Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        child: content,
      );
    }

    // Make selectable.
    return GestureDetector(
      onTap: () => onNodeSelected(node.id),
      child: content,
    );
  }

  Color? _color(BuildContext context, ColorValue? colorValue) {
    if (colorValue == null) return null;
    final hex = colorValue.hex.replaceAll('#', '');
    if (hex.length == 8) {
      return Color(int.parse('0x$hex'));
    } else if (hex.length == 6) {
      return Color(int.parse('0xFF$hex'));
    }
    return null;
  }

  MainAxisAlignment _mainAxis(String? value) {
    return switch (value) {
      'center' => MainAxisAlignment.center,
      'end' => MainAxisAlignment.end,
      'spaceBetween' => MainAxisAlignment.spaceBetween,
      'spaceAround' => MainAxisAlignment.spaceAround,
      'spaceEvenly' => MainAxisAlignment.spaceEvenly,
      _ => MainAxisAlignment.start,
    };
  }

  CrossAxisAlignment _crossAxis(String? value) {
    return switch (value) {
      'start' => CrossAxisAlignment.start,
      'end' => CrossAxisAlignment.end,
      'stretch' => CrossAxisAlignment.stretch,
      _ => CrossAxisAlignment.center,
    };
  }
}
