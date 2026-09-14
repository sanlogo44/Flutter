import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/project_controller.dart';
import '../application/providers.dart';
import '../domain/ui_node.dart' hide EdgeInsets;

/// Right panel: property inspector for the selected node.
///
/// All changes go through the [ProjectController] so they are recorded in the
/// undo/redo stack and immediately reflected in the canvas.
class Inspector extends ConsumerWidget {
  const Inspector({
    super.key,
    required this.node,
    required this.pageId,
  });

  final UiNode? node;
  final String pageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(projectControllerProvider);

    if (node == null) {
      return Container(
        color: Theme.of(context).colorScheme.surfaceContainer,
        child: const Center(
          child: Text('No node selected',
              style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    final n = node!;
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // Name
          _Section(title: 'Node'),
          _TextField(
            label: 'Name',
            value: n.name,
            onChanged: (v) => controller.renameNode(pageId, n.id, v),
          ),
          // Type selector
          const SizedBox(height: 8),
          DropdownButtonFormField<WidgetType>(
            value: n.type,
            decoration: const InputDecoration(
              labelText: 'Widget Type',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            items: WidgetType.values
                .map((t) => DropdownMenuItem(
                      value: t,
                      child: Text(t.name),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) {
                controller.setNodeWidgetType(pageId, n.id, v);
              }
            },
          ),
          const Divider(),
          // Layout
          _Section(title: 'Layout'),
          const SizedBox(height: 8),
          DropdownButtonFormField<LayoutDirection>(
            value: n.layout.direction,
            decoration: const InputDecoration(
              labelText: 'Direction',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                  value: LayoutDirection.none, child: Text('None')),
              DropdownMenuItem(
                  value: LayoutDirection.horizontal, child: Text('Horizontal')),
              DropdownMenuItem(
                  value: LayoutDirection.vertical, child: Text('Vertical')),
            ],
            onChanged: (v) {
              if (v != null) {
                controller.setNodeLayoutDirection(pageId, n.id, v);
              }
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _TextField(
                  label: 'Padding Top',
                  value: n.layout.padding.top.toString(),
                  keyboardType: TextInputType.number,
                  onChanged: (v) {
                    final d = double.tryParse(v) ?? 0;
                    controller.setNodePadding(
                        pageId, n.id, d, d, d, d);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TextField(
                  label: 'Spacing',
                  value: n.layout.spacing.toString(),
                  keyboardType: TextInputType.number,
                  onChanged: (v) {
                    final d = double.tryParse(v) ?? 0;
                    controller.setNodeSpacing(pageId, n.id, d);
                  },
                ),
              ),
            ],
          ),
          const Divider(),
          // Style
          _Section(title: 'Style'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _TextField(
                  label: 'Border Radius',
                  value: n.style.borderRadius.toString(),
                  keyboardType: TextInputType.number,
                  onChanged: (v) {
                    final d = double.tryParse(v) ?? 0;
                    controller.setNodeBorderRadius(pageId, n.id, d);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TextField(
                  label: 'Opacity',
                  value: n.style.opacity.toString(),
                  keyboardType: TextInputType.number,
                  onChanged: (v) {
                    final d = double.tryParse(v) ?? 1;
                    controller.setNodeOpacity(pageId, n.id, d);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Fill color
          Row(
            children: [
              const Text('Fill:'),
              const SizedBox(width: 8),
              Expanded(
                child: _TextField(
                  label: 'Fill Color',
                  value: n.style.fillColor?.hex ?? '',
                  onChanged: (v) {
                    if (v.startsWith('#')) {
                      controller.setNodeFillColor(
                          pageId, n.id, ColorValue.parse(v));
                    }
                  },
                ),
              ),
            ],
          ),
          const Divider(),
          // Typography (for text nodes)
          if (n.type == WidgetType.text) ...[
            _Section(title: 'Typography'),
            const SizedBox(height: 8),
            _TextField(
              label: 'Text',
              value: n.text?.text ?? '',
              maxLines: 3,
              onChanged: (v) => controller.setNodeText(pageId, n.id, v),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _TextField(
                    label: 'Font Size',
                    value: n.text?.fontSize.toString() ?? '14',
                    keyboardType: TextInputType.number,
                    onChanged: (v) {
                      final d = double.tryParse(v) ?? 14;
                      controller.setNodeFontSize(pageId, n.id, d);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _TextField(
                    label: 'Font Weight',
                    value: n.text?.fontWeight.toString() ?? '400',
                    keyboardType: TextInputType.number,
                    onChanged: (v) {
                      final w = int.tryParse(v) ?? 400;
                      controller.setNodeFontWeight(pageId, n.id, w);
                    },
                  ),
                ),
              ],
            ),
            const Divider(),
          ],
          // Flutter
          _Section(title: 'Flutter'),
          const SizedBox(height: 8),
          _TextField(
            label: 'Key',
            value: n.widgetConfiguration?.key ?? '',
            onChanged: (v) {
              final cfg = n.widgetConfiguration ?? WidgetConfiguration(widgetType: n.type);
              cfg.key = v.isEmpty ? null : v;
              controller.setNodeWidgetConfig(pageId, n.id, cfg);
            },
          ),
          const SizedBox(height: 8),
          _TextField(
            label: 'On Tap Action',
            value: n.widgetConfiguration?.onTapAction ?? '',
            onChanged: (v) {
              final cfg = n.widgetConfiguration ?? WidgetConfiguration(widgetType: n.type);
              cfg.onTapAction = v.isEmpty ? null : v;
              controller.setNodeWidgetConfig(pageId, n.id, cfg);
            },
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.keyboardType,
    this.maxLines = 1,
  });
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: TextEditingController(text: value),
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: const OutlineInputBorder(),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
    );
  }
}
