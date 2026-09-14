/// Renders [AstNode] trees and [WidgetModel] trees into formatted Dart source
/// code strings.
library;

import '../../../domain/widget_model.dart';
import 'ast/ast_nodes.dart';

class DartGenerator {
  DartGenerator();

  /// Render a full Dart file from a list of declarations.
  String renderFile({
    String? header,
    List<ImportDecl>? imports,
    required List<Declaration> declarations,
  }) {
    final buf = StringBuffer();
    if (header != null) {
      buf.writeln('// $header');
      buf.writeln();
    }
    if (imports != null) {
      for (final imp in imports) {
        buf.writeln(_renderImport(imp));
      }
      buf.writeln();
    }
    for (var i = 0; i < declarations.length; i++) {
      buf.write(renderDeclaration(declarations[i]));
      if (i < declarations.length - 1) {
        buf.writeln();
        buf.writeln();
      }
    }
    return buf.toString();
  }

  /// Render a single declaration to source.
  String renderDeclaration(Declaration decl) {
    return switch (decl) {
      ClassDecl c => _renderClass(c),
      MethodDecl m => _renderMethod(m),
      FieldDecl f => _renderField(f),
      ImportDecl i => _renderImport(i),
      ConstructorDecl c => _renderConstructor(c),
      ParameterDecl p => _renderParameter(p),
      _ => '/* unsupported declaration: ${decl.runtimeType} */',
    };
  }

  // --- Imports ---

  String _renderImport(ImportDecl imp) {
    final buf = StringBuffer("import '");
    buf.write(imp.uri);
    buf.write("'");
    if (imp.asName != null) {
      buf.write(' as ${imp.asName}');
    }
    if (imp.show.isNotEmpty) {
      buf.write(' show ${imp.show.join(', ')}');
    }
    buf.write(';');
    return buf.toString();
  }

  // --- Classes ---

  String _renderClass(ClassDecl c) {
    final buf = StringBuffer();
    if (c.documentation != null) {
      buf.writeln('/// ${c.documentation}');
    }
    if (c.isAbstract) buf.write('abstract ');
    buf.write('class ${c.name}');
    if (c.extendsName != null) {
      buf.write(' extends ${c.extendsName}');
    }
    if (c.withMixins.isNotEmpty) {
      buf.write(' with ${c.withMixins.join(', ')}');
    }
    if (c.implements.isNotEmpty) {
      buf.write(' implements ${c.implements.join(', ')}');
    }
    buf.writeln(' {');

    for (final f in c.fields) {
      buf.writeln('  ${_renderField(f)}');
    }
    if (c.fields.isNotEmpty) buf.writeln();

    for (final ctor in c.constructors) {
      buf.writeln('  ${_renderConstructor(ctor)}');
    }
    if (c.constructors.isNotEmpty) buf.writeln();

    for (final m in c.methods) {
      buf.writeln('  ${_renderMethod(m)}');
      buf.writeln();
    }

    buf.writeln('}');
    return buf.toString();
  }

  String _renderField(FieldDecl f) {
    final buf = StringBuffer();
    if (f.documentation != null) {
      buf.write('/// ${f.documentation} ');
    }
    if (f.isStatic) buf.write('static ');
    buf.write('${f.modifier} ${f.type} ${f.name}');
    if (f.initializer != null) {
      buf.write(' = ${_renderExpression(f.initializer!)}');
    }
    buf.write(';');
    return buf.toString();
  }

  String _renderMethod(MethodDecl m) {
    final buf = StringBuffer();
    if (m.documentation != null) {
      buf.writeln('  /// ${m.documentation}');
    }
    if (m.isStatic) buf.write('static ');
    buf.write('${m.returnType} ${m.name}(');
    buf.write(m.parameters.map(_renderParameter).join(', '));
    buf.write(')');
    if (m.isAsync) buf.write(' async');
    buf.writeln(' {');
    for (final s in m.body) {
      buf.writeln('    ${_renderStatement(s)}');
    }
    buf.write('  }');
    return buf.toString();
  }

  String _renderConstructor(ConstructorDecl c) {
    final buf = StringBuffer();
    if (c.isConst) buf.write('const ');
    buf.write(c.className);
    if (c.name != null) buf.write('.${c.name}');
    buf.write('(');
    buf.write(c.parameters.map(_renderParameter).join(', '));
    buf.write(')');
    if (c.initializers.isNotEmpty) {
      buf.write(' : ${c.initializers.join(', ')}');
    }
    if (c.body.isEmpty) {
      buf.write(';');
    } else {
      buf.writeln(' {');
      for (final s in c.body) {
        buf.writeln('    ${_renderStatement(s)}');
      }
      buf.write('  }');
    }
    return buf.toString();
  }

  String _renderParameter(ParameterDecl p) {
    final buf = StringBuffer();
    if (p.named) {
      if (p.isRequired) buf.write('required ');
      buf.write('${p.type} ${p.name}');
    } else {
      buf.write('${p.type} ${p.name}');
    }
    if (p.defaultValue != null) {
      buf.write(' = ${_renderExpression(p.defaultValue!)}');
    }
    return buf.toString();
  }

  // --- Expressions ---

  String _renderExpression(Expression expr) {
    return switch (expr) {
      LiteralExpr l => l.value,
      StringLiteral s => "'${_escape(s.value)}'",
      NumberLiteral n => _fmtDouble(n.value),
      BoolLiteral b => b.toString(),
      IdentifierExpr i => i.name,
      MemberExpr m =>
        '${_renderExpression(m.target)}.${m.member}',
      CallExpr c =>
        '${_renderExpression(c.target)}(${_renderArgs(c.arguments, c.namedArguments)})',
      ConstructorCall c =>
        '${c.isConst ? 'const ' : ''}${c.type}(${_renderNamedOnly(c.namedArguments)})',
      _ => '/* unsupported expression: ${expr.runtimeType} */',
    };
  }

  String _renderArgs(List<Expression> args, Map<String, Expression> named) {
    final parts = <String>[];
    for (final a in args) {
      parts.add(_renderExpression(a));
    }
    for (final entry in named.entries) {
      parts.add('${entry.key}: ${_renderExpression(entry.value)}');
    }
    return parts.join(', ');
  }

  String _renderNamedOnly(Map<String, Expression> named) {
    final parts = <String>[];
    for (final entry in named.entries) {
      parts.add('${entry.key}: ${_renderExpression(entry.value)}');
    }
    return parts.join(', ');
  }

  // --- Statements ---

  String _renderStatement(Statement stmt) {
    return switch (stmt) {
      ReturnStatement r =>
        r.value != null ? 'return ${_renderExpression(r.value!)};' : 'return;',
      ExpressionStatement e =>
        '${_renderExpression(e.expression)};',
      VariableDeclStatement v =>
        v.initializer != null
            ? '${v.type} ${v.name} = ${_renderExpression(v.initializer!)};'
            : '${v.type} ${v.name};',
      IfStatement i =>
        'if (${_renderExpression(i.condition)}) { ... } else { ... }',
      BlockStatement b =>
        b.statements.map(_renderStatement).join(' '),
      _ => '/* unsupported statement: ${stmt.runtimeType} */',
    };
  }

  // --- WidgetModel rendering ---

  /// Render a [WidgetModel] tree to a Dart widget expression string.
  String renderWidget(WidgetModel widget, {int indent = 0}) {
    final pad = '  ' * indent;
    final innerPad = '  ' * (indent + 1);

    if (widget.dartCode != null) {
      return '$pad${widget.dartCode!}';
    }

    final buf = StringBuffer();
    if (widget.comment != null) {
      buf.writeln('$pad// ${widget.comment}');
    }
    buf.write('${pad}${widget.widgetType}(');

    final hasChildren = widget.children.isNotEmpty;
    final props = widget.properties;

    // Single child widgets use `child:`, multi-child use `children: []`.
    if (hasChildren && props.every((p) => p.name != 'child')) {
      // Render positional props first, then named props.
      final positionalProps = props.where((p) => !p.isNamed).toList();
      final namedProps = props.where((p) => p.isNamed).toList();
      for (final p in positionalProps) {
        buf.writeln();
        buf.write('$innerPad${p.value},');
      }
      for (final p in namedProps) {
        buf.writeln();
        buf.write('$innerPad${p.name}: ${p.value},');
      }
      if (widget.children.length == 1) {
        buf.writeln();
        buf.write('${innerPad}child: ');
        buf.write(renderWidget(widget.children.first, indent: indent + 1)
            .trimLeft());
        buf.write(',');
      } else {
        buf.writeln();
        buf.writeln('${innerPad}children: [');
        for (final c in widget.children) {
          buf.writeln(renderWidget(c, indent: indent + 2) + ',');
        }
        buf.write('$innerPad],');
      }
      buf.writeln();
      buf.write('$pad)');
    } else if (props.isNotEmpty) {
      // No children, just properties.
      buf.writeln();
      final positionalProps = props.where((p) => !p.isNamed).toList();
      final namedProps = props.where((p) => p.isNamed).toList();
      for (final p in positionalProps) {
        buf.write('$innerPad${p.value},');
        buf.writeln();
      }
      for (final p in namedProps) {
        buf.write('$innerPad${p.name}: ${p.value},');
        buf.writeln();
      }
      buf.write('$pad)');
    } else {
      buf.write(')');
    }

    return buf.toString();
  }

  // --- Helpers ---

  String _escape(String s) => s.replaceAll("'", r"\'").replaceAll('\n', r'\n');

  String _fmtDouble(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }
}
