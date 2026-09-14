import 'package:flutter/material.dart';

import '../domain/project_model.dart' hide EdgeInsets;
import '../infrastructure/codegen/project_generator.dart';

/// Bottom panel: shows a preview of the generated Dart code.
///
/// Renders a file tree on the left and the code content on the right.
class CodePreview extends StatefulWidget {
  const CodePreview({
    super.key,
    required this.project,
    required this.onSwitchToLogic,
  });

  final ProjectModel project;
  final VoidCallback onSwitchToLogic;

  @override
  State<CodePreview> createState() => _CodePreviewState();
}

class _CodePreviewState extends State<CodePreview> {
  String? _selectedFile;
  List<GeneratedFile>? _files;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  void _generate() {
    final gen = ProjectGenerator();
    final result = gen.generate(widget.project);
    _files = result.files;
    if (_files!.isNotEmpty) {
      _selectedFile = _files!.first.path;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_files == null || _files!.isEmpty) {
      return const Center(child: Text('No code generated'));
    }

    final selectedContent = _files!
        .firstWhere((f) => f.path == _selectedFile,
            orElse: () => _files!.first)
        .content;

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
                const Text('Code Preview',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton.icon(
                  onPressed: widget.onSwitchToLogic,
                  icon: const Icon(Icons.account_tree, size: 16),
                  label: const Text('Logic Editor'),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 16),
                  tooltip: 'Regenerate',
                  onPressed: () {
                    _generate();
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                // File tree
                SizedBox(
                  width: 220,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _files!.length,
                    itemBuilder: (ctx, i) {
                      final file = _files![i];
                      final isSelected = file.path == _selectedFile;
                      return ListTile(
                        dense: true,
                        selected: isSelected,
                        leading: Icon(
                          file.path.endsWith('.dart')
                              ? Icons.code
                              : file.path.endsWith('.yaml')
                                  ? Icons.settings
                                  : Icons.description,
                          size: 16,
                        ),
                        title: Text(
                          file.path.split('/').last,
                          style: const TextStyle(fontSize: 12),
                        ),
                        subtitle: Text(
                          file.path,
                          style: const TextStyle(fontSize: 10),
                        ),
                        onTap: () => setState(() => _selectedFile = file.path),
                      );
                    },
                  ),
                ),
                const VerticalDivider(width: 1),
                // Code view
                Expanded(
                  child: Container(
                    color: const Color(0xFF1E1E1E),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: SelectableText(
                            selectedContent,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 13,
                              color: Color(0xFFD4D4D4),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
