import 'package:alloy_analyzer/alloy_analyzer.dart';
import 'package:alloy_annotations/alloy_annotations.dart';
import 'package:alloy_generator/alloy_generator.dart';

const appImport = 'package:app/app.dart';

AlloyTypeRef ref(
  String name, {
  List<AlloyTypeRef> of = const [],
  bool isNullable = false,
}) => AlloyTypeRef(
  name: name,
  import: appImport,
  typeArguments: of,
  isNullable: isNullable,
);

AlloyInjectedProperty dep(
  String type, {
  String? name,
  bool isNullable = false,
  bool isNamed = false,
  String? field,
}) => AlloyInjectedProperty(
  field: field ?? type.toLowerCase(),
  type: ref(type, isNullable: isNullable),
  name: name,
  isNamed: isNamed,
);

/// A constructor parameter the call site supplies, as `@AlloyParam` marks it.
AlloyInjectedProperty arg(String field, String type, {bool isNamed = true}) =>
    AlloyInjectedProperty(
      field: field,
      type: AlloyTypeRef(name: type, import: 'dart:core'),
      isNamed: isNamed,
      isParam: true,
    );

AlloyInjectableClass declare(
  String type, {
  AlloyLifetime lifetime = AlloyLifetime.lazySingleton,
  List<AlloyInjectedProperty> constructor = const [],
  List<AlloyInjectedProperty> properties = const [],
  String? name,
  AlloyTypeRef? exposeAs,
  bool isAsyncInit = false,
  List<AlloyTypeRef> dependsOn = const [],
  Set<String> environments = const {},
}) => AlloyInjectableClass(
  type: ref(type),
  lifetime: lifetime,
  constructorParameters: constructor,
  properties: properties,
  name: name,
  exposeAs: exposeAs,
  isAsyncInit: isAsyncInit,
  dependsOn: dependsOn,
  environments: environments,
);

AlloyBootstrapStepClass step(
  String type, {
  int order = 0,
  Set<String> environments = const {},
}) => AlloyBootstrapStepClass(
  type: ref(type),
  order: order,
  environments: environments,
);

AlloyInjectableClass provide(
  String module,
  String member,
  String returns, {
  AlloyLifetime lifetime = AlloyLifetime.lazySingleton,
  List<AlloyInjectedProperty> parameters = const [],
  String? name,
  AlloyTypeRef? exposeAs,
  bool isAsyncInit = false,
  bool isGetter = false,
  Set<String> environments = const {},
  AlloyFunctionRef? dispose,
}) => AlloyInjectableClass(
  type: ref(returns),
  lifetime: lifetime,
  constructorParameters: parameters,
  properties: const [],
  name: name,
  exposeAs: exposeAs,
  isAsyncInit: isAsyncInit,
  environments: environments,
  provider: AlloyProviderRef(
    module: ref(module),
    member: member,
    isGetter: isGetter,
  ),
  dispose: dispose,
);

AlloyProvidedRef provided(String type, {String? name}) =>
    AlloyProvidedRef(type: ref(type), name: name);

AlloyScopeRootClass scopeRoot(
  String type, {
  String name = 'root',
  List<AlloyProvidedRef> provides = const [],
}) => AlloyScopeRootClass(type: ref(type), name: name, provides: provides);

String generate(
  List<AlloyInjectableClass> injectables, {
  List<AlloyBootstrapStepClass> bootstrap = const [],
  List<AlloyScopeRootClass> scopeRoots = const [],
}) => const ContainerSourceEmitter().emit(
  AlloyLibraryDeclarations(
    injectables: injectables,
    bootstrapSteps: bootstrap,
    scopeRoots: scopeRoots,
  ),
);

List<String> registrationsOf(String source) => source
    .split('\n')
    .map((line) => line.trim())
    .where((line) => line.startsWith('scope.register'))
    .toList();
