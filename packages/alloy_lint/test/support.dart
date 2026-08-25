import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';

const alloyAnnotationsStub = r'''
class AlloyInject {
  const AlloyInject({this.name, this.exposeAs});
  final String? name;
  final Type? exposeAs;
}

const alloyInject = AlloyInject();

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

class AlloyEnvironment {
  const AlloyEnvironment(this.name);
  final String name;
  static const dev = AlloyEnvironment('dev');
  static const prod = AlloyEnvironment('prod');
}
''';

const alloyImport =
    "import 'package:alloy_annotations/alloy_annotations.dart';";

void stubAlloyAnnotations(AnalysisRuleTest test) {
  test
      .newPackage('alloy_annotations')
      .addFile('lib/alloy_annotations.dart', alloyAnnotationsStub);
}
