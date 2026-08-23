import 'package:alloy_analyzer/alloy_analyzer.dart';
import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Reports `@AlloyEnvironment` on a class that nothing registers.
///
/// The annotation narrows an existing registration. On a class the generator
/// never looks at it does nothing at all, which reads at a glance as though
/// the class were environment-specific when it is simply absent from the
/// graph.
class EnvironmentNeedsARegistration extends AnalysisRule {
  /// Creates the rule.
  EnvironmentNeedsARegistration()
    : super(name: code.lowerCaseName, description: code.problemMessage);

  /// The diagnostic this rule reports.
  static const code = LintCode(
    'alloy_environment_needs_a_registration',
    "'{0}' names an environment but is never registered.",
    correctionMessage:
        '@AlloyEnvironment restricts a registration to some environments. Add '
        '@AlloyInject, @AlloyInit or @AlloyBootstrap, or remove the '
        'environment.',
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
    if (element == null || !environmentMatcher.matches(element)) return;

    final registered =
        injectMatcher.matches(element) ||
        initMatcher.matches(element) ||
        bootstrapMatcher.matches(element);
    if (registered) return;

    rule.reportAtNode(
      node.namePart,
      arguments: [node.namePart.typeName.lexeme],
    );
  }
}
