import 'package:flutter_test/flutter_test.dart';
import 'package:figma_flutter_builder/domain/project_model.dart';
import 'package:figma_flutter_builder/domain/ui_node.dart';
import 'package:figma_flutter_builder/infrastructure/validation/project_validator.dart';

void main() {
  group('ProjectValidator', () {
    test('passes for a valid project with one home page', () {
      final validator = ProjectValidator();
      final project = ProjectModel(
        name: 'Valid',
        pages: [
          ProjectPage(
            id: 'p1',
            name: 'Home',
            root: UiNode(
              id: 'root',
              name: 'Root',
              type: WidgetType.container,
            ),
            isHome: true,
          ),
        ],
        generatorSettings: GeneratorSettings(projectName: 'valid_app'),
      );

      final result = validator.validate(project);
      expect(result.hasErrors, isFalse);
    });

    test('errors when no pages exist', () {
      final validator = ProjectValidator();
      final project = ProjectModel(
        name: 'Empty',
        pages: [],
        generatorSettings: GeneratorSettings(projectName: 'empty_app'),
      );

      final result = validator.validate(project);
      expect(result.hasErrors, isTrue);
    });

    test('errors when multiple home pages exist', () {
      final validator = ProjectValidator();
      final project = ProjectModel(
        name: 'MultiHome',
        pages: [
          ProjectPage(
            id: 'p1',
            name: 'Home1',
            root: UiNode(id: 'r1', name: 'R', type: WidgetType.container),
            isHome: true,
          ),
          ProjectPage(
            id: 'p2',
            name: 'Home2',
            root: UiNode(id: 'r2', name: 'R', type: WidgetType.container),
            isHome: true,
          ),
        ],
        generatorSettings: GeneratorSettings(projectName: 'multi_app'),
      );

      final result = validator.validate(project);
      expect(result.hasErrors, isTrue);
    });

    test('errors when navigation references missing page', () {
      final validator = ProjectValidator();
      final project = ProjectModel(
        name: 'BrokenNav',
        pages: [
          ProjectPage(
            id: 'p1',
            name: 'Home',
            root: UiNode(id: 'r1', name: 'R', type: WidgetType.container),
            isHome: true,
          ),
        ],
        navigation: [
          NavRoute(id: 'n1', name: 'ToMissing', pageId: 'nonexistent'),
        ],
        generatorSettings: GeneratorSettings(projectName: 'nav_app'),
      );

      final result = validator.validate(project);
      expect(result.hasErrors, isTrue);
    });

    test('errors when API config has invalid method', () {
      final validator = ProjectValidator();
      final project = ProjectModel(
        name: 'BadApi',
        pages: [
          ProjectPage(
            id: 'p1',
            name: 'Home',
            root: UiNode(id: 'r1', name: 'R', type: WidgetType.container),
            isHome: true,
          ),
        ],
        apiConfigs: [
          ApiConfig(
            id: 'a1',
            name: 'Bad',
            method: 'FETCH',
            url: '/items',
          ),
        ],
        generatorSettings: GeneratorSettings(projectName: 'bad_api_app'),
      );

      final result = validator.validate(project);
      expect(result.hasErrors, isTrue);
    });

    test('warns when text node has no content', () {
      final validator = ProjectValidator();
      final project = ProjectModel(
        name: 'EmptyText',
        pages: [
          ProjectPage(
            id: 'p1',
            name: 'Home',
            root: UiNode(
              id: 'r1',
              name: 'Root',
              type: WidgetType.column,
              children: [
                UiNode(
                  id: 't1',
                  name: 'EmptyLabel',
                  type: WidgetType.text,
                  text: TextData(text: ''),
                ),
              ],
            ),
            isHome: true,
          ),
        ],
        generatorSettings: GeneratorSettings(projectName: 'empty_text_app'),
      );

      final result = validator.validate(project);
      expect(result.hasWarnings, isTrue);
    });
  });
}
