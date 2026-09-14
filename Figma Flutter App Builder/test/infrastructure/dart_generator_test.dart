import 'package:flutter_test/flutter_test.dart';
import 'package:figma_flutter_builder/domain/ui_node.dart';
import 'package:figma_flutter_builder/domain/widget_model.dart';
import 'package:figma_flutter_builder/infrastructure/codegen/dart_generator.dart';

void main() {
  group('DartGenerator', () {
    test('renders a simple Text widget', () {
      final gen = DartGenerator();
      final widget = WidgetModel(
        widgetType: 'Text',
        properties: [
          WidgetProperty(name: '', value: "'Hello World'", isNamed: false),
        ],
      );
      final code = gen.renderWidget(widget);
      expect(code, contains('Text('));
      expect(code, contains("'Hello World'"));
    });

    test('renders a Container with child', () {
      final gen = DartGenerator();
      final child = WidgetModel(
        widgetType: 'Text',
        properties: [
          WidgetProperty(name: '', value: "'Label'", isNamed: false),
        ],
      );
      final widget = WidgetModel(
        widgetType: 'Container',
        properties: [
          WidgetProperty(name: 'padding', value: 'const EdgeInsets.all(16)'),
        ],
        children: [child],
      );
      final code = gen.renderWidget(widget);
      expect(code, contains('Container('));
      expect(code, contains('child:'));
      expect(code, contains('Text('));
    });

    test('renders multi-child widget with children list', () {
      final gen = DartGenerator();
      final a = WidgetModel(
        widgetType: 'Text',
        properties: [WidgetProperty(name: '', value: "'A'", isNamed: false)],
      );
      final b = WidgetModel(
        widgetType: 'Text',
        properties: [WidgetProperty(name: '', value: "'B'", isNamed: false)],
      );
      final widget = WidgetModel(
        widgetType: 'Column',
        children: [a, b],
      );
      final code = gen.renderWidget(widget);
      expect(code, contains('children: ['));
      expect(code, contains("'A'"));
      expect(code, contains("'B'"));
    });

    test('renders with comment', () {
      final gen = DartGenerator();
      final widget = WidgetModel(
        widgetType: 'SizedBox',
        comment: 'Spacer',
      );
      final code = gen.renderWidget(widget);
      expect(code, contains('// Spacer'));
    });
  });
}
