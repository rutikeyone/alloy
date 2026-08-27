import 'package:alloy_lint/src/rules/param_needs_an_injectable.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ParamNeedsAnInjectableTest);
  });
}

@reflectiveTest
class ParamNeedsAnInjectableTest extends AnalysisRuleTest {
  @override
  void setUp() {
    stubAlloyAnnotations(this);
    rule = ParamNeedsAnInjectable();
    super.setUp();
  }

  void test_unregisteredClass_isReported() async {
    await assertDiagnostics(
      r'''
import 'package:alloy_annotations/alloy_annotations.dart';

class Orphan {
  Orphan({@alloyParam required this.id});

  final int id;
}
''',
      [lint(85, 28)],
    );
  }

  void test_injectableClass_isClean() async {
    await assertNoDiagnostics(r'''
import 'package:alloy_annotations/alloy_annotations.dart';

@alloyInject
class Editor {
  Editor({@alloyParam required this.id});

  final int id;
}
''');
  }

  void test_noMarking_isClean() async {
    await assertNoDiagnostics(r'''
class Plain {
  Plain(this.id);

  final int id;
}
''');
  }

  /// A module member with the marking is a build failure with a message of its
  /// own, so this rule stays out of the way.
  void test_module_isLeftToTheBuild() async {
    await assertNoDiagnostics(r'''
import 'package:alloy_annotations/alloy_annotations.dart';

class Channel {}

@alloyModule
class PlatformModule {
  const PlatformModule();

  @alloyInject
  Channel channel(@alloyParam int id) => Channel();
}
''');
  }
}
