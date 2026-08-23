import 'dart:convert';

import 'package:alloy_analyzer/alloy_analyzer.dart';
import 'package:alloy_generator/src/emitters/container_source_emitter.dart';
import 'package:build/build.dart';
import 'package:glob/glob.dart';

/// Aggregates every per-library IR file into one container.
///
/// Runs once per package against the synthetic `$lib$` input, because the
/// container is a whole-program artifact that no single library owns.
class AlloyContainerBuilder implements Builder {
  const AlloyContainerBuilder();

  static const _emitter = ContainerSourceEmitter();

  @override
  Map<String, List<String>> get buildExtensions => const {
    r'$lib$': ['alloy.g.dart'],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    final injectables = <AlloyInjectableClass>[];
    final bootstrapSteps = <AlloyBootstrapStepClass>[];
    final scopeRoots = <AlloyScopeRootClass>[];

    await for (final id in buildStep.findAssets(Glob('lib/**.alloy.json'))) {
      final decoded = AlloyLibraryDeclarations.fromJson(
        jsonDecode(await buildStep.readAsString(id)) as Map<String, dynamic>,
      );
      injectables.addAll(decoded.injectables);
      bootstrapSteps.addAll(decoded.bootstrapSteps);
      scopeRoots.addAll(decoded.scopeRoots);
    }

    final declarations = AlloyLibraryDeclarations(
      injectables: injectables,
      bootstrapSteps: bootstrapSteps,
      scopeRoots: scopeRoots,
    );
    if (declarations.isEmpty) return;

    await buildStep.writeAsString(
      AssetId(buildStep.inputId.package, 'lib/alloy.g.dart'),
      _emitter.emit(declarations),
    );
  }
}
