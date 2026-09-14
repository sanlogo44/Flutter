/// Enum of all Figma node types the parser recognizes.
enum FigmaNodeType {
  document,
  canvas,
  frame,
  group,
  component,
  componentSet,
  instance,
  text,
  rectangle,
  ellipse,
  vector,
  line,
  polygon,
  star,
  booleanOperation,
  section,
  unknown;

  static FigmaNodeType fromString(String value) {
    return switch (value) {
      'DOCUMENT' => FigmaNodeType.document,
      'CANVAS' => FigmaNodeType.canvas,
      'FRAME' => FigmaNodeType.frame,
      'GROUP' => FigmaNodeType.group,
      'COMPONENT' => FigmaNodeType.component,
      'COMPONENT_SET' => FigmaNodeType.componentSet,
      'INSTANCE' => FigmaNodeType.instance,
      'TEXT' => FigmaNodeType.text,
      'RECTANGLE' => FigmaNodeType.rectangle,
      'ELLIPSE' => FigmaNodeType.ellipse,
      'VECTOR' => FigmaNodeType.vector,
      'LINE' => FigmaNodeType.line,
      'POLYGON' => FigmaNodeType.polygon,
      'STAR' => FigmaNodeType.star,
      'BOOLEAN_OPERATION' => FigmaNodeType.booleanOperation,
      'SECTION' => FigmaNodeType.section,
      _ => FigmaNodeType.unknown,
    };
  }
}

/// Minimal representation of a Figma API node (document tree).
/// This is intentionally decoupled from the internal [UiNode] model so that
/// other design sources can be supported later.
class FigmaNode {
  FigmaNode({
    required this.id,
    required this.name,
    required this.type,
    this.x = 0,
    this.y = 0,
    this.width,
    this.height,
    this.rotation = 0,
    this.visible = true,
    this.opacity = 1,
    this.fills = const [],
    this.strokes = const [],
    this.strokeWeight,
    this.cornerRadius,
    this.effects = const [],
    this.layoutMode,
    this.paddingTop = 0,
    this.paddingRight = 0,
    this.paddingBottom = 0,
    this.paddingLeft = 0,
    this.itemSpacing = 0,
    this.primaryAxisAlignItems,
    this.counterAxisAlignItems,
    this.layoutSizingHorizontal,
    this.layoutSizingVertical,
    this.characters,
    this.style,
    this.children = const [],
    this.componentId,
    this.constraints,
  });

  /// Parse from Figma API JSON map.
  factory FigmaNode.fromJson(Map<String, dynamic> json) {
    final type = FigmaNodeType.fromString(json['type'] as String? ?? '');
    final childrenRaw = json['children'] as List<dynamic>? ?? [];
    final fillsRaw = json['fills'] as List<dynamic>? ?? [];
    final strokesRaw = json['strokes'] as List<dynamic>? ?? [];
    final effectsRaw = json['effects'] as List<dynamic>? ?? [];
    final styleRaw = json['style'] as Map<String, dynamic>?;

    // Figma API provides size/position via absoluteBoundingBox and absoluteRenderBounds.
    final bbox = json['absoluteBoundingBox'] as Map<String, dynamic>? ??
        json['absoluteRenderBounds'] as Map<String, dynamic>?;
    final width = (json['width'] as num?)?.toDouble() ??
        (bbox?['width'] as num?)?.toDouble();
    final height = (json['height'] as num?)?.toDouble() ??
        (bbox?['height'] as num?)?.toDouble();
    final x = (json['x'] as num?)?.toDouble() ??
        (bbox?['x'] as num?)?.toDouble() ?? 0;
    final y = (json['y'] as num?)?.toDouble() ??
        (bbox?['y'] as num?)?.toDouble() ?? 0;

    return FigmaNode(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: type,
      x: x,
      y: y,
      width: width,
      height: height,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0,
      visible: json['visible'] as bool? ?? true,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1,
      fills: fillsRaw.map((e) => FigmaPaint.fromJson(e as Map<String, dynamic>)).toList(),
      strokes: strokesRaw.map((e) => FigmaPaint.fromJson(e as Map<String, dynamic>)).toList(),
      strokeWeight: (json['strokeWeight'] as num?)?.toDouble(),
      cornerRadius: (json['cornerRadius'] as num?)?.toDouble(),
      effects: effectsRaw.map((e) => FigmaEffect.fromJson(e as Map<String, dynamic>)).toList(),
      layoutMode: json['layoutMode'] as String?,
      paddingTop: (json['paddingTop'] as num?)?.toDouble() ?? 0,
      paddingRight: (json['paddingRight'] as num?)?.toDouble() ?? 0,
      paddingBottom: (json['paddingBottom'] as num?)?.toDouble() ?? 0,
      paddingLeft: (json['paddingLeft'] as num?)?.toDouble() ?? 0,
      itemSpacing: (json['itemSpacing'] as num?)?.toDouble() ?? 0,
      primaryAxisAlignItems: json['primaryAxisAlignItems'] as String?,
      counterAxisAlignItems: json['counterAxisAlignItems'] as String?,
      layoutSizingHorizontal: json['layoutSizingHorizontal'] as String?,
      layoutSizingVertical: json['layoutSizingVertical'] as String?,
      characters: json['characters'] as String?,
      style: styleRaw != null ? FigmaTextStyle.fromJson(styleRaw) : null,
      children: childrenRaw
          .map((e) => FigmaNode.fromJson(e as Map<String, dynamic>))
          .toList(),
      componentId: json['componentId'] as String?,
      constraints: json['constraints'] as Map<String, dynamic>?,
    );
  }

  final String id;
  final String name;
  final FigmaNodeType type;
  final double x;
  final double y;
  final double? width;
  final double? height;
  final double rotation;
  final bool visible;
  final double opacity;
  final List<FigmaPaint> fills;
  final List<FigmaPaint> strokes;
  final double? strokeWeight;
  final double? cornerRadius;
  final List<FigmaEffect> effects;
  final String? layoutMode; // 'HORIZONTAL' | 'VERTICAL' | null
  final double paddingTop;
  final double paddingRight;
  final double paddingBottom;
  final double paddingLeft;
  final double itemSpacing;
  final String? primaryAxisAlignItems;
  final String? counterAxisAlignItems;
  final String? layoutSizingHorizontal; // 'FIXED' | 'HUG' | 'FILL'
  final String? layoutSizingVertical;
  final String? characters;
  final FigmaTextStyle? style;
  final List<FigmaNode> children;
  final String? componentId;
  final Map<String, dynamic>? constraints;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name.toUpperCase(),
        'x': x,
        'y': y,
        if (width != null) 'width': width,
        if (height != null) 'height': height,
        'rotation': rotation,
        'visible': visible,
        'opacity': opacity,
        'fills': fills.map((e) => e.toJson()).toList(),
        'strokes': strokes.map((e) => e.toJson()).toList(),
        if (strokeWeight != null) 'strokeWeight': strokeWeight,
        if (cornerRadius != null) 'cornerRadius': cornerRadius,
        'effects': effects.map((e) => e.toJson()).toList(),
        if (layoutMode != null) 'layoutMode': layoutMode,
        'paddingTop': paddingTop,
        'paddingRight': paddingRight,
        'paddingBottom': paddingBottom,
        'paddingLeft': paddingLeft,
        'itemSpacing': itemSpacing,
        if (primaryAxisAlignItems != null)
          'primaryAxisAlignItems': primaryAxisAlignItems,
        if (counterAxisAlignItems != null)
          'counterAxisAlignItems': counterAxisAlignItems,
        if (layoutSizingHorizontal != null)
          'layoutSizingHorizontal': layoutSizingHorizontal,
        if (layoutSizingVertical != null)
          'layoutSizingVertical': layoutSizingVertical,
        if (characters != null) 'characters': characters,
        if (style != null) 'style': style!.toJson(),
        'children': children.map((e) => e.toJson()).toList(),
        if (componentId != null) 'componentId': componentId,
        if (constraints != null) 'constraints': constraints,
      };
}

class FigmaPaint {
  FigmaPaint({
    required this.type,
    this.color,
    this.opacity,
    this.visible = true,
    this.gradientHandlePositions,
    this.gradientStops,
  });

  factory FigmaPaint.fromJson(Map<String, dynamic> json) {
    final colorRaw = json['color'] as Map<String, dynamic>?;
    return FigmaPaint(
      type: json['type'] as String? ?? 'SOLID',
      color: colorRaw != null ? FigmaColor.fromJson(colorRaw) : null,
      opacity: (json['opacity'] as num?)?.toDouble(),
      visible: json['visible'] as bool? ?? true,
      gradientHandlePositions: json['gradientHandlePositions'] as List<dynamic>?,
      gradientStops: json['gradientStops'] as List<dynamic>?,
    );
  }

  final String type; // 'SOLID' | 'GRADIENT_LINEAR' | ...
  final FigmaColor? color;
  final double? opacity;
  final bool visible;
  final List<dynamic>? gradientHandlePositions;
  final List<dynamic>? gradientStops;

  Map<String, dynamic> toJson() => {
        'type': type,
        if (color != null) 'color': color!.toJson(),
        if (opacity != null) 'opacity': opacity,
        'visible': visible,
        if (gradientHandlePositions != null)
          'gradientHandlePositions': gradientHandlePositions,
        if (gradientStops != null) 'gradientStops': gradientStops,
      };
}

class FigmaColor {
  FigmaColor({
    required this.r,
    required this.g,
    required this.b,
    required this.a,
  });

  factory FigmaColor.fromJson(Map<String, dynamic> json) => FigmaColor(
        r: (json['r'] as num).toDouble(),
        g: (json['g'] as num).toDouble(),
        b: (json['b'] as num).toDouble(),
        a: (json['a'] as num).toDouble(),
      );

  final double r;
  final double g;
  final double b;
  final double a;

  /// Convert to a hex color string like `#FFRRGGBB`.
  String toHex() {
    final ri = (r * 255).round().clamp(0, 255);
    final gi = (g * 255).round().clamp(0, 255);
    final bi = (b * 255).round().clamp(0, 255);
    final ai = (a * 255).round().clamp(0, 255);
    return '#${ai.toRadixString(16).padLeft(2, '0')}'
        '${ri.toRadixString(16).padLeft(2, '0')}'
        '${gi.toRadixString(16).padLeft(2, '0')}'
        '${bi.toRadixString(16).padLeft(2, '0')}';
  }

  Map<String, dynamic> toJson() => {'r': r, 'g': g, 'b': b, 'a': a};
}

class FigmaEffect {
  FigmaEffect({required this.type, this.visible = true, this.radius, this.offset, this.color});

  factory FigmaEffect.fromJson(Map<String, dynamic> json) {
    final colorRaw = json['color'] as Map<String, dynamic>?;
    final offsetRaw = json['offset'] as Map<String, dynamic>?;
    return FigmaEffect(
      type: json['type'] as String? ?? 'DROP_SHADOW',
      visible: json['visible'] as bool? ?? true,
      radius: (json['radius'] as num?)?.toDouble(),
      offset: offsetRaw != null
          ? FigmaVector.fromJson(offsetRaw)
          : null,
      color: colorRaw != null ? FigmaColor.fromJson(colorRaw) : null,
    );
  }

  final String type;
  final bool visible;
  final double? radius;
  final FigmaVector? offset;
  final FigmaColor? color;

  Map<String, dynamic> toJson() => {
        'type': type,
        'visible': visible,
        if (radius != null) 'radius': radius,
        if (offset != null) 'offset': offset!.toJson(),
        if (color != null) 'color': color!.toJson(),
      };
}

class FigmaVector {
  FigmaVector({required this.x, required this.y});

  factory FigmaVector.fromJson(Map<String, dynamic> json) => FigmaVector(
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
      );

  final double x;
  final double y;

  Map<String, dynamic> toJson() => {'x': x, 'y': y};
}

class FigmaTextStyle {
  FigmaTextStyle({
    this.fontFamily,
    this.fontSize = 14,
    this.fontWeight = 400,
    this.italic = false,
    this.lineHeightPx,
    this.letterSpacing,
    this.textCase,
    this.textDecoration,
    this.textAlignHorizontal,
    this.textAlignVertical,
  });

  factory FigmaTextStyle.fromJson(Map<String, dynamic> json) => FigmaTextStyle(
        fontFamily: json['fontFamily'] as String?,
        fontSize: (json['fontSize'] as num?)?.toDouble() ?? 14,
        fontWeight: (json['fontWeight'] as num?)?.toInt() ?? 400,
        italic: json['italic'] as bool? ?? false,
        lineHeightPx: (json['lineHeightPx'] as num?)?.toDouble(),
        letterSpacing: (json['letterSpacing'] as num?)?.toDouble(),
        textCase: json['textCase'] as String?,
        textDecoration: json['textDecoration'] as String?,
        textAlignHorizontal: json['textAlignHorizontal'] as String?,
        textAlignVertical: json['textAlignVertical'] as String?,
      );

  final String? fontFamily;
  final double fontSize;
  final int fontWeight;
  final bool italic;
  final double? lineHeightPx;
  final double? letterSpacing;
  final String? textCase;
  final String? textDecoration;
  final String? textAlignHorizontal;
  final String? textAlignVertical;

  Map<String, dynamic> toJson() => {
        if (fontFamily != null) 'fontFamily': fontFamily,
        'fontSize': fontSize,
        'fontWeight': fontWeight,
        'italic': italic,
        if (lineHeightPx != null) 'lineHeightPx': lineHeightPx,
        if (letterSpacing != null) 'letterSpacing': letterSpacing,
        if (textCase != null) 'textCase': textCase,
        if (textDecoration != null) 'textDecoration': textDecoration,
        if (textAlignHorizontal != null) 'textAlignHorizontal': textAlignHorizontal,
        if (textAlignVertical != null) 'textAlignVertical': textAlignVertical,
      };
}
