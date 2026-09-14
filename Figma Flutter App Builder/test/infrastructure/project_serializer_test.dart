import 'package:flutter_test/flutter_test.dart';
import 'package:figma_flutter_builder/domain/project_model.dart';
import 'package:figma_flutter_builder/domain/ui_node.dart';
import 'package:figma_flutter_builder/infrastructure/persistence/project_serializer.dart';

void main() {
  group('ProjectSerializer', () {
    test('serializes and deserializes a project round-trip', () {
      final serializer = ProjectSerializer();
      final project = ProjectModel(
        name: 'Test Project',
        pages: [
          ProjectPage(
            id: 'page1',
            name: 'Home',
            root: UiNode(
              id: 'root1',
              name: 'Scaffold',
              type: WidgetType.container,
              children: [
                UiNode(
                  id: 'child1',
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

      final jsonStr = serializer.toJsonString(project);
      expect(jsonStr, contains('Test Project'));

      final restored = serializer.fromJsonString(jsonStr);
      expect(restored.name, 'Test Project');
      expect(restored.pages, hasLength(1));
      expect(restored.pages.first.name, 'Home');
      expect(restored.pages.first.root.children.first.text!.text, 'Welcome');
    });

    test('clones a project deeply', () {
      final serializer = ProjectSerializer();
      final project = ProjectModel(
        name: 'Clone Me',
        pages: [
          ProjectPage(
            id: 'p1',
            name: 'Page',
            root: UiNode(id: 'r1', name: 'Root', type: WidgetType.container),
          ),
        ],
        generatorSettings: GeneratorSettings(projectName: 'clone_app'),
      );

      final clone = serializer.clone(project);
      expect(clone.name, 'Clone Me');
      // Modifying clone should not affect original.
      clone.name = 'Modified';
      expect(project.name, 'Clone Me');
      expect(clone.name, 'Modified');
    });

    test('serializes empty project', () {
      final serializer = ProjectSerializer();
      final project = ProjectModel.empty();
      final jsonStr = serializer.toJsonString(project);
      final restored = serializer.fromJsonString(jsonStr);
      expect(restored.pages, hasLength(1));
      expect(restored.pages.first.isHome, isTrue);
    });
  });
}
