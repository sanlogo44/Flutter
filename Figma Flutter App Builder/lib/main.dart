import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ui/editor_shell.dart';

void main() {
  runApp(const ProviderScope(child: FigmaFlutterBuilderApp()));
}

class FigmaFlutterBuilderApp extends StatelessWidget {
  const FigmaFlutterBuilderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Figma Flutter Builder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const EditorShell(),
    );
  }
}
