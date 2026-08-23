import 'package:alloy_analyzer/alloy_analyzer.dart';
import 'package:alloy_generator/src/emitters/bootstrap_emitter.dart';
import 'package:alloy_generator/src/emitters/injectable_factory_emitter.dart';
import 'package:alloy_generator/src/emitters/root_scope_emitter.dart';
import 'package:alloy_generator/src/emitters/start_function_emitter.dart';
import 'package:alloy_generator/src/errors/alloy_generation_error.dart';
import 'package:alloy_generator/src/hashed_allocator.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';

const _header = '// GENERATED CODE - DO NOT MODIFY BY HAND';

class ContainerSourceEmitter {
  const ContainerSourceEmitter();

  static const _factories = InjectableFactoryEmitter();
  static const _rootScope = RootScopeEmitter();
  static const _bootstrap = BootstrapEmitter();
  static const _start = StartFunctionEmitter();

  String emit(AlloyLibraryDeclarations declarations) {
    final injectables = [...declarations.injectables]
      ..sort((a, b) {
        final byKey = _keyOf(a).compareTo(_keyOf(b));
        return byKey != 0 ? byKey : a.type.name.compareTo(b.type.name);
      });

    _assertNoEnvironmentConflicts(injectables);

    final scopeName = _start.resolveName(declarations.scopeRoots);
    final hasBootstrap = declarations.bootstrapSteps.isNotEmpty;
    final scopeUsesEnvironments = injectables.any(
      (declaration) => declaration.environments.isNotEmpty,
    );
    final bootstrapUsesEnvironments = declarations.bootstrapSteps.any(
      (step) => step.environments.isNotEmpty,
    );

    final library = Library(
      (b) => b
        ..body.addAll([
          for (final declaration in injectables) _factories.emit(declaration),
          if (injectables.isNotEmpty)
            _rootScope.emit(
              _ordered(injectables),
              usesEnvironments: scopeUsesEnvironments,
            ),
          if (hasBootstrap)
            _bootstrap.emit(
              declarations.bootstrapSteps,
              usesEnvironments: bootstrapUsesEnvironments,
            ),
          if (injectables.isNotEmpty) ...[
            _start.emitName(scopeName),
            _start.emitStart(
              hasBootstrap: hasBootstrap,
              scopeUsesEnvironments: scopeUsesEnvironments,
              bootstrapUsesEnvironments: bootstrapUsesEnvironments,
            ),
          ],
        ]),
    );

    final emitted = library.accept(
      DartEmitter(
        allocator: HashedAllocator(),
        orderDirectives: true,
        useNullSafetySyntax: true,
      ),
    );

    return DartFormatter(languageVersion: DartFormatter.latestLanguageVersion)
        .format('$_header\n\n$emitted');
  }

  List<AlloyInjectableClass> _ordered(List<AlloyInjectableClass> injectables) {
    final byKey = _groupByKey(injectables);

    final levels = layeredTopologicalSort<AlloyInjectableClass>(
      injectables,
      (declaration) => [
        for (final dependency in _dependenciesOf(declaration))
          ...?byKey[dependency],
      ],
      labelOf: (declaration) => declaration.type.name,
    );

    return [for (final level in levels) ...level];
  }

  /// Rejects a graph where two registrations of the same type could be active
  /// at once.
  ///
  /// Without environments a duplicate is always a mistake. With them it is a
  /// mistake only when the environments overlap — or when one side names none,
  /// since an unrestricted registration is present in every environment.
  void _assertNoEnvironmentConflicts(List<AlloyInjectableClass> injectables) {
    for (final group in _groupByKey(injectables).values) {
      for (var i = 0; i < group.length; i++) {
        for (var j = i + 1; j < group.length; j++) {
          final first = group[i];
          final second = group[j];
          if (!_canCoexist(first.environments, second.environments)) continue;
          throw AlloyGenerationError(_conflictMessage(first, second));
        }
      }
    }
  }

  static String _conflictMessage(
    AlloyInjectableClass first,
    AlloyInjectableClass second,
  ) {
    final exposed = first.exposedType.name;
    final named = first.name == null ? '' : " named '${first.name}'";
    final where = _overlapDescription(first.environments, second.environments);
    return '${first.type.name} and ${second.type.name} both register '
        '$exposed$named$where. Give them environments that do not overlap, '
        'or expose one of them as a different type.';
  }

  static String _overlapDescription(Set<String> first, Set<String> second) {
    if (first.isEmpty && second.isEmpty) return '';
    if (first.isEmpty || second.isEmpty) {
      final restricted = first.isEmpty ? second : first;
      final names = (restricted.toList()..sort()).join(', ');
      return ', and one of them names no environment, so both are active in '
          '$names';
    }
    final shared = (first.intersection(second).toList()..sort()).join(', ');
    return ' in $shared';
  }

  static bool _canCoexist(Set<String> first, Set<String> second) =>
      first.isEmpty || second.isEmpty || first.intersection(second).isNotEmpty;

  static Map<String, List<AlloyInjectableClass>> _groupByKey(
    List<AlloyInjectableClass> injectables,
  ) {
    final byKey = <String, List<AlloyInjectableClass>>{};
    for (final declaration in injectables) {
      byKey.putIfAbsent(_keyOf(declaration), () => []).add(declaration);
    }
    return byKey;
  }

  Iterable<String> _dependenciesOf(AlloyInjectableClass declaration) => [
    for (final parameter in declaration.constructorParameters)
      _refKey(parameter.type, parameter.name),
    for (final property in declaration.properties)
      _refKey(property.type, property.name),
    for (final dependency in declaration.dependsOn) _refKey(dependency, null),
  ];

  static String _keyOf(AlloyInjectableClass declaration) =>
      _refKey(declaration.exposedType, declaration.name);

  static String _refKey(AlloyTypeRef type, String? name) =>
      '${type.signature}#${name ?? ''}';
}
