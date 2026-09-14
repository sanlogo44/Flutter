import 'package:flutter_test/flutter_test.dart';
import 'package:figma_flutter_builder/domain/ui_node.dart';
import 'package:figma_flutter_builder/domain/widget_model.dart';
import 'package:figma_flutter_builder/infrastructure/mapping/widget_mapper.dart';

void main() {
  group('WidgetMapper', () {
    test('maps text node to Text widget', () {
      final mapper = WidgetMapper();
      final node = UiNode(
        name: 'Label',
        type: WidgetType.text,
        text: TextData(text: 'Hello', fontSize: 16, fontWeight: 700),
      );
      final widget = mapper.map(node);

      expect(widget.widgetType, 'Text');
      expect(widget.properties, isNotEmpty);
      // First property should be positional (the text string).
      expect(widget.properties.first.isNamed, isFalse);
    });

    test('maps column node with spacing to Column with SizedBox spacers', () {
      final mapper = WidgetMapper();
      final node = UiNode(
        name: 'Col',
        type: WidgetType.column,
        layout: LayoutData(
          direction: LayoutDirection.vertical,
          spacing: 8,
        ),
        children: [
          UiNode(name: 'A', type: WidgetType.text, text: TextData(text: 'A')),
          UiNode(name: 'B', type: WidgetType.text, text: TextData(text: 'B')),
        ],
      );
      final widget = mapper.map(node);

      expect(widget.widgetType, 'Column');
      // 2 children + 1 spacer = 3
      expect(widget.children, hasLength(3));
      expect(widget.children[1].widgetType, 'SizedBox');
    });

    test('maps container with fill color and border radius', () {
      final mapper = WidgetMapper();
      final node = UiNode(
        name: 'Box',
        type: WidgetType.container,
        style: StyleData(
          fillColor: ColorValue('#FF0000FF'),
          borderRadius: 12,
        ),
      );
      final widget = mapper.map(node);

      expect(widget.widgetType, 'Container');
      // Should have a decoration property with borderRadius.
      final hasDecoration = widget.properties
          .any((p) => p.name == 'decoration');
      expect(hasDecoration, isTrue);
    });

    test('maps button with label and action', () {
      final mapper = WidgetMapper();
      final node = UiNode(
        name: 'Login',
        type: WidgetType.button,
        text: TextData(text: 'Login'),
        widgetConfiguration: WidgetConfiguration(
          widgetType: WidgetType.button,
          onTapAction: 'navigateToDashboard',
        ),
      );
      final widget = mapper.map(node);

      expect(widget.widgetType, 'ElevatedButton');
      expect(widget.children, isNotEmpty);
      expect(widget.children.first.widgetType, 'Text');
    });

    test('maps row with main axis alignment', () {
      final mapper = WidgetMapper();
      final node = UiNode(
        name: 'Row1',
        type: WidgetType.row,
        layout: LayoutData(
          direction: LayoutDirection.horizontal,
          mainAxisAlignment: 'center',
        ),
        children: [
          UiNode(name: 'A', type: WidgetType.text, text: TextData(text: 'A')),
        ],
      );
      final widget = mapper.map(node);

      expect(widget.widgetType, 'Row');
      final hasAlign = widget.properties
          .any((p) => p.name == 'mainAxisAlignment');
      expect(hasAlign, isTrue);
    });

    test('maps divider node', () {
      final mapper = WidgetMapper();
      final node = UiNode(name: 'Sep', type: WidgetType.divider);
      final widget = mapper.map(node);
      expect(widget.widgetType, 'Divider');
    });
  });
}
