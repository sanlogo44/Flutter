/// Intermediate representation of a Flutter widget tree used by the code
/// generator. This decouples the [UiNode] model (editor-facing) from the
/// generated Dart code structure.
library;

/// A node in the Flutter widget tree IR.
class WidgetModel {
  WidgetModel({
    required this.widgetType,
    List<WidgetProperty>? properties,
    List<WidgetModel>? children,
    this.dartCode,
    this.comment,
  })  : properties = properties ?? [],
        children = children ?? [];

  /// The Flutter widget class name, e.g. `Container`, `Column`, `Text`.
  final String widgetType;

  /// Properties/named parameters of the widget constructor.
  final List<WidgetProperty> properties;

  /// Child widgets.
  final List<WidgetModel> children;

  /// If non-null, a literal Dart expression used instead of generating
  /// from properties (e.g. for custom widgets).
  final String? dartCode;

  /// Optional comment emitted above the widget.
  final String? comment;

  /// Add a property.
  void addProperty(WidgetProperty prop) => properties.add(prop);

  /// Add a child widget.
  void addChild(WidgetModel child) => children.add(child);
}

/// A named property of a widget constructor.
class WidgetProperty {
  WidgetProperty({
    required this.name,
    required this.value,
    this.isNamed = true,
  });

  /// The parameter name, e.g. `padding`, `child`, `color`.
  final String name;

  /// The Dart expression string for the value, e.g. `EdgeInsets.all(16)`.
  final String value;

  /// Whether this is a named parameter (true) or positional (false).
  final bool isNamed;
}
