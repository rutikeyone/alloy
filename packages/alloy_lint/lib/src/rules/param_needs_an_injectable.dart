import 'package:alloy_analyzer/alloy_analyzer.dart';
import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Reports `@AlloyParam` on a class the container never registers.
///
/// The annotation only means something to the generator: it turns a class into
/// a parameterized registration and writes the record type the call site
/// passes. On a class that says nothing, it is read by nobody — the class is
/// constructed by hand as before, and the marking is decoration.
///
/// The sibling of `alloy_injected_field_needs_an_injectable`, for the same
/// reason: an annotation that quietly does nothing is worse than one that is
/// missing, because it reads as though it did.
class ParamNeedsAnInjectable extends AnalysisRule {
  /// Creates the rule.
  ParamNeedsAnInjectable()
    : super(name: code.lowerCaseName, description: code.problemMessage);

  /// The diagnostic this rule reports.
  static const code = LintCode(
    'alloy_param_needs_an_injectable',
    "'{0}' is marked @AlloyParam, but nothing registers '{1}'.",
    correctionMessage:
        'Annotate the class with @AlloyInject so the generator writes a '
        'parameterized factory for it, or drop @AlloyParam — on a class the '
        'container does not know, it does nothing.',
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

  static const _parser = AlloyInjectableParser();
  static const _modules = AlloyModuleParser();

  final AnalysisRule rule;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final element = node.declaredFragment?.element;
    if (element == null) return;
    if (_parser.declares(element) || _modules.declares(element)) return;

    final name = node.namePart.typeName.lexeme;
    for (final member in node.body.members) {
      if (member is! ConstructorDeclaration) continue;
      for (final parameter in member.parameters.parameters) {
        if (!_isMarked(parameter)) continue;
        rule.reportAtNode(
          parameter,
          arguments: [parameter.name?.lexeme ?? '', name],
        );
      }
    }
  }

  static bool _isMarked(FormalParameter parameter) =>
      parameter.metadata.any((annotation) {
        final name = annotation.name.name.split('.').last;
        return name == 'AlloyParam' || name == 'alloyParam';
      });
}
