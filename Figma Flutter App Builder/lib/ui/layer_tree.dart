import 'package:flutter/material.dart';

import '../domain/project_model.dart' hide EdgeInsets;
import '../domain/ui_node.dart' hide EdgeInsets;

/// Left panel: shows the page list and the node hierarchy (layer tree).
class LayerTree extends StatelessWidget {
  const LayerTree({
    super.key,
    required this.project,
    required this.selectedPageId,
    required this.selectedNodeId,
    required this.onPageSelected,
    required this.onNodeSelected,
    required this.onAddPage,
  });

  final ProjectModel project;
  final String? selectedPageId;
  final String? selectedNodeId;
  final ValueChanged<String> onPageSelected;
  final ValueChanged<String> onNodeSelected;
  final void Function(String name) onAddPage;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Column(
        children: [
          // Pages header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Row(
              children: [
                const Text('Pages',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add, size: 18),
                  tooltip: 'Add Page',
                  onPressed: () => _showAddPageDialog(context),
                ),
              ],
            ),
          ),
          // Pages list
          ...project.pages.map((page) => ListTile(
                dense: true,
                selected: page.id == selectedPageId,
                leading: const Icon(Icons.description, size: 18),
                title: Text(page.name),
                onTap: () => onPageSelected(page.id),
              )),
          const Divider(height: 1),
          // Layer tree header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Text('Layers',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          // Node tree
          Expanded(
            child: project.pages.isEmpty
                ? const Center(child: Text('No pages'))
                : _NodeTreeList(
                    node: project.pages
                        .firstWhere(
                          (p) => p.id == selectedPageId,
                          orElse: () => project.pages.first,
                        )
                        .root,
                    selectedNodeId: selectedNodeId,
                    onSelected: onNodeSelected,
                    depth: 0,
                  ),
          ),
        ],
      ),
    );
  }

  void _showAddPageDialog(BuildContext context) {
    final nameController = TextEditingController(text: 'New Page');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Page'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Page Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                onAddPage(name);
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

/// Recursive node tree list.
class _NodeTreeList extends StatelessWidget {
  const _NodeTreeList({
    required this.node,
    required this.selectedNodeId,
    required this.onSelected,
    required this.depth,
  });

  final UiNode node;
  final String? selectedNodeId;
  final ValueChanged<String> onSelected;
  final int depth;

  @override
  Widget build(BuildContext context) {
    final isSelected = node.id == selectedNodeId;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => onSelected(node.id),
          child: Container(
            padding: EdgeInsets.only(left: 12.0 + depth * 16, right: 8),
            height: 28,
            color: isSelected
                ? Theme.of(context).colorScheme.primaryContainer
                : null,
            child: Row(
              children: [
                Icon(
                  _iconForType(node.type),
                  size: 14,
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    node.name,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : null,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!node.visible)
                  Icon(Icons.visibility_off,
                      size: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
        ...node.children.map((child) => _NodeTreeList(
              node: child,
              selectedNodeId: selectedNodeId,
              onSelected: onSelected,
              depth: depth + 1,
            )),
      ],
    );
  }

  IconData _iconForType(WidgetType type) {
    return switch (type) {
      WidgetType.text => Icons.text_fields,
      WidgetType.container => Icons.crop_square,
      WidgetType.column => Icons.view_column,
      WidgetType.row => Icons.table_rows,
      WidgetType.stack => Icons.layers,
      WidgetType.button => Icons.smart_button,
      WidgetType.iconButton => Icons.touch_app,
      WidgetType.textField => Icons.edit,
      WidgetType.image => Icons.image,
      WidgetType.card => Icons.credit_card,
      WidgetType.listView => Icons.list,
      WidgetType.gridView => Icons.grid_view,
      WidgetType.appBar => Icons.view_headline,
      WidgetType.divider => Icons.horizontal_rule,
      WidgetType.custom => Icons.extension,
      _ => Icons.widgets,
    };
  }
}
