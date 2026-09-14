import 'package:flutter_test/flutter_test.dart';
import 'package:figma_flutter_builder/domain/models.dart';
import 'package:figma_flutter_builder/domain/ui_node.dart';
import 'package:figma_flutter_builder/domain/project_model.dart';
import 'package:figma_flutter_builder/infrastructure/codegen/backend/backend_generator.dart';
import 'package:figma_flutter_builder/infrastructure/codegen/project_generator.dart';
import 'dart:io';

void main() {
  test('Generate sample backend and Flutter app', () {
    final settings = GeneratorSettings(
      projectName: 'SampleApp',
      generateBackend: true,
      database: DatabaseType.postgres,
      authProviders: const [AuthProviderType.emailPassword, AuthProviderType.google],
      enableEmailVerification: true,
      enableDisposableEmailProtection: true,
      enableRateLimiting: true,
      enableRefreshTokenRotation: true,
    );

    final root = UiNode(
      id: 'node1',
      name: 'Title',
      type: WidgetType.text,
      text: TextData(text: 'Welcome'),
    );

    final page = ProjectPage(
      id: 'page1',
      name: 'Home',
      root: root,
      isHome: true,
    );

    final project = ProjectModel(
      id: 'demo',
      name: 'Sample App',
      figmaMetadata: FigmaMetadata(fileId: 'sample'),
      pages: [page],
      designSystem: DesignSystem(),
      generatorSettings: settings,
    );

    // Generate full project (Flutter + Backend)
    print('\n=== Generating Project (Flutter + Backend) ===');
    final result = ProjectGenerator().generate(project);
    expect(result.files.isNotEmpty, true, reason: result.warnings.join('\n'));
    print('Generated: ${result.files.length} files');
    for (final file in result.files) {
      print('  ${file.path}');
    }

    // Copy backend/ to top-level
    print('\n=== Copying backend to top-level ===');
    final backendDir = Directory('backend');
    if (!backendDir.existsSync()) {
      backendDir.createSync();
    }

    // Find backend files in generated output and write them
    int backendCount = 0;
    for (final file in result.files) {
      if (file.path.startsWith('backend/')) {
        final outPath = file.path;
        final outFile = File(outPath);
        outFile.parent.createSync(recursive: true);
        outFile.writeAsStringSync(file.content);
        backendCount++;
      }
    }
    print('Backend files written: $backendCount');

    // Verify backend structure
    print('\n=== Backend directory structure ===');
    if (backendDir.existsSync()) {
      _listFiles(backendDir, '  ');
    }

    print('\n=== Done ===');
  });
}

void _listFiles(Directory dir, String prefix) {
  for (final entity in dir.listSync()) {
    if (entity is File) {
      print('$prefix${entity.path}');
    } else if (entity is Directory) {
      print('$prefix${entity.path}/');
      _listFiles(entity, '  $prefix');
    }
  }
}
