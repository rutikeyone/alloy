import 'package:alloy_analyzer/src/model/bootstrap_step_class.dart';
import 'package:alloy_analyzer/src/parser/alloy_matchers.dart';
import 'package:alloy_analyzer/src/parser/dart_object_reader.dart';
import 'package:alloy_analyzer/src/parser/environment_reader.dart';
import 'package:alloy_analyzer/src/parser/parse_error.dart';
import 'package:alloy_analyzer/src/parser/type_ref_resolver.dart';
import 'package:analyzer/dart/element/element.dart';

class AlloyBootstrapParser {
  const AlloyBootstrapParser();

  bool declares(ClassElement clazz) => bootstrapMatcher.matches(clazz);

  AlloyBootstrapStepClass parseClass(ClassElement clazz) {
    final annotation = bootstrapMatcher.firstOf(clazz)!;

    if (clazz.isAbstract) {
      throw AlloyParseError(
        '${clazz.displayName} is abstract and cannot be a bootstrap step.',
        clazz,
      );
    }

    final constructor = clazz.constructors
        .where((c) => c.isPublic && !c.isFactory)
        .firstOrNull;

    if (constructor == null) {
      throw AlloyParseError(
        '${clazz.displayName} has no public generative constructor.',
        clazz,
      );
    }

    if (constructor.formalParameters.any((p) => p.isRequired)) {
      throw AlloyParseError(
        '${clazz.displayName} must have a constructor without required '
        'parameters. Bootstrap steps run before the container exists, so they '
        'cannot receive injected dependencies.',
        clazz,
      );
    }

    if (!_hasRunMethod(clazz)) {
      throw AlloyParseError(
        '${clazz.displayName} is annotated with @AlloyBootstrap but declares '
        "no 'run()' method. Implement AlloyBootstrapStep.",
        clazz,
      );
    }

    return AlloyBootstrapStepClass(
      type: typeRefOfElement(clazz),
      order: annotation.readInt('order') ?? 0,
      environments: environmentsOf(clazz),
    );
  }

  bool _hasRunMethod(ClassElement clazz) =>
      clazz.methods.any((method) => method.name == 'run') ||
      clazz.allSupertypes.any(
        (supertype) => supertype.methods.any((method) => method.name == 'run'),
      );
}
