/// A minimal Dart AST model used by the code generator.
///
/// Rather than building enormous string templates, the generator constructs
/// these AST nodes which are then rendered to source by [DartFormatter].
library;

/// Base class for all AST nodes.
abstract class AstNode {
  const AstNode();
}

/// A Dart expression (something that has a value).
abstract class Expression extends AstNode {
  const Expression();
}

/// A Dart statement.
abstract class Statement extends AstNode {
  const Statement();
}

/// A top-level declaration (class, import, function, field).
abstract class Declaration extends AstNode {
  const Declaration();
}

class ImportDecl extends Declaration {
  const ImportDecl(this.uri, {this.asName, this.show = const []});
  final String uri;
  final String? asName;
  final List<String> show;
}

class ClassDecl extends Declaration {
  ClassDecl({
    required this.name,
    this.extendsName,
    this.implements = const [],
    this.isAbstract = false,
    this.fields = const [],
    this.methods = const [],
    this.constructors = const [],
    this.withMixins = const [],
    this.documentation,
  });
  final String name;
  final String? extendsName;
  final List<String> implements;
  final List<String> withMixins;
  final bool isAbstract;
  final List<FieldDecl> fields;
  final List<MethodDecl> methods;
  final List<ConstructorDecl> constructors;
  final String? documentation;
}

class FieldDecl extends Declaration {
  const FieldDecl({
    required this.name,
    required this.type,
    this.modifier = 'final',
    this.initializer,
    this.documentation,
    this.isStatic = false,
  });
  final String name;
  final String type;
  final String modifier; // 'final', 'var', 'late'
  final Expression? initializer;
  final String? documentation;
  final bool isStatic;
}

class MethodDecl extends Declaration {
  MethodDecl({
    required this.name,
    this.returnType = 'void',
    this.parameters = const [],
    this.body = const [],
    this.isAsync = false,
    this.isStatic = false,
    this.documentation,
  });
  final String name;
  final String returnType;
  final List<ParameterDecl> parameters;
  final List<Statement> body;
  final bool isAsync;
  final bool isStatic;
  final String? documentation;
}

class ParameterDecl extends Declaration {
  const ParameterDecl({
    required this.name,
    required this.type,
    this.isRequired = false,
    this.named = true,
    this.defaultValue,
  });
  final String name;
  final String type;
  final bool isRequired;
  final bool named;
  final Expression? defaultValue;
}

class ConstructorDecl extends Declaration {
  const ConstructorDecl({
    required this.className,
    this.name,
    this.parameters = const [],
    this.initializers = const [],
    this.body = const [],
    this.isConst = false,
  });
  final String className;
  final String? name;
  final List<ParameterDecl> parameters;
  final List<String> initializers;
  final List<Statement> body;
  final bool isConst;
}

// --- Expressions ---

class LiteralExpr extends Expression {
  const LiteralExpr(this.value);
  final String value;
}

class StringLiteral extends Expression {
  const StringLiteral(this.value);
  final String value;
}

class NumberLiteral extends Expression {
  const NumberLiteral(this.value);
  final double value;
}

class BoolLiteral extends Expression {
  const BoolLiteral(this.value);
  final bool value;
}

class IdentifierExpr extends Expression {
  const IdentifierExpr(this.name);
  final String name;
}

class MemberExpr extends Expression {
  const MemberExpr(this.target, this.member);
  final Expression target;
  final String member;
}

class CallExpr extends Expression {
  const CallExpr({
    required this.target,
    this.arguments = const [],
    this.namedArguments = const {},
  });
  final Expression target;
  final List<Expression> arguments;
  final Map<String, Expression> namedArguments;
}

class ConstructorCall extends Expression {
  const ConstructorCall({
    required this.type,
    this.namedArguments = const {},
    this.isConst = false,
  });
  final String type;
  final Map<String, Expression> namedArguments;
  final bool isConst;
}

// --- Statements ---

class ReturnStatement extends Statement {
  const ReturnStatement([this.value]);
  final Expression? value;
}

class ExpressionStatement extends Statement {
  const ExpressionStatement(this.expression);
  final Expression expression;
}

class VariableDeclStatement extends Statement {
  const VariableDeclStatement({
    required this.type,
    required this.name,
    this.initializer,
  });
  final String type;
  final String name;
  final Expression? initializer;
}

class IfStatement extends Statement {
  const IfStatement({
    required this.condition,
    required this.thenBranch,
    this.elseBranch = const [],
  });
  final Expression condition;
  final List<Statement> thenBranch;
  final List<Statement> elseBranch;
}

class BlockStatement extends Statement {
  const BlockStatement(this.statements);
  final List<Statement> statements;
}
