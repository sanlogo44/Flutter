/// Maps the editor-facing [UiNode] tree into the Flutter [WidgetModel] IR
/// used by the code generator.
///
/// The mapper applies the intelligent mapping rules from the spec:
/// it does not rely solely on node type but also considers layout mode,
/// styling and widget configuration to choose the right Flutter widget.
library;

import '../../domain/ui_node.dart';
import '../../domain/widget_model.dart';

class WidgetMapper {
  WidgetMapper();

  /// Map a [UiNode] subtree to a [WidgetModel] subtree.
  WidgetModel map(UiNode node) {
    // If the user has explicitly typed a widget, honor it first.
    if (node.widgetConfiguration != null &&
        node.widgetConfiguration!.widgetType != WidgetType.untyped) {
      return _mapTypedWidget(node);
    }

    return _mapByType(node);
  }

  WidgetModel _mapByType(UiNode node) {
    switch (node.type) {
      case WidgetType.text:
        return _mapText(node);
      case WidgetType.container:
        return _mapContainer(node);
      case WidgetType.column:
        return _mapFlex(node, 'Column');
      case WidgetType.row:
        return _mapFlex(node, 'Row');
      case WidgetType.stack:
        return _mapStack(node);
      case WidgetType.image:
        return _mapImage(node);
      case WidgetType.button:
        return _mapButton(node);
      case WidgetType.iconButton:
        return _mapIconButton(node);
      case WidgetType.textField:
        return _mapTextField(node);
      case WidgetType.listView:
        return _mapListView(node);
      case WidgetType.divider:
        return WidgetModel(widgetType: 'Divider');
      case WidgetType.card:
        return _mapCard(node);
      case WidgetType.appBar:
        return _mapAppBar(node);
      case WidgetType.custom:
      case WidgetType.untyped:
      default:
        return _mapContainer(node);
    }
  }

  WidgetModel _mapTypedWidget(UiNode node) {
    final cfg = node.widgetConfiguration!;
    // Override the node's type temporarily so mappers pick up the right shape.
    final typed = UiNode(
      id: node.id,
      name: node.name,
      type: cfg.widgetType,
      width: node.width,
      height: node.height,
      rotation: node.rotation,
      visible: node.visible,
      layout: node.layout,
      style: node.style,
      text: node.text != null
          ? TextData(text: cfg.label ?? node.text!.text)
          : (cfg.label != null ? TextData(text: cfg.label!) : null),
      children: node.children,
      widgetConfiguration: cfg,
      originFigmaId: node.originFigmaId,
    );
    return _mapByType(typed);
  }

  // --- Specific mappers ---

  WidgetModel _mapText(UiNode node) {
    final text = node.text;
    if (text == null) {
      return WidgetModel(
        widgetType: 'SizedBox',
        comment: 'Empty text node: ${node.name}',
      );
    }
    final escaped = _escapeString(text.text);
    final props = <WidgetProperty>[
      WidgetProperty(name: '', value: escaped, isNamed: false),
    ];
    if (text.fontSize != 14) {
      props.add(WidgetProperty(name: 'style', value: _textStyle(text)));
    } else if (text.color != null ||
        text.fontWeight != 400 ||
        text.fontFamily != null) {
      props.add(WidgetProperty(name: 'style', value: _textStyle(text)));
    }
    if (text.textAlign != null) {
      props.add(WidgetProperty(
        name: 'textAlign',
        value: _textAlign(text.textAlign!),
      ));
    }
    return WidgetModel(
      widgetType: 'Text',
      properties: props,
      comment: node.name,
    );
  }

  String _textStyle(TextData text) {
    final parts = <String>[];
    if (text.fontSize != 14) parts.add('fontSize: ${_fmtDouble(text.fontSize)}');
    if (text.fontWeight != 400) {
      parts.add('fontWeight: FontWeight.w${text.fontWeight}');
    }
    if (text.italic) parts.add('fontStyle: FontStyle.italic');
    if (text.color != null) parts.add('color: ${_color(text.color!)}');
    if (text.fontFamily != null) {
      parts.add("fontFamily: '${text.fontFamily}'");
    }
    if (text.letterSpacing != null) {
      parts.add('letterSpacing: ${_fmtDouble(text.letterSpacing!)}');
    }
    if (parts.isEmpty) return 'const TextStyle()';
    return 'TextStyle(${parts.join(', ')})';
  }

  String _textAlign(String align) {
    return switch (align) {
      'left' => 'TextAlign.left',
      'center' => 'TextAlign.center',
      'right' => 'TextAlign.right',
      'justify' => 'TextAlign.justify',
      _ => 'TextAlign.left',
    };
  }

  WidgetModel _mapContainer(UiNode node) {
    final props = <WidgetProperty>[];
    final style = node.style;

    // Decoration (background, border, radius, shadow).
    final decorationParts = <String>[];
    if (style.fillColor != null) {
      decorationParts.add('color: ${_color(style.fillColor!)}');
    }
    if (style.borderRadius > 0) {
      decorationParts.add(
          'borderRadius: BorderRadius.circular(${_fmtDouble(style.borderRadius)})');
    }
    if (style.borderColor != null && style.borderWidth != null) {
      decorationParts.add(
          'border: Border.all(color: ${_color(style.borderColor!)}, '
          'width: ${_fmtDouble(style.borderWidth!)})');
    }
    if (style.shadow != null) {
      decorationParts.add('boxShadow: [${_boxShadow(style.shadow!)}]');
    }

    if (decorationParts.length == 1 && style.fillColor != null) {
      props.add(WidgetProperty(
        name: 'color',
        value: _color(style.fillColor!),
      ));
    } else if (decorationParts.isNotEmpty) {
      props.add(WidgetProperty(
        name: 'decoration',
        value: 'BoxDecoration(${decorationParts.join(', ')})',
      ));
    }

    // Padding.
    if (node.layout.padding.top > 0 ||
        node.layout.padding.right > 0 ||
        node.layout.padding.bottom > 0 ||
        node.layout.padding.left > 0) {
      props.add(WidgetProperty(
        name: 'padding',
        value: _edgeInsets(node.layout.padding),
      ));
    }

    // Width/height (fixed sizing).
    if (node.layout.widthSizing == SizingMode.fixed && node.width != null) {
      props.add(WidgetProperty(name: 'width', value: _fmtDouble(node.width!)));
    }
    if (node.layout.heightSizing == SizingMode.fixed && node.height != null) {
      props.add(WidgetProperty(name: 'height', value: _fmtDouble(node.height!)));
    }

    if (style.opacity < 1) {
      props.add(WidgetProperty(
        name: 'child',
        value: 'Opacity(opacity: ${_fmtDouble(style.opacity)}, child: ...)',
      ));
    }

    final children = node.children.map(map).toList();
    final widget = WidgetModel(
      widgetType: 'Container',
      properties: props,
      comment: node.name,
    );
    for (final c in children) {
      widget.addChild(c);
    }
    return widget;
  }

  WidgetModel _mapFlex(UiNode node, String widgetType) {
    final props = <WidgetProperty>[];

    // MainAxisAlignment.
    if (node.layout.mainAxisAlignment != null) {
      props.add(WidgetProperty(
        name: 'mainAxisAlignment',
        value: _mainAxisAlign(node.layout.mainAxisAlignment!),
      ));
    }
    if (node.layout.crossAxisAlignment != null) {
      props.add(WidgetProperty(
        name: 'crossAxisAlignment',
        value: _crossAxisAlign(node.layout.crossAxisAlignment!),
      ));
    }
    // Spacing → use SizedBox between children if > 0 (handled by generator).
    // For simplicity we emit a custom approach: if spacing > 0, wrap children.
    final widget = WidgetModel(
      widgetType: widgetType,
      properties: props,
      comment: node.name,
    );
    final children = node.children.map(map).toList();
    if (node.layout.spacing > 0 && children.length > 1) {
      // Insert SizedBox spacers between children.
      final spaced = <WidgetModel>[];
      for (var i = 0; i < children.length; i++) {
        spaced.add(children[i]);
        if (i < children.length - 1) {
          spaced.add(WidgetModel(
            widgetType: 'SizedBox',
            properties: [
              WidgetProperty(
                name: widgetType == 'Row' ? 'width' : 'height',
                value: _fmtDouble(node.layout.spacing),
              ),
            ],
          ));
        }
      }
      for (final c in spaced) {
        widget.addChild(c);
      }
    } else {
      for (final c in children) {
        widget.addChild(c);
      }
    }
    return widget;
  }

  WidgetModel _mapStack(UiNode node) {
    final widget = WidgetModel(
      widgetType: 'Stack',
      comment: node.name,
    );
    for (final c in node.children.map(map)) {
      widget.addChild(c);
    }
    return widget;
  }

  WidgetModel _mapImage(UiNode node) {
    return WidgetModel(
      widgetType: 'Image',
      properties: [
        WidgetProperty(name: 'asset', value: "'assets/images/${node.name}.png'", isNamed: false),
      ],
      comment: node.name,
    );
  }

  WidgetModel _mapButton(UiNode node) {
    final label = node.text?.text ?? node.widgetConfiguration?.label ?? 'Button';
    final action = node.widgetConfiguration?.onTapAction;
    final child = WidgetModel(
      widgetType: 'Text',
      properties: [WidgetProperty(name: '', value: _escapeString(label), isNamed: false)],
    );
    return WidgetModel(
      widgetType: 'ElevatedButton',
      properties: [
        WidgetProperty(
          name: 'onPressed',
          value: action != null ? '() => $action' : '() {}',
        ),
      ],
      children: [child],
      comment: node.name,
    );
  }

  WidgetModel _mapIconButton(UiNode node) {
    final action = node.widgetConfiguration?.onTapAction;
    return WidgetModel(
      widgetType: 'IconButton',
      properties: [
        WidgetProperty(
          name: 'onPressed',
          value: action != null ? '() => $action' : '() {}',
        ),
        WidgetProperty(
          name: 'icon',
          value: "const Icon(Icons.add)",
        ),
      ],
      comment: node.name,
    );
  }

  WidgetModel _mapTextField(UiNode node) {
    final props = <WidgetProperty>[
      WidgetProperty(
        name: 'decoration',
        value:
            "const InputDecoration(hintText: '${node.text?.text ?? node.name}')",
      ),
    ];
    if (node.widgetConfiguration?.controllerName != null) {
      props.add(WidgetProperty(
        name: 'controller',
        value: node.widgetConfiguration!.controllerName!,
      ));
    }
    return WidgetModel(
      widgetType: 'TextField',
      properties: props,
      comment: node.name,
    );
  }

  WidgetModel _mapListView(UiNode node) {
    return WidgetModel(
      widgetType: 'ListView',
      properties: [
        WidgetProperty(
          name: 'children',
          value: 'const []',
        ),
      ],
      comment: node.name,
    );
  }

  WidgetModel _mapCard(UiNode node) {
    final widget = WidgetModel(
      widgetType: 'Card',
      properties: [
        if (node.style.borderRadius > 0)
          WidgetProperty(
            name: 'shape',
            value:
                'RoundedRectangleBorder(borderRadius: BorderRadius.circular(${_fmtDouble(node.style.borderRadius)}))',
          ),
      ],
      comment: node.name,
    );
    for (final c in node.children.map(map)) {
      widget.addChild(c);
    }
    return widget;
  }

  WidgetModel _mapAppBar(UiNode node) {
    final title = node.text?.text ?? node.name;
    return WidgetModel(
      widgetType: 'AppBar',
      properties: [
        WidgetProperty(name: 'title', value: "const Text('${_escape(title)}')"),
      ],
      comment: node.name,
    );
  }

  // --- Helpers ---

  String _color(ColorValue color) {
    final hex = color.hex.replaceAll('#', '');
    if (hex.length == 8) {
      return 'const Color(0x$hex)';
    } else if (hex.length == 6) {
      return 'const Color(0xFF$hex)';
    }
    return 'const Color(0xFF000000)';
  }

  String _boxShadow(ShadowData shadow) {
    return 'BoxShadow(color: ${_color(shadow.color)}, '
        'blurRadius: ${_fmtDouble(shadow.blurRadius)}, '
        'offset: const Offset(${_fmtDouble(shadow.offsetDx)}, '
        '${_fmtDouble(shadow.offsetDy)}))';
  }

  String _edgeInsets(EdgeInsets p) {
    if (p.left == p.top && p.top == p.right && p.right == p.bottom) {
      return 'const EdgeInsets.all(${_fmtDouble(p.top)})';
    }
    if (p.left == p.right && p.top == p.bottom) {
      return 'const EdgeInsets.symmetric(horizontal: ${_fmtDouble(p.left)}, '
          'vertical: ${_fmtDouble(p.top)})';
    }
    return 'const EdgeInsets.fromLTRB(${_fmtDouble(p.left)}, '
        '${_fmtDouble(p.top)}, ${_fmtDouble(p.right)}, ${_fmtDouble(p.bottom)})';
  }

  String _mainAxisAlign(String align) {
    return switch (align) {
      'start' => 'MainAxisAlignment.start',
      'center' => 'MainAxisAlignment.center',
      'end' => 'MainAxisAlignment.end',
      'spaceBetween' => 'MainAxisAlignment.spaceBetween',
      'spaceAround' => 'MainAxisAlignment.spaceAround',
      'spaceEvenly' => 'MainAxisAlignment.spaceEvenly',
      _ => 'MainAxisAlignment.start',
    };
  }

  String _crossAxisAlign(String align) {
    return switch (align) {
      'start' => 'CrossAxisAlignment.start',
      'center' => 'CrossAxisAlignment.center',
      'end' => 'CrossAxisAlignment.end',
      'stretch' => 'CrossAxisAlignment.stretch',
      _ => 'CrossAxisAlignment.center',
    };
  }

  String _fmtDouble(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '').replaceAll(
        RegExp(r'\.$'), '');
  }

  String _escapeString(String s) => "'${_escape(s)}'";
  String _escape(String s) => s.replaceAll("'", r"\'").replaceAll('\n', r'\n');
}
