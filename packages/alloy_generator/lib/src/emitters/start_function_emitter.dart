import 'package:alloy_analyzer/alloy_analyzer.dart';
import 'package:alloy_generator/src/emitters/alloy_references.dart';
import 'package:alloy_generator/src/errors/alloy_generation_error.dart';
import 'package:code_builder/code_builder.dart';

class StartFunctionEmitter {
  const StartFunctionEmitter();

  static const defaultScopeName = 'root';

  String resolveName(List<AlloyScopeRootClass> roots) {
    if (roots.isEmpty) return defaultScopeName;
    if (roots.length > 1) {
      final names = ([
        for (final root in roots) root.type.name,
      ]..sort()).join(', ');
      throw AlloyGenerationError(
        'Found ${roots.length} classes annotated with @AlloyScopeRoot: $names. '
        'A package can declare at most one root scope.',
      );
    }
    return roots.single.name;
  }

  Field emitName(String name) => Field(
    (f) => f
      ..name = r'$alloyRootScopeName'
      ..modifier = FieldModifier.constant
      ..type = refer('String', 'dart:core')
      ..assignment = literalString(name).code,
  );

  Method emitStart({
    required bool hasBootstrap,
    required bool scopeUsesEnvironments,
    required bool bootstrapUsesEnvironments,
  }) {
    final usesEnvironments = scopeUsesEnvironments || bootstrapUsesEnvironments;
    final environment = refer('environment');

    return Method(
      (m) => m
        ..name = r'$startAlloy'
        ..optionalParameters.addAll([
          if (usesEnvironments)
            Parameter(
              (p) => p
                ..name = 'environment'
                ..named = true
                ..type = alloyRef('AlloyEnvironment')
                ..defaultTo = defaultEnvironment.code,
            ),
        ])
        ..returns = TypeReference(
          (b) => b
            ..symbol = 'Future'
            ..url = 'dart:async'
            ..types.add(alloyRef('AlloyScope')),
        )
        ..lambda = true
        ..body = alloyRef('AlloyApplication').property('start').call(const [], {
          'root': scopeUsesEnvironments
              ? refer(r'$AlloyRootScope')
                    .newInstance(const [], {'environment': environment})
              : refer(r'$AlloyRootScope').constInstance(const []),
          if (hasBootstrap)
            'bootstrap': bootstrapUsesEnvironments
                ? refer(r'$alloyBootstrap').call([environment])
                : refer(r'$alloyBootstrap'),
          'rootName': refer(r'$alloyRootScopeName'),
        }).code,
    );
  }
}
