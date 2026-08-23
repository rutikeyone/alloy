import 'package:alloy_analyzer/alloy_analyzer.dart';
import 'package:alloy_generator/src/emitters/alloy_references.dart';
import 'package:code_builder/code_builder.dart';

class BootstrapEmitter {
  const BootstrapEmitter();

  /// Emits `$alloyBootstrap` as a getter rather than a stored list, so every
  /// startup gets fresh step instances. A top-level `final` would build them
  /// once per process, which quietly shares state between a retried startup
  /// and between tests, and leaves them alive after the scope that adopted
  /// them is gone.
  ///
  /// When any step names an environment it becomes a function of the chosen
  /// environment instead, because the list is then no longer the same for
  /// every build.

  Method emit(
    List<AlloyBootstrapStepClass> steps, {
    required bool usesEnvironments,
  }) {
    final ordered = [...steps]
      ..sort((a, b) {
        final byOrder = a.order.compareTo(b.order);
        return byOrder != 0 ? byOrder : a.type.name.compareTo(b.type.name);
      });

    return Method(
      (m) => m
        ..name = r'$alloyBootstrap'
        ..type = usesEnvironments ? null : MethodType.getter
        ..requiredParameters.addAll([
          if (usesEnvironments)
            Parameter(
              (p) => p
                ..name = 'environment'
                ..type = alloyRef('AlloyEnvironment'),
            ),
        ])
        ..returns = TypeReference(
          (b) => b
            ..symbol = 'List'
            ..url = 'dart:core'
            ..types.add(alloyRef('AlloyBootstrapStep')),
        )
        ..lambda = true
        ..body = Block.of([
          const Code('['),
          for (final step in ordered) ...[
            if (step.environments.isNotEmpty) ...[
              const Code('if ('),
              environmentGuard(step.environments).code,
              const Code(') '),
            ],
            typeReferenceOf(step.type).newInstance(const []).code,
            const Code(','),
          ],
          const Code(']'),
        ]),
    );
  }
}
