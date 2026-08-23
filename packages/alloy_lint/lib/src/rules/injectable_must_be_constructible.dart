import 'package:alloy_analyzer/alloy_analyzer.dart';
import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

const _injectMatcher = AlloyAnnotationMatcher('AlloyInject');

/// Reports an `@AlloyInject` class the container cannot build — abstract, or
/// with no public generative constructor.
class InjectableMustBeConstructible extends AnalysisRule {
  /// Creates the rule.
  InjectableMustBeConstructible()
    : super(name: code.lowerCaseName, description: code.problemMessage);

  /// The diagnostic this rule reports.
  static const code = LintCode(
    'alloy_injectable_must_be_constructible',
    "Alloy cannot construct '{0}': {1}.",
    correctionMessage:
        'Give the class a public generative constructor, or register it '
        'manually and drop the @AlloyInject annotation.',
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
    if (element == null || !_injectMatcher.matches(element)) return;

    final name = node.namePart.typeName.lexeme;

    if (element.isAbstract) {
      rule.reportAtNode(node.namePart, arguments: [name, 'it is abstract']);
      return;
    }

    final hasUsableConstructor = element.constructors.any(
      (constructor) => constructor.isPublic && !constructor.isFactory,
    );

    if (!hasUsableConstructor) {
      rule.reportAtNode(
        node.namePart,
        arguments: [name, 'it has no public generative constructor'],
      );
    }
  }
}
