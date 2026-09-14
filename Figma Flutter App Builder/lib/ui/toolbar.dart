import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../domain/project_model.dart' hide EdgeInsets;
import '../domain/models.dart';
import '../application/project_controller.dart';
import '../application/providers.dart';

/// Top toolbar with global actions.
class Toolbar extends StatelessWidget {
  const Toolbar({
    super.key,
    required this.onCommandPalette,
    required this.onUndo,
    required this.onRedo,
    required this.canUndo,
    required this.canRedo,
  });

  final VoidCallback onCommandPalette;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final bool canUndo;
  final bool canRedo;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Row(
        children: [
          // Logo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.widgets,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                const Text(
                  'Figma Flutter Builder',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const VerticalDivider(),
          // Undo/Redo
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: 'Undo (Ctrl+Z)',
            onPressed: canUndo ? onUndo : null,
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            tooltip: 'Redo (Ctrl+Shift+Z)',
            onPressed: canRedo ? onRedo : null,
          ),
          const VerticalDivider(),
          // Import
          _ToolbarButton(
            icon: Icons.file_download,
            label: 'Import Figma',
            onTap: () => _showImportDialog(context),
          ),
          _ToolbarButton(
            icon: Icons.save,
            label: 'Save Project',
            onTap: () => _showSaveDialog(context),
          ),
          _ToolbarButton(
            icon: Icons.folder_open,
            label: 'Open Project',
            onTap: () => _showOpenDialog(context),
          ),
          const VerticalDivider(),
          _ToolbarButton(
            icon: Icons.code,
            label: 'Generate Code',
            onTap: () => _showGenerateDialog(context),
          ),
          _ToolbarButton(
            icon: Icons.download,
            label: 'Export',
            onTap: () => _showExportDialog(context),
          ),
          _ToolbarButton(
            icon: Icons.check_circle,
            label: 'Validate',
            onTap: () => _showValidationDialog(context),
          ),
          const Spacer(),
          // Command palette trigger
          TextButton.icon(
            onPressed: onCommandPalette,
            icon: const Icon(Icons.search, size: 16),
            label: const Text('Command Palette'),
          ),
          const Text(
            'Ctrl+K',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _showImportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const _ImportFigmaDialog(),
    );
  }

  void _showSaveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const _SaveProjectDialog(),
    );
  }

  void _showOpenDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const _OpenProjectDialog(),
    );
  }

  void _showGenerateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const _GenerateCodeDialog(),
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const _ExportDialog(),
    );
  }

  void _showValidationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const _ValidationDialog(),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

// Placeholder dialogs that wire into the controller.
class _ImportFigmaDialog extends StatelessWidget {
  const _ImportFigmaDialog();
  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (ctx, ref, _) {
        return AlertDialog(
          title: const Text('Import Figma File'),
          content: const _ImportFigmaForm(),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

class _ImportFigmaForm extends ConsumerStatefulWidget {
  const _ImportFigmaForm();
  @override
  ConsumerState<_ImportFigmaForm> createState() => _ImportFigmaFormState();
}

class _ImportFigmaFormState extends ConsumerState<_ImportFigmaForm> {
  final _urlController = TextEditingController();
  final _tokenController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _urlController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 400,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: 'Figma File URL or ID',
              hintText: 'https://www.figma.com/design/...',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _tokenController,
            decoration: const InputDecoration(
              labelText: 'Personal Access Token',
              helperText: 'Token is used only in-memory, never stored.',
            ),
            obscureText: true,
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _import,
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  Future<void> _import() async {
    setState(() => _error = null);
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() => _error = 'Please enter a Figma URL or file ID.');
      return;
    }
    // The actual import requires the Figma API client + credentials.
    // This is the integration point; the controller orchestrates the call.
    try {
      await ref
          .read(projectControllerProvider)
          .importFromFigma(
            fileUrlOrId: url,
            accessToken: _tokenController.text.trim(),
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = 'Import failed: $e');
    }
  }
}

class _SaveProjectDialog extends StatelessWidget {
  const _SaveProjectDialog();
  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (ctx, ref, _) {
        final controller = ref.read(projectControllerProvider);
        return AlertDialog(
          title: const Text('Save Project'),
          content: const Text(
              'Saves the current project as a .builder.json file.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await controller.saveProject();
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}

class _OpenProjectDialog extends StatelessWidget {
  const _OpenProjectDialog();
  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (ctx, ref, _) {
        final controller = ref.read(projectControllerProvider);
        return AlertDialog(
          title: const Text('Open Project'),
          content: const Text('Open a .builder.json project file.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await controller.loadProjectFromFile();
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Open'),
            ),
          ],
        );
      },
    );
  }
}

class _GenerateCodeDialog extends StatelessWidget {
  const _GenerateCodeDialog();
  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (ctx, ref, _) {
        final controller = ref.read(projectControllerProvider);
        return AlertDialog(
          title: const Text('Generate Flutter Code'),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Backend & Authentication Settings'),
                const SizedBox(height: 8),
                CheckboxListTile(
                  title: const Text('Generate Backend'),
                  value: controller.project.generatorSettings.generateBackend,
                  onChanged: (v) {
                    if (v != null) {
                      controller.project.generatorSettings.generateBackend = v;
                      ref.read(projectControllerProvider.notifier).state = controller;
                    }
                  },
                ),
                // Auth providers
                const Padding(
                  padding: EdgeInsets.only(left: 16, top: 8),
                  child: Text('Authentication'),
                ),
                ...AuthProviderType.values.map((provider) {
                  final enabled = controller
                      .project.generatorSettings.authProviders
                      .contains(provider);
                  return CheckboxListTile(
                    dense: true,
                    title: Text(provider.name),
                    value: enabled,
                    onChanged: (v) {
                      final settings = controller.project.generatorSettings;
                      if (v == true) {
                        settings.authProviders.add(provider);
                      } else {
                        settings.authProviders.remove(provider);
                      }
                      ref.read(projectControllerProvider.notifier).state = controller;
                    },
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                controller.generateCode();
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Generate'),
            ),
          ],
        );
      },
    );
  }
}

class _ExportDialog extends StatelessWidget {
  const _ExportDialog();
  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (ctx, ref, _) {
        final controller = ref.read(projectControllerProvider);
        return AlertDialog(
          title: const Text('Export Project'),
          content: const Text('Export as ZIP or to a folder.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await controller.exportToZip();
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Export ZIP'),
            ),
          ],
        );
      },
    );
  }
}

class _ValidationDialog extends StatelessWidget {
  const _ValidationDialog();
  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (ctx, ref, _) {
        final controller = ref.read(projectControllerProvider);
        final result = controller.validateProject();
        return AlertDialog(
          title: const Text('Validation'),
          content: SizedBox(
            width: 500,
            child: result.isOk
                ? const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 48),
                      SizedBox(height: 16),
                      Text('No errors found. Project is ready for export.'),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${result.issues.length} issue(s) found:',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...result.issues.map((issue) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(issue.toString()),
                          )),
                    ],
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
