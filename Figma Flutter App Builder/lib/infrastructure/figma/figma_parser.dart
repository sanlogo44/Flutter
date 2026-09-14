/// Converts a Figma API JSON document into the internal [UiNode] tree.
///
/// This is the bridge between the Figma-specific representation
/// ([FigmaNode]) and the source-independent internal model ([UiNode]).
/// The mapping is intentionally decoupled so other design sources can
/// target the same [UiNode] model later.
library;

import 'package:collection/collection.dart';

import '../../domain/figma/figma_node.dart';
import '../../domain/ui_node.dart';

class FigmaParseResult {
  FigmaParseResult({required this.pages, this.warnings = const []});
  final List<UiNode> pages;
  final List<String> warnings;
}

/// Maps a Figma file JSON (the `/v1/files/:key` response) to [UiNode] pages.
///
/// Top-level canvases in Figma become pages; each top-level FRAME on a canvas
/// becomes a [UiNode] subtree. The parser applies heuristics (e.g. detecting
/// auto-layout → Row/Column) and records warnings for unsupported nodes.
class FigmaParser {
  FigmaParser();

  /// Parse the full Figma file response.
  ///
  /// `fileJson` should be the decoded JSON map returned by the Figma API.
  FigmaParseResult parseFile(Map<String, dynamic> fileJson) {
    final warnings = <String>[];
    final doc = fileJson['document'];
    final document = doc is Map<String, dynamic> ? doc : null;
    if (document == null) {
      warnings.add('No "document" key found in Figma file JSON.');
      return FigmaParseResult(pages: [], warnings: warnings);
    }

    final canvases = (document['children'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .where((c) => c['type'] == 'CANVAS')
        .toList();

    if (canvases.isEmpty) {
      warnings.add('No canvases found in Figma document.');
      return FigmaParseResult(pages: [], warnings: warnings);
    }

    final pages = <UiNode>[];
    for (final canvas in canvases) {
      final canvasNode = FigmaNode.fromJson(canvas);
      final pageNode = UiNode(
        id: canvasNode.id,
        name: canvasNode.name,
        type: WidgetType.container,
        layout: LayoutData(direction: LayoutDirection.vertical),
        originFigmaId: canvasNode.id,
      );
      for (final child in canvasNode.children) {
        final uiChild = _convertNode(child, warnings);
        if (uiChild != null) {
          pageNode.addChild(uiChild);
        }
      }
      pages.add(pageNode);
    }

    return FigmaParseResult(pages: pages, warnings: warnings);
  }

  /// Recursively convert a [FigmaNode] into a [UiNode].
  UiNode? _convertNode(FigmaNode node, List<String> warnings) {
    if (!node.visible) {
      // Keep invisible nodes but mark them – useful for round-tripping.
    }

    final uiNode = UiNode(
      id: node.id,
      name: node.name,
      width: node.width,
      height: node.height,
      rotation: node.rotation,
      visible: node.visible,
      originFigmaId: node.id,
      layout: _convertLayout(node),
      style: _convertStyle(node),
    );

    // Type-specific data.
    switch (node.type) {
      case FigmaNodeType.text:
        uiNode.type = WidgetType.text;
        uiNode.text = _convertText(node);
        break;
      case FigmaNodeType.rectangle:
        uiNode.type = WidgetType.container;
        break;
      case FigmaNodeType.ellipse:
        uiNode.type = WidgetType.container;
        break;
      case FigmaNodeType.frame:
      case FigmaNodeType.group:
      case FigmaNodeType.component:
      case FigmaNodeType.componentSet:
      case FigmaNodeType.instance:
      case FigmaNodeType.section:
        uiNode.type = _inferContainerType(node);
        break;
      case FigmaNodeType.vector:
      case FigmaNodeType.line:
        uiNode.type = WidgetType.divider;
        break;
      case FigmaNodeType.polygon:
      case FigmaNodeType.star:
        uiNode.type = WidgetType.custom;
        warnings.add('Node "${node.name}" (${node.type.name}) requires a '
            'CustomPainter for full fidelity.');
        break;
      case FigmaNodeType.booleanOperation:
        uiNode.type = WidgetType.custom;
        warnings.add('Boolean operation "${node.name}" requires vector '
            'reconstruction.');
        break;
      default:
        uiNode.type = WidgetType.untyped;
        warnings.add('Unknown node type for "${node.name}".');
    }

    // Recurse into children.
    for (final child in node.children) {
      final converted = _convertNode(child, warnings);
      if (converted != null) {
        uiNode.addChild(converted);
      }
    }

    return uiNode;
  }

  /// Infer whether a frame with auto-layout should become a Row or Column.
  WidgetType _inferContainerType(FigmaNode node) {
    if (node.layoutMode == 'HORIZONTAL') return WidgetType.row;
    if (node.layoutMode == 'VERTICAL') return WidgetType.column;
    // Stacked children → Stack.
    if (node.children.length > 1) return WidgetType.stack;
    return WidgetType.container;
  }

  LayoutData _convertLayout(FigmaNode node) {
    final direction = switch (node.layoutMode) {
      'HORIZONTAL' => LayoutDirection.horizontal,
      'VERTICAL' => LayoutDirection.vertical,
      _ => LayoutDirection.none,
    };

    return LayoutData(
      direction: direction,
      padding: EdgeInsets.fromLTRB(
        node.paddingLeft,
        node.paddingTop,
        node.paddingRight,
        node.paddingBottom,
      ),
      spacing: node.itemSpacing,
      mainAxisAlignment: _mapMainAxisAlign(node.primaryAxisAlignItems),
      crossAxisAlignment: _mapCrossAxisAlign(node.counterAxisAlignItems),
      widthSizing: _mapSizing(node.layoutSizingHorizontal),
      heightSizing: _mapSizing(node.layoutSizingVertical),
    );
  }

  SizingMode _mapSizing(String? value) {
    return switch (value) {
      'FIXED' => SizingMode.fixed,
      'FILL' => SizingMode.fill,
      'HUG' => SizingMode.hug,
      _ => SizingMode.hug,
    };
  }

  String? _mapMainAxisAlign(String? value) {
    return switch (value) {
      'MIN' => 'start',
      'CENTER' => 'center',
      'MAX' => 'end',
      'SPACE_BETWEEN' => 'spaceBetween',
      _ => null,
    };
  }

  String? _mapCrossAxisAlign(String? value) {
    return switch (value) {
      'MIN' => 'start',
      'CENTER' => 'center',
      'MAX' => 'end',
      _ => null,
    };
  }

  StyleData _convertStyle(FigmaNode node) {
    final style = StyleData(
      opacity: node.opacity,
      borderRadius: node.cornerRadius ?? 0,
    );

    // First visible solid fill.
    final solidFill = node.fills
        .where((f) => f.visible && f.type == 'SOLID' && f.color != null)
        .firstOrNull;
    if (solidFill != null && solidFill.color != null) {
      style.fillColor = ColorValue.fromRgba(
        solidFill.color!.r,
        solidFill.color!.g,
        solidFill.color!.b,
        (solidFill.opacity ?? 1) * solidFill.color!.a,
      );
    }

    // First visible gradient fill.
    final gradientFill = node.fills
        .where((f) =>
            f.visible &&
            f.type.startsWith('GRADIENT') &&
            f.gradientStops != null &&
            f.gradientStops!.isNotEmpty)
        .firstOrNull;
    if (gradientFill != null && gradientFill.gradientStops != null) {
      style.gradient = GradientData(
        type: gradientFill.type,
        stops: (gradientFill.gradientStops! as List<dynamic>)
            .whereType<Map<String, dynamic>>()
            .map((s) {
              final colorRaw = s['color'] as Map<String, dynamic>?;
              final pos = (s['position'] as num?)?.toDouble() ?? 0;
              if (colorRaw == null) {
                return GradientStop(color: ColorValue('#FF000000'), position: pos);
              }
              final c = FigmaColor.fromJson(colorRaw);
              return GradientStop(
                color: ColorValue.fromRgba(c.r, c.g, c.b, c.a),
                position: pos,
              );
            })
            .toList(),
      );
    }

    // First visible solid stroke.
    final solidStroke = node.strokes
        .where((s) => s.visible && s.type == 'SOLID' && s.color != null)
        .firstOrNull;
    if (solidStroke != null && solidStroke.color != null) {
      style.borderColor = ColorValue.fromRgba(
        solidStroke.color!.r,
        solidStroke.color!.g,
        solidStroke.color!.b,
        (solidStroke.opacity ?? 1) * solidStroke.color!.a,
      );
      style.borderWidth = node.strokeWeight;
    }

    // First visible drop shadow effect.
    final shadow = node.effects
        .where((e) =>
            e.visible &&
            (e.type == 'DROP_SHADOW' || e.type == 'LAYER_BLUR') &&
            e.color != null)
        .firstOrNull;
    if (shadow != null && shadow.color != null) {
      style.shadow = ShadowData(
        color: ColorValue.fromRgba(
          shadow.color!.r,
          shadow.color!.g,
          shadow.color!.b,
          shadow.color!.a,
        ),
        blurRadius: shadow.radius ?? 0,
        offsetDx: shadow.offset?.x ?? 0,
        offsetDy: shadow.offset?.y ?? 0,
      );
    }

    return style;
  }

  TextData _convertText(FigmaNode node) {
    final style = node.style;
    final firstFill = node.fills
        .where((f) => f.visible && f.type == 'SOLID' && f.color != null)
        .firstOrNull;
    return TextData(
      text: node.characters ?? '',
      fontFamily: style?.fontFamily,
      fontSize: style?.fontSize ?? 14,
      fontWeight: style?.fontWeight ?? 400,
      italic: style?.italic ?? false,
      lineHeight: style?.lineHeightPx,
      letterSpacing: style?.letterSpacing,
      color: firstFill?.color != null
          ? ColorValue.fromRgba(
              firstFill!.color!.r,
              firstFill.color!.g,
              firstFill.color!.b,
              (firstFill.opacity ?? 1) * firstFill.color!.a,
            )
          : null,
      textAlign: _mapTextAlign(style?.textAlignHorizontal),
    );
  }

  String? _mapTextAlign(String? value) {
    return switch (value) {
      'LEFT' => 'left',
      'CENTER' => 'center',
      'RIGHT' => 'right',
      'JUSTIFIED' => 'justify',
      _ => null,
    };
  }
}
