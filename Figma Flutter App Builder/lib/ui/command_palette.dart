import 'package:flutter/material.dart';

/// Command palette (Ctrl+K) for quick access to all actions.
class CommandPalette extends StatelessWidget {
  const CommandPalette({
    super.key,
    required this.commands,
    required this.onClose,
  });

  final List<CommandItem> commands;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 600,
        height: 400,
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Type a command...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) {
                  // Filter handled by parent in a real implementation.
                },
              ),
            ),
            // Command list
            Expanded(
              child: ListView.builder(
                itemCount: commands.length,
                itemBuilder: (ctx, i) {
                  final cmd = commands[i];
                  return ListTile(
                    leading: Icon(cmd.icon),
                    title: Text(cmd.label),
                    subtitle: cmd.description != null
                        ? Text(cmd.description!)
                        : null,
                    onTap: () {
                      cmd.onExecute();
                      onClose();
                    },
                  );
                },
              ),
            ),
            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              child: Row(
                children: [
                  const Text('↑↓ Navigate  ↵ Execute  Esc Close',
                      style: TextStyle(fontSize: 11, color: Colors.grey)),
                  const Spacer(),
                  TextButton(
                    onPressed: onClose,
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CommandItem {
  CommandItem({
    required this.label,
    required this.icon,
    required this.onExecute,
    this.description,
    this.category = 'General',
  });

  final String label;
  final IconData icon;
  final VoidCallback onExecute;
  final String? description;
  final String category;
}
