import 'package:alloy_lint/src/rules/missing_injection_mixin.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MissingInjectionMixinTest);
  });
}

@reflectiveTest
class MissingInjectionMixinTest extends AnalysisRuleTest {
  @override
  void setUp() {
    stubAlloyAnnotations(this);
    rule = MissingInjectionMixin();
    super.setUp();
  }

  void test_missingMixin_isReported() async {
    await assertDiagnostics(
      r'''
import 'package:alloy_annotations/alloy_annotations.dart';

@alloyInject
class Bloc {
  @injected
  late final String value;
}
''',
      [lint(79, 4)],
    );
  }

  void test_mixinPresent_isClean() async {
    await assertNoDiagnostics(r'''
import 'package:alloy_annotations/alloy_annotations.dart';

mixin _$Bloc {}

@alloyInject
class Bloc with _$Bloc {
  @injected
  late final String value;
}
''');
  }

  void test_noInjectedFields_isClean() async {
    await assertNoDiagnostics(r'''
import 'package:alloy_annotations/alloy_annotations.dart';

@alloyInject
class Service {
  final String value = '';
}
''');
  }

  /// The mixin is written only for a class the container registers, so on a
  /// class nothing registers this rule stays quiet and
  /// `alloy_injected_field_needs_an_injectable` speaks instead.
  void test_classNothingRegisters_isNotThisRule() async {
    await assertNoDiagnostics(r'''
import 'package:alloy_annotations/alloy_annotations.dart';

class Orphan {
  @injected
  late final String value;
}
''');
  }

  void test_asyncInitClass_isReportedToo() async {
    await assertDiagnostics(
      r'''
import 'package:alloy_annotations/alloy_annotations.dart';

@AlloyInit()
class Warmer {
  @injected
  late final String value;
}
''',
      [lint(79, 6)],
    );
  }
}
