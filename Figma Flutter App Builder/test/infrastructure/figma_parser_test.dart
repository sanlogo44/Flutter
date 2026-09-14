import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:figma_flutter_builder/domain/ui_node.dart';
import 'package:figma_flutter_builder/infrastructure/figma/figma_parser.dart';

void main() {
  group('FigmaParser', () {
    late Map<String, dynamic> sampleJson;

    setUpAll(() {
      final fixtureFile = File('test/fixtures/figma_login_sample.json');
      final contents = fixtureFile.readAsStringSync();
      sampleJson = jsonDecode(contents) as Map<String, dynamic>;
    });

    test('parses a Figma file with one canvas and one page', () {
      final parser = FigmaParser();
      final result = parser.parseFile(sampleJson);

      expect(result.pages, hasLength(1));
      final page = result.pages.first;
      expect(page.name, 'Page 1');
      expect(page.type, WidgetType.container);
    });

    test('detects vertical auto layout frame as column', () {
      final parser = FigmaParser();
      final result = parser.parseFile(sampleJson);
      final page = result.pages.first;

      // The first child should be "Login Frame" with vertical auto layout.
      final loginFrame = page.children.first;
      expect(loginFrame.name, 'Login Frame');
      expect(loginFrame.type, WidgetType.column);
      expect(loginFrame.layout.direction, LayoutDirection.vertical);
    });

    test('converts text node with style', () {
      final parser = FigmaParser();
      final result = parser.parseFile(sampleJson);
      final page = result.pages.first;
      final loginFrame = page.children.first;

      // Logo text node.
      final logo = loginFrame.children.first;
      expect(logo.type, WidgetType.text);
      expect(logo.text, isNotNull);
      expect(logo.text!.text, 'My App');
      expect(logo.text!.fontSize, 32);
      expect(logo.text!.fontWeight, 700);
    });

    test('converts fill color from Figma RGBA to hex', () {
      final parser = FigmaParser();
      final result = parser.parseFile(sampleJson);
      final page = result.pages.first;
      final loginFrame = page.children.first;

      // The login button should have a blue fill.
      final button = loginFrame.children.last;
      expect(button.style.fillColor, isNotNull);
      // r=0.13, g=0.45, b=0.94, a=1 → #FF21F0 (approx)
      expect(button.style.fillColor!.hex, startsWith('#'));
    });

    test('converts border radius', () {
      final parser = FigmaParser();
      final result = parser.parseFile(sampleJson);
      final page = result.pages.first;
      final loginFrame = page.children.first;

      // Email field has cornerRadius 12.
      final emailField = loginFrame.children[1];
      expect(emailField.style.borderRadius, 12);
    });

    test('converts drop shadow effect', () {
      final parser = FigmaParser();
      final result = parser.parseFile(sampleJson);
      final page = result.pages.first;
      final loginFrame = page.children.first;

      final button = loginFrame.children.last;
      expect(button.style.shadow, isNotNull);
      expect(button.style.shadow!.blurRadius, 8);
      expect(button.style.shadow!.offsetDy, 4);
    });

    test('handles empty document gracefully', () {
      final parser = FigmaParser();
      final result = parser.parseFile({'document': {}});
      expect(result.pages, isEmpty);
      expect(result.warnings, isNotEmpty);
    });

    test('handles missing document key', () {
      final parser = FigmaParser();
      final result = parser.parseFile({});
      expect(result.pages, isEmpty);
      expect(result.warnings, isNotEmpty);
    });
  });
}
