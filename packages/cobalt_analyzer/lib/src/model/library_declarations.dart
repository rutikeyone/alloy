import 'package:cobalt_analyzer/src/model/bootstrap_step_class.dart';
import 'package:cobalt_analyzer/src/model/injectable_class.dart';
import 'package:cobalt_analyzer/src/model/scope_root_class.dart';

class CobaltLibraryDeclarations {
  const CobaltLibraryDeclarations({
    this.injectables = const [],
    this.bootstrapSteps = const [],
    this.scopeRoots = const [],
  });

  factory CobaltLibraryDeclarations.fromJson(Map<String, dynamic> json) =>
      CobaltLibraryDeclarations(
        injectables: [
          for (final i in json['injectables'] as List<dynamic>? ?? const [])
            CobaltInjectableClass.fromJson(i as Map<String, dynamic>),
        ],
        bootstrapSteps: [
          for (final b in json['bootstrapSteps'] as List<dynamic>? ?? const [])
            CobaltBootstrapStepClass.fromJson(b as Map<String, dynamic>),
        ],
        scopeRoots: [
          for (final r in json['scopeRoots'] as List<dynamic>? ?? const [])
            CobaltScopeRootClass.fromJson(r as Map<String, dynamic>),
        ],
      );

  final List<CobaltInjectableClass> injectables;
  final List<CobaltBootstrapStepClass> bootstrapSteps;
  final List<CobaltScopeRootClass> scopeRoots;

  bool get isEmpty =>
      injectables.isEmpty && bootstrapSteps.isEmpty && scopeRoots.isEmpty;

  Map<String, dynamic> toJson() => {
    'injectables': [for (final i in injectables) i.toJson()],
    'bootstrapSteps': [for (final b in bootstrapSteps) b.toJson()],
    'scopeRoots': [for (final r in scopeRoots) r.toJson()],
  };
}
