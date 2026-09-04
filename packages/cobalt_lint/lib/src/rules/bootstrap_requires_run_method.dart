import 'package:cobalt_analyzer/cobalt_analyzer.dart';
import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

/// Reports an `@CobaltBootstrap` class with no `run()` method, which cannot
/// satisfy `CobaltBootstrapStep`.
class BootstrapRequiresRunMethod extends AnalysisRule {
  /// Creates the rule.
  BootstrapRequiresRunMethod()
    : super(name: code.lowerCaseName, description: code.problemMessage);

  /// The diagnostic this rule reports.
  static const code = LintCode(
    'cobalt_bootstrap_requires_run_method',
    "'{0}' is annotated with @CobaltBootstrap but declares no 'run()' method.",
    correctionMessage:
        'Implement CobaltBootstrapStep, which requires a name getter and a '
        'run() method.',
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
    if (element == null || !bootstrapMatcher.matches(element)) return;

    if (_declaresRun(element)) return;

    rule.reportAtNode(
      node.namePart,
      arguments: [node.namePart.typeName.lexeme],
    );
  }

  bool _declaresRun(ClassElement element) =>
      element.methods.any((method) => method.name == 'run') ||
      element.allSupertypes.any(
        (supertype) => supertype.methods.any((method) => method.name == 'run'),
      );
}
