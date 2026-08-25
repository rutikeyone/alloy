import 'package:alloy_analyzer/alloy_analyzer.dart';
import 'package:alloy_lint/src/registration_index.dart';
import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Reports a dependency of an injectable class that nothing in the package
/// registers.
///
/// The build already rejects such a graph. This is the same answer earlier, in
/// the editor, from a coarser view — see [AlloyRegistrationIndex] for what the
/// rule cannot see and why it errs towards silence.
class DependencyIsNotRegistered extends AnalysisRule {
  /// Creates the rule.
  DependencyIsNotRegistered()
    : super(name: code.lowerCaseName, description: code.problemMessage);

  /// The diagnostic this rule reports.
  static const code = LintCode(
    'alloy_dependency_is_not_registered',
    "'{0}' needs '{1}', which nothing in this package registers.",
    correctionMessage:
        'Annotate the class that provides it with @AlloyInject, or name it in '
        '@AlloyScopeRoot(provides: [...]) when something outside the generated '
        'container registers it.',
  );

  final _cache = AlloyRegistrationIndexCache();

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) => registry.addClassDeclaration(this, _Visitor(this, context, _cache));
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context, this._cache);

  static const _parser = AlloyInjectableParser();

  final AnalysisRule rule;
  final RuleContext context;
  final AlloyRegistrationIndexCache _cache;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final element = node.declaredFragment?.element;
    if (element == null || !_parser.declares(element)) return;

    final AlloyInjectableClass declaration;
    try {
      declaration = _parser.parseClass(element);
    } on AlloyParseError {
      // A malformed declaration is somebody else's rule to report, and its
      // dependency list cannot be trusted.
      return;
    }

    final index = _index();
    if (index == null) return;

    final wanted = {
      for (final parameter in declaration.constructorParameters) parameter.type,
      for (final property in declaration.properties) property.type,
      ...declaration.dependsOn,
    };

    for (final type in wanted) {
      if (index.contains(type.name)) continue;
      rule.reportAtNode(
        node.namePart,
        arguments: [node.namePart.typeName.lexeme, type.name],
      );
      return;
    }
  }

  AlloyRegistrationIndex? _index() {
    final root = context.package?.root;
    final session = context.libraryElement?.session;
    if (root == null || session == null) return null;
    return _cache.of(root, session);
  }
}
