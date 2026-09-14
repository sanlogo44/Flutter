import 'package:flutter_test/flutter_test.dart';
import 'package:figma_flutter_builder/domain/project_model.dart';
import 'package:figma_flutter_builder/domain/ui_node.dart';
import 'package:figma_flutter_builder/infrastructure/codegen/project_generator.dart';

void main() {
  group('ProjectGenerator', () {
    test('generates pubspec.yaml', () {
      final gen = ProjectGenerator();
      final project = ProjectModel(
        name: 'My App',
        pages: [
          ProjectPage(
            id: 'p1',
            name: 'Home',
            root: UiNode(
              id: 'root',
              name: 'Scaffold',
              type: WidgetType.container,
              children: [
                UiNode(
                  id: 't1',
                  name: 'Title',
                  type: WidgetType.text,
                  text: TextData(text: 'Hello'),
                ),
              ],
            ),
            isHome: true,
          ),
        ],
        generatorSettings: GeneratorSettings(projectName: 'my_app'),
      );

      final result = gen.generate(project);

      final pubspec = result.files.firstWhere((f) => f.path == 'pubspec.yaml');
      expect(pubspec.content, contains('name: my_app'));
      expect(pubspec.content, contains('flutter'));
    });

    test('generates main.dart with app entry point', () {
      final gen = ProjectGenerator();
      final project = ProjectModel(
        name: 'Test',
        pages: [
          ProjectPage(
            id: 'p1',
            name: 'Home',
            root: UiNode(id: 'root', name: 'Root', type: WidgetType.container),
            isHome: true,
          ),
        ],
        generatorSettings: GeneratorSettings(projectName: 'test_app'),
      );

      final result = gen.generate(project);
      final mainDart = result.files.firstWhere((f) => f.path == 'lib/main.dart');
      expect(mainDart.content, contains('void main()'));
      expect(mainDart.content, contains('TestApp'));
    });

    test('generates a page file with widget tree', () {
      final gen = ProjectGenerator();
      final project = ProjectModel(
        name: 'Test',
        pages: [
          ProjectPage(
            id: 'p1',
            name: 'Home',
            root: UiNode(
              id: 'root',
              name: 'Scaffold',
              type: WidgetType.column,
              children: [
                UiNode(
                  id: 't1',
                  name: 'Title',
                  type: WidgetType.text,
                  text: TextData(text: 'Welcome'),
                ),
              ],
            ),
            isHome: true,
          ),
        ],
        generatorSettings: GeneratorSettings(projectName: 'test_app'),
      );

      final result = gen.generate(project);
      final pageFile =
          result.files.firstWhere((f) => f.path.contains('home_page.dart'));
      expect(pageFile.content, contains('class HomePage'));
      expect(pageFile.content, contains('Scaffold'));
    });

    test('generates API service when API configs exist', () {
      final gen = ProjectGenerator();
      final project = ProjectModel(
        name: 'Test',
        pages: [
          ProjectPage(
            id: 'p1',
            name: 'Home',
            root: UiNode(id: 'root', name: 'Root', type: WidgetType.container),
            isHome: true,
          ),
        ],
        apiConfigs: [
          ApiConfig(
            id: 'api1',
            name: 'Get Products',
            method: 'GET',
            url: '/products',
          ),
        ],
        generatorSettings: GeneratorSettings(projectName: 'test_app'),
      );

      final result = gen.generate(project);
      final hasApiService =
          result.files.any((f) => f.path == 'lib/services/api_service.dart');
      expect(hasApiService, isTrue);
    });

    test('generates assets directories', () {
      final gen = ProjectGenerator();
      final project = ProjectModel(
        name: 'Test',
        pages: [
          ProjectPage(
            id: 'p1',
            name: 'Home',
            root: UiNode(id: 'root', name: 'Root', type: WidgetType.container),
            isHome: true,
          ),
        ],
        generatorSettings: GeneratorSettings(projectName: 'test_app'),
      );

      final result = gen.generate(project);
      expect(result.files.any((f) => f.path.contains('assets/images/')), isTrue);
      expect(result.files.any((f) => f.path.contains('assets/icons/')), isTrue);
    });
  });
}
