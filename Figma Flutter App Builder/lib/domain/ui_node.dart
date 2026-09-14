/// The internal, source-independent representation of a UI element.
///
/// This is the central data structure of the builder. It is NOT directly coupled
/// to Figma – the [FigmaParser] converts Figma's tree into this model, and the
/// [WidgetMapper] converts this model into a [WidgetModel] for code generation.
/// Future design sources (Sketch, Adobe XD) can target the same model.
library;

import 'package:uuid/uuid.dart';

/// All widget types a [UiNode] can be typed as in the builder.
enum WidgetType {
  container,
  column,
  row,
  stack,
  text,
  image,
  button,
  iconButton,
  textField,
  checkbox,
  switcher,
  slider,
  dropdown,
  listView,
  gridView,
  card,
  navigationBar,
  appBar,
  dialog,
  bottomSheet,
  divider,
  custom,
  untyped,
}

/// How a node's main axis is oriented.
enum LayoutDirection { horizontal, vertical, none }

/// How a child is sized along the main/cross axis.
enum SizingMode { fixed, hug, fill }

/// A color value in the internal model (hex `#AARRGGBB` or `#RRGGBB`).
class ColorValue {
  ColorValue(this.hex);

  /// Parse from `#RRGGBB` or `#AARRGGBB` hex string.
  factory ColorValue.parse(String hex) {
    var h = hex.replaceAll('#', '');
    if (h.length == 6) {
      h = 'FF$h';
    }
    return ColorValue('#$h');
  }

  factory ColorValue.fromRgba(double r, double g, double b, double a) {
    final ri = (r * 255).round().clamp(0, 255);
    final gi = (g * 255).round().clamp(0, 255);
    final bi = (b * 255).round().clamp(0, 255);
    final ai = (a * 255).round().clamp(0, 255);
    return ColorValue('#${ai.toRadixString(16).padLeft(2, '0')}'
        '${ri.toRadixString(16).padLeft(2, '0')}'
        '${gi.toRadixString(16).padLeft(2, '0')}'
        '${bi.toRadixString(16).padLeft(2, '0')}');
  }

  final String hex;

  @override
  String toString() => hex;
  @override
  bool operator ==(Object other) => other is ColorValue && other.hex == hex;
  @override
  int get hashCode => hex.hashCode;
}

/// Layout data for a node (padding, spacing, direction, sizing, alignment).
class LayoutData {
  LayoutData({
    this.direction = LayoutDirection.none,
    this.padding = const EdgeInsets.all(0),
    this.spacing = 0,
    this.mainAxisAlignment,
    this.crossAxisAlignment,
    this.widthSizing = SizingMode.hug,
    this.heightSizing = SizingMode.hug,
  });

  LayoutDirection direction;
  EdgeInsets padding;
  double spacing;
  String? mainAxisAlignment; // e.g. 'center', 'start', 'spaceBetween'
  String? crossAxisAlignment;
  SizingMode widthSizing;
  SizingMode heightSizing;

  Map<String, dynamic> toJson() => {
        'direction': direction.name,
        'padding': {
          'top': padding.top,
          'right': padding.right,
          'bottom': padding.bottom,
          'left': padding.left,
        },
        'spacing': spacing,
        if (mainAxisAlignment != null) 'mainAxisAlignment': mainAxisAlignment,
        if (crossAxisAlignment != null) 'crossAxisAlignment': crossAxisAlignment,
        'widthSizing': widthSizing.name,
        'heightSizing': heightSizing.name,
      };

  factory LayoutData.fromJson(Map<String, dynamic> json) {
    final p = json['padding'] as Map<String, dynamic>? ?? {};
    return LayoutData(
      direction: LayoutDirection.values.firstWhere(
        (e) => e.name == (json['direction'] as String? ?? 'none'),
        orElse: () => LayoutDirection.none,
      ),
      padding: EdgeInsets.fromLTRB(
        (p['left'] as num?)?.toDouble() ?? 0,
        (p['top'] as num?)?.toDouble() ?? 0,
        (p['right'] as num?)?.toDouble() ?? 0,
        (p['bottom'] as num?)?.toDouble() ?? 0,
      ),
      spacing: (json['spacing'] as num?)?.toDouble() ?? 0,
      mainAxisAlignment: json['mainAxisAlignment'] as String?,
      crossAxisAlignment: json['crossAxisAlignment'] as String?,
      widthSizing: SizingMode.values.firstWhere(
        (e) => e.name == (json['widthSizing'] as String? ?? 'hug'),
        orElse: () => SizingMode.hug,
      ),
      heightSizing: SizingMode.values.firstWhere(
        (e) => e.name == (json['heightSizing'] as String? ?? 'hug'),
        orElse: () => SizingMode.hug,
      ),
    );
  }

  LayoutData copy() => LayoutData(
        direction: direction,
        padding: padding,
        spacing: spacing,
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        widthSizing: widthSizing,
        heightSizing: heightSizing,
      );
}

/// Simple EdgeInsets-like class (avoiding Flutter dependency in domain tests).
class EdgeInsets {
  const EdgeInsets.fromLTRB(this.left, this.top, this.right, this.bottom);
  const EdgeInsets.all(double v)
      : left = v,
        top = v,
        right = v,
        bottom = v;
  const EdgeInsets.symmetric({double vertical = 0, double horizontal = 0})
      : left = horizontal,
        right = horizontal,
        top = vertical,
        bottom = vertical;
  final double left;
  final double top;
  final double right;
  final double bottom;
  static const zero = EdgeInsets.all(0);
}

/// Style data for a node (fill, border, radius, shadow, opacity).
class StyleData {
  StyleData({
    this.fillColor,
    this.borderRadius = 0,
    this.borderColor,
    this.borderWidth,
    this.shadow,
    this.opacity = 1,
    this.gradient,
  });

  ColorValue? fillColor;
  double borderRadius;
  ColorValue? borderColor;
  double? borderWidth;
  ShadowData? shadow;
  double opacity;
  GradientData? gradient;

  Map<String, dynamic> toJson() => {
        if (fillColor != null) 'fillColor': fillColor!.hex,
        'borderRadius': borderRadius,
        if (borderColor != null) 'borderColor': borderColor!.hex,
        if (borderWidth != null) 'borderWidth': borderWidth,
        if (shadow != null) 'shadow': shadow!.toJson(),
        'opacity': opacity,
        if (gradient != null) 'gradient': gradient!.toJson(),
      };

  factory StyleData.fromJson(Map<String, dynamic> json) => StyleData(
        fillColor: json['fillColor'] != null
            ? ColorValue.parse(json['fillColor'] as String)
            : null,
        borderRadius: (json['borderRadius'] as num?)?.toDouble() ?? 0,
        borderColor: json['borderColor'] != null
            ? ColorValue.parse(json['borderColor'] as String)
            : null,
        borderWidth: (json['borderWidth'] as num?)?.toDouble(),
        shadow: json['shadow'] != null
            ? ShadowData.fromJson(json['shadow'] as Map<String, dynamic>)
            : null,
        opacity: (json['opacity'] as num?)?.toDouble() ?? 1,
        gradient: json['gradient'] != null
            ? GradientData.fromJson(json['gradient'] as Map<String, dynamic>)
            : null,
      );

  StyleData copy() => StyleData(
        fillColor: fillColor,
        borderRadius: borderRadius,
        borderColor: borderColor,
        borderWidth: borderWidth,
        shadow: shadow?.copy(),
        opacity: opacity,
        gradient: gradient?.copy(),
      );
}

class ShadowData {
  ShadowData({
    required this.color,
    required this.blurRadius,
    required this.offsetDx,
    required this.offsetDy,
  });

  factory ShadowData.fromJson(Map<String, dynamic> json) => ShadowData(
        color: ColorValue.parse(json['color'] as String),
        blurRadius: (json['blurRadius'] as num).toDouble(),
        offsetDx: (json['offsetDx'] as num?)?.toDouble() ?? 0,
        offsetDy: (json['offsetDy'] as num?)?.toDouble() ?? 0,
      );

  final ColorValue color;
  final double blurRadius;
  final double offsetDx;
  final double offsetDy;

  Map<String, dynamic> toJson() => {
        'color': color.hex,
        'blurRadius': blurRadius,
        'offsetDx': offsetDx,
        'offsetDy': offsetDy,
      };

  ShadowData copy() => ShadowData(
        color: color,
        blurRadius: blurRadius,
        offsetDx: offsetDx,
        offsetDy: offsetDy,
      );
}

class GradientData {
  GradientData({required this.type, required this.stops});

  factory GradientData.fromJson(Map<String, dynamic> json) => GradientData(
        type: json['type'] as String? ?? 'linear',
        stops: (json['stops'] as List<dynamic>)
            .map((e) => GradientStop.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  final String type;
  final List<GradientStop> stops;

  Map<String, dynamic> toJson() => {
        'type': type,
        'stops': stops.map((e) => e.toJson()).toList(),
      };

  GradientData copy() => GradientData(type: type, stops: stops.map((e) => e.copy()).toList());
}

class GradientStop {
  GradientStop({required this.color, required this.position});

  factory GradientStop.fromJson(Map<String, dynamic> json) => GradientStop(
        color: ColorValue.parse(json['color'] as String),
        position: (json['position'] as num).toDouble(),
      );

  final ColorValue color;
  final double position;

  Map<String, dynamic> toJson() => {'color': color.hex, 'position': position};

  GradientStop copy() => GradientStop(color: color, position: position);
}

/// Text-specific data for a [UiNode] typed as text.
class TextData {
  TextData({
    required this.text,
    this.fontFamily,
    this.fontSize = 14,
    this.fontWeight = 400,
    this.italic = false,
    this.lineHeight,
    this.letterSpacing,
    this.color,
    this.textAlign,
  });

  factory TextData.fromJson(Map<String, dynamic> json) => TextData(
        text: json['text'] as String? ?? '',
        fontFamily: json['fontFamily'] as String?,
        fontSize: (json['fontSize'] as num?)?.toDouble() ?? 14,
        fontWeight: (json['fontWeight'] as num?)?.toInt() ?? 400,
        italic: json['italic'] as bool? ?? false,
        lineHeight: (json['lineHeight'] as num?)?.toDouble(),
        letterSpacing: (json['letterSpacing'] as num?)?.toDouble(),
        color: json['color'] != null ? ColorValue.parse(json['color'] as String) : null,
        textAlign: json['textAlign'] as String?,
      );

  String text;
  String? fontFamily;
  double fontSize;
  int fontWeight;
  bool italic;
  double? lineHeight;
  double? letterSpacing;
  ColorValue? color;
  String? textAlign;

  Map<String, dynamic> toJson() => {
        'text': text,
        if (fontFamily != null) 'fontFamily': fontFamily,
        'fontSize': fontSize,
        'fontWeight': fontWeight,
        'italic': italic,
        if (lineHeight != null) 'lineHeight': lineHeight,
        if (letterSpacing != null) 'letterSpacing': letterSpacing,
        if (color != null) 'color': color!.hex,
        if (textAlign != null) 'textAlign': textAlign,
      };

  TextData copy() => TextData(
        text: text,
        fontFamily: fontFamily,
        fontSize: fontSize,
        fontWeight: fontWeight,
        italic: italic,
        lineHeight: lineHeight,
        letterSpacing: letterSpacing,
        color: color,
        textAlign: textAlign,
      );
}

/// Optional configuration that ties a node to a specific Flutter widget
/// (e.g. a rectangle typed as a `Button` with a label and an action).
class WidgetConfiguration {
  WidgetConfiguration({
    required this.widgetType,
    this.label,
    this.onTapAction,
    this.controllerName,
    this.variableName,
    this.key,
  });

  factory WidgetConfiguration.fromJson(Map<String, dynamic> json) =>
      WidgetConfiguration(
        widgetType: WidgetType.values.firstWhere(
          (e) => e.name == (json['widgetType'] as String?),
          orElse: () => WidgetType.untyped,
        ),
        label: json['label'] as String?,
        onTapAction: json['onTapAction'] as String?,
        controllerName: json['controllerName'] as String?,
        variableName: json['variableName'] as String?,
        key: json['key'] as String?,
      );

  WidgetType widgetType;
  String? label;
  String? onTapAction;
  String? controllerName;
  String? variableName;
  String? key;

  Map<String, dynamic> toJson() => {
        'widgetType': widgetType.name,
        if (label != null) 'label': label,
        if (onTapAction != null) 'onTapAction': onTapAction,
        if (controllerName != null) 'controllerName': controllerName,
        if (variableName != null) 'variableName': variableName,
        if (key != null) 'key': key,
      };

  WidgetConfiguration copy() => WidgetConfiguration(
        widgetType: widgetType,
        label: label,
        onTapAction: onTapAction,
        controllerName: controllerName,
        variableName: variableName,
        key: key,
      );
}

/// The core node of the internal UI tree.
class UiNode {
  UiNode({
    String? id,
    required this.name,
    this.type = WidgetType.untyped,
    this.width,
    this.height,
    this.rotation = 0,
    this.visible = true,
    LayoutData? layout,
    StyleData? style,
    TextData? text,
    List<UiNode>? children,
    this.widgetConfiguration,
    this.originFigmaId,
  })  : id = id ?? const Uuid().v4(),
        layout = layout ?? LayoutData(),
        style = style ?? StyleData(),
        text = text,
        children = children ?? [];

  /// Parse from the builder's own JSON format.
  factory UiNode.fromJson(Map<String, dynamic> json) => UiNode(
        id: json['id'] as String?,
        name: json['name'] as String? ?? 'Unnamed',
        type: WidgetType.values.firstWhere(
          (e) => e.name == (json['type'] as String? ?? 'untyped'),
          orElse: () => WidgetType.untyped,
        ),
        width: (json['width'] as num?)?.toDouble(),
        height: (json['height'] as num?)?.toDouble(),
        rotation: (json['rotation'] as num?)?.toDouble() ?? 0,
        visible: json['visible'] as bool? ?? true,
        layout: json['layout'] != null
            ? LayoutData.fromJson(json['layout'] as Map<String, dynamic>)
            : null,
        style: json['style'] != null
            ? StyleData.fromJson(json['style'] as Map<String, dynamic>)
            : null,
        text: json['text'] != null
            ? TextData.fromJson(json['text'] as Map<String, dynamic>)
            : null,
        children: (json['children'] as List<dynamic>? ?? [])
            .map((e) => UiNode.fromJson(e as Map<String, dynamic>))
            .toList(),
        widgetConfiguration: json['widgetConfiguration'] != null
            ? WidgetConfiguration.fromJson(
                json['widgetConfiguration'] as Map<String, dynamic>)
            : null,
        originFigmaId: json['originFigmaId'] as String?,
      );

  String id;
  String name;
  WidgetType type;
  double? width;
  double? height;
  double rotation;
  bool visible;
  LayoutData layout;
  StyleData style;
  TextData? text;
  List<UiNode> children;
  WidgetConfiguration? widgetConfiguration;
  String? originFigmaId;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        if (width != null) 'width': width,
        if (height != null) 'height': height,
        'rotation': rotation,
        'visible': visible,
        'layout': layout.toJson(),
        'style': style.toJson(),
        if (text != null) 'text': text!.toJson(),
        'children': children.map((e) => e.toJson()).toList(),
        if (widgetConfiguration != null) 'widgetConfiguration': widgetConfiguration!.toJson(),
        if (originFigmaId != null) 'originFigmaId': originFigmaId,
      };

  /// Deep copy of this node and all its children.
  UiNode deepCopy() => UiNode.fromJson(toJson());

  /// Find a node by id in this subtree.
  UiNode? findById(String targetId) {
    if (id == targetId) return this;
    for (final child in children) {
      final found = child.findById(targetId);
      if (found != null) return found;
    }
    return null;
  }

  /// Remove a child by id. Returns true if removed.
  bool removeChild(String childId) {
    for (var i = 0; i < children.length; i++) {
      if (children[i].id == childId) {
        children.removeAt(i);
        return true;
      }
      if (children[i].removeChild(childId)) return true;
    }
    return false;
  }

  /// Insert a child node.
  void addChild(UiNode child) => children.add(child);

  /// Move a child to a new parent.
  void moveChild(String childId, UiNode newParent) {
    final child = findById(childId);
    if (child == null || child.id == id) return;
    // Remove from current location (root-level caller handles removal).
    removeChild(childId);
    newParent.addChild(child);
  }
}
