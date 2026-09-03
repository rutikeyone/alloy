// `test_reflective_loader` finds tests by a `test_` prefix, which is not a
// Dart identifier name. The rule is off per file rather than through a
// `test/analysis_options.yaml`: that file had to `include` the repository
// root, and a copy of this package taken out of the tree — which
// tool/floor_check.sh does — cannot reach it.
// ignore_for_file: non_constant_identifier_names

import 'package:alloy_lint/src/rules/init_requires_init_method.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InitRequiresInitMethodTest);
  });
}

@reflectiveTest
class InitRequiresInitMethodTest extends AnalysisRuleTest {
  @override
  void setUp() {
    stubAlloyAnnotations(this);
    rule = InitRequiresInitMethod();
    super.setUp();
  }

  void test_withInitMethod_isClean() async {
    await assertNoDiagnostics('''
$alloyImport

@alloyInit
class Database {
  Future<void> init() async {}
}
''');
  }

  void test_inheritedInitMethod_isClean() async {
    await assertNoDiagnostics('''
$alloyImport

abstract class Base {
  Future<void> init() async {}
}

@alloyInit
class Database extends Base {}
''');
  }

  void test_missingInitMethod_isReported() async {
    await assertDiagnostics(
      '''
$alloyImport

@alloyInit
class Database {}
''',
      [lint(77, 8)],
    );
  }

  void test_unannotatedClass_isClean() async {
    await assertNoDiagnostics(r'''
class Database {}
''');
  }
}
