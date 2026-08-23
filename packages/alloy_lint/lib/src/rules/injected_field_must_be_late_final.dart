import 'package:alloy_analyzer/alloy_analyzer.dart';
import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

const _injectedMatcher = AlloyAnnotationMatcher('Injected');

/// Reports an `@injected` field that is not `late final`.
///
/// `late` is what lets the mixin assign the field after construction, and
/// `final` is what stops anything else from overwriting an injected value.
class InjectedFieldMustBeLateFinal extends AnalysisRule {
  /// Creates the rule.
  InjectedFieldMustBeLateFinal()
    : super(name: code.lowerCaseName, description: code.problemMessage);

  /// The diagnostic this rule reports.
  static const code = LintCode(
    'alloy_injected_field_must_be_late_final',
    "An @injected field must be declared 'late final'.",
    correctionMessage:
        "Declare the field as 'late final', so injection happens once and "
        'the value cannot be replaced afterwards.',
  );

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) => registry.addFieldDeclaration(this, _Visitor(this));
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AnalysisRule rule;

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    final element = node.fields.variables.first.declaredFragment?.element;
    if (element == null || !_injectedMatcher.matches(element)) return;

    if (node.isStatic || !node.fields.isLate || !node.fields.isFinal) {
      rule.reportAtNode(node);
    }
  }
}
