import 'package:alloy_analyzer/alloy_analyzer.dart';
import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Reports a bootstrap step whose constructor takes required parameters.
///
/// Phase 0 runs before the container exists, so there is nothing to inject
/// from. Work that needs dependencies belongs in an `@AlloyInit` service.
class BootstrapStepCannotInject extends AnalysisRule {
  /// Creates the rule.
  BootstrapStepCannotInject()
    : super(name: code.lowerCaseName, description: code.problemMessage);

  /// The diagnostic this rule reports.
  static const code = LintCode(
    'alloy_bootstrap_step_cannot_inject',
    "'{0}' is a bootstrap step and cannot take required constructor "
        'parameters.',
    correctionMessage:
        'Bootstrap steps run before the container exists, so nothing can be '
        'injected into them. Move the work that needs dependencies into an '
        '@AlloyInit service.',
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

    final constructor = element.constructors
        .where((c) => c.isPublic && !c.isFactory)
        .firstOrNull;
    if (constructor == null) return;

    if (constructor.formalParameters.any((parameter) => parameter.isRequired)) {
      rule.reportAtNode(
        node.namePart,
        arguments: [node.namePart.typeName.lexeme],
      );
    }
  }
}
