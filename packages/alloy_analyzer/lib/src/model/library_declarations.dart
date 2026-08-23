import 'package:alloy_analyzer/src/model/bootstrap_step_class.dart';
import 'package:alloy_analyzer/src/model/injectable_class.dart';
import 'package:alloy_analyzer/src/model/scope_root_class.dart';

class AlloyLibraryDeclarations {
  const AlloyLibraryDeclarations({
    this.injectables = const [],
    this.bootstrapSteps = const [],
    this.scopeRoots = const [],
  });

  factory AlloyLibraryDeclarations.fromJson(Map<String, dynamic> json) =>
      AlloyLibraryDeclarations(
        injectables: [
          for (final i in json['injectables'] as List<dynamic>? ?? const [])
            AlloyInjectableClass.fromJson(i as Map<String, dynamic>),
        ],
        bootstrapSteps: [
          for (final b in json['bootstrapSteps'] as List<dynamic>? ?? const [])
            AlloyBootstrapStepClass.fromJson(b as Map<String, dynamic>),
        ],
        scopeRoots: [
          for (final r in json['scopeRoots'] as List<dynamic>? ?? const [])
            AlloyScopeRootClass.fromJson(r as Map<String, dynamic>),
        ],
      );

  final List<AlloyInjectableClass> injectables;
  final List<AlloyBootstrapStepClass> bootstrapSteps;
  final List<AlloyScopeRootClass> scopeRoots;

  bool get isEmpty =>
      injectables.isEmpty && bootstrapSteps.isEmpty && scopeRoots.isEmpty;

  Map<String, dynamic> toJson() => {
    'injectables': [for (final i in injectables) i.toJson()],
    'bootstrapSteps': [for (final b in bootstrapSteps) b.toJson()],
    'scopeRoots': [for (final r in scopeRoots) r.toJson()],
  };
}
