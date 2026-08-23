import 'package:alloy_analyzer/alloy_analyzer.dart';
import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

/// Reports an `@AlloyInit` class with no `init()` method.
///
/// The generated factory awaits `init()`, so without it the annotation only
/// changes the lifetime and silently skips the initialization it promised.
class InitRequiresInitMethod extends AnalysisRule {
  /// Creates the rule.
  InitRequiresInitMethod()
    : super(name: code.lowerCaseName, description: code.problemMessage);

  /// The diagnostic this rule reports.
  static const code = LintCode(
    'alloy_init_requires_init_method',
    "'{0}' is annotated with @AlloyInit but declares no 'init()' method.",
    correctionMessage:
        "Implement AsyncInitializable and add 'Future<void> init()', or drop "
        'the @AlloyInit annotation.',
  );

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) => registry.addClassDeclaration(this, _Visitor(this));
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AnalysisRule rule;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final element = node.declaredFragment?.element;
    if (element == null || !initMatcher.matches(element)) return;

    if (_declaresInit(element)) return;

    rule.reportAtNode(
      node.namePart,
      arguments: [node.namePart.typeName.lexeme],
    );
  }

  bool _declaresInit(ClassElement element) =>
      element.methods.any((method) => method.name == 'init') ||
      element.allSupertypes.any(
        (supertype) => supertype.methods.any((method) => method.name == 'init'),
      );
}
