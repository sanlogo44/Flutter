import 'package:flutter/material.dart';

import '../domain/project_model.dart' hide EdgeInsets;

/// Bottom panel: node-based logic editor for events, actions and conditions.
///
/// This is a visual representation of the [LogicNode] graph. In the full
/// implementation this will support drag-and-drop node creation, connection
/// drawing and execution. For now it renders the graph as a list.
class LogicEditor extends StatelessWidget {
  const LogicEditor({
    super.key,
    required this.project,
    required this.onSwitchToCode,
  });

  final ProjectModel project;
  final VoidCallback onSwitchToCode;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Column(
        children: [
          // Header
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Row(
              children: [
                const Text('Logic Editor',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 16),
                // Event types
                _Chip(label: 'Events'),
                _Chip(label: 'Actions'),
                _Chip(label: 'Conditions'),
                _Chip(label: 'Data'),
                const Spacer(),
                TextButton.icon(
                  onPressed: onSwitchToCode,
                  icon: const Icon(Icons.code, size: 16),
                  label: const Text('Code Preview'),
                ),
              ],
            ),
          ),
          // Node list / graph
          Expanded(
            child: project.logicGraph.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.account_tree,
                            size: 48, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('No logic nodes yet'),
                        const SizedBox(height: 8),
                        const Text(
                          'Add events, actions and conditions to define '
                          'behavior.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.add),
                          label: const Text('Add Event'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: project.logicGraph.length,
                    itemBuilder: (ctx, i) {
                      final node = project.logicGraph[i];
                      return Card(
                        child: ListTile(
                          leading: Icon(_iconForCategory(node.category)),
                          title: Text(node.label ?? node.type),
                          subtitle: Text(
                              'Category: ${node.category.name}\n'
                              'Connections: ${node.connections.length}'),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  IconData _iconForCategory(LogicCategory category) {
    return switch (category) {
      LogicCategory.event => Icons.touch_app,
      LogicCategory.action => Icons.play_arrow,
      LogicCategory.logic => Icons.call_split,
      LogicCategory.data => Icons.storage,
    };
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Chip(
        label: Text(label, style: const TextStyle(fontSize: 11)),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
