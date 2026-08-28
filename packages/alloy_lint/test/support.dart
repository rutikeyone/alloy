import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';

const alloyAnnotationsStub = r'''
// The order matters: the parser reads this field by enum index, so a stub
// that lists them differently maps every lifetime to the wrong one and
// says nothing about it.
enum AlloyLifetime { transient, lazySingleton, singleton }

class AlloyInject {
  const AlloyInject({
    this.name,
    this.exposeAs,
    this.dispose,
    this.lifetime = AlloyLifetime.lazySingleton,
  });
  final String? name;
  final Type? exposeAs;
  final Function? dispose;
  final AlloyLifetime lifetime;
}

const alloyInject = AlloyInject();

const alloyTransient = AlloyInject(lifetime: AlloyLifetime.transient);

class Named {
  const Named(this.name);
  final String name;
}

class AlloyProvided {
  const AlloyProvided(this.type, {this.name});
  final Type type;
  final String? name;
}

class AlloyScopeRoot {
  const AlloyScopeRoot({this.name = 'root', this.provides = const <Object>[]});
  final String name;
  final List<Object> provides;
}

class AlloyParam {
  const AlloyParam();
}

const alloyParam = AlloyParam();

class Injected {
  const Injected({this.name});
  final String? name;
}

const injected = Injected();

class AlloyBootstrap {
  const AlloyBootstrap({this.order = 0});
  final int order;
}

const alloyBootstrap = AlloyBootstrap();

class AlloyInit {
  const AlloyInit({this.dependsOn = const <Type>[]});
  final List<Type> dependsOn;
}

const alloyInit = AlloyInit();

class AlloyModule {
  const AlloyModule();
}

const alloyModule = AlloyModule();

class AlloyEnvironment {
  const AlloyEnvironment(this.name);
  final String name;
  static const dev = AlloyEnvironment('dev');
  static const prod = AlloyEnvironment('prod');
}
''';

const alloyImport =
    "import 'package:alloy_annotations/alloy_annotations.dart';";

/// What the runtime recognises as closeable.
///
/// A stub rather than the real `package:alloy`, for the same reason the
/// annotations are one: these tests drive rules, not a resolver over the whole
/// workspace.
const alloyRuntimeStub = r'''
abstract interface class Disposable {
  void dispose();
}

abstract interface class AsyncDisposable {
  Future<void> dispose();
}
''';

const alloyRuntimeImport = "import 'package:alloy/alloy.dart';";

void stubAlloyRuntime(AnalysisRuleTest test) {
  test.newPackage('alloy').addFile('lib/alloy.dart', alloyRuntimeStub);
}

void stubAlloyAnnotations(AnalysisRuleTest test) {
  test
      .newPackage('alloy_annotations')
      .addFile('lib/alloy_annotations.dart', alloyAnnotationsStub);
}
