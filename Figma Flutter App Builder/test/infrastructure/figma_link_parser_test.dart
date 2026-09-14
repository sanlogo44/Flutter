import 'package:flutter_test/flutter_test.dart';
import 'package:figma_flutter_builder/infrastructure/figma/figma_link_parser.dart';

void main() {
  group('FigmaLinkParser', () {
    test('parses design URL with file ID', () {
      const url =
          'https://www.figma.com/design/ABC123xyz/My-Project-Name';
      final id = FigmaLinkParser.parseFileId(url);
      expect(id, 'ABC123xyz');
    });

    test('parses file URL with file ID', () {
      const url = 'https://www.figma.com/file/DEF456uvw/ProjectName';
      final id = FigmaLinkParser.parseFileId(url);
      expect(id, 'DEF456uvw');
    });

    test('parses proto URL with file ID', () {
      const url = 'https://www.figma.com/proto/GHI789rst/Prototype';
      final id = FigmaLinkParser.parseFileId(url);
      expect(id, 'GHI789rst');
    });

    test('parses raw file ID', () {
      const raw = 'JKLMNOPqrs';
      final id = FigmaLinkParser.parseFileId(raw);
      expect(id, 'JKLMNOPqrs');
    });

    test('returns null for empty input', () {
      expect(FigmaLinkParser.parseFileId(''), isNull);
      expect(FigmaLinkParser.parseFileId('   '), isNull);
    });

    test('returns null for invalid input', () {
      expect(FigmaLinkParser.parseFileId('short'), isNull);
    });

    test('extracts node-id from URL query', () {
      const url =
          'https://www.figma.com/design/ABC123/Name?node-id=1:2';
      final nodeId = FigmaLinkParser.parseNodeId(url);
      expect(nodeId, '1:2');
    });
  });
}
