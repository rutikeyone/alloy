// `test_reflective_loader` finds tests by a `test_` prefix, which is not a
// Dart identifier name. The rule is off per file rather than through a
// `test/analysis_options.yaml`: that file had to `include` the repository
// root, and a copy of this package taken out of the tree — which
// tool/floor_check.sh does — cannot reach it.
// ignore_for_file: non_constant_identifier_names

import 'package:alloy_lint/src/rules/bootstrap_requires_run_method.dart';
import 'package:alloy_lint/src/rules/bootstrap_step_cannot_inject.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BootstrapRequiresRunMethodTest);
    defineReflectiveTests(BootstrapStepCannotInjectTest);
  });
}

@reflectiveTest
class BootstrapRequiresRunMethodTest extends AnalysisRuleTest {
  @override
  void setUp() {
    stubAlloyAnnotations(this);
    rule = BootstrapRequiresRunMethod();
    super.setUp();
  }

  void test_withRunMethod_isClean() async {
    await assertNoDiagnostics('''
$alloyImport

@alloyBootstrap
class BindPlatform {
  String get name => 'bind';
  void run() {}
}
''');
  }

  void test_missingRunMethod_isReported() async {
    await assertDiagnostics(
      '''
$alloyImport

@alloyBootstrap
class BindPlatform {
  String get name => 'bind';
}
''',
      [lint(82, 12)],
    );
  }
}

@reflectiveTest
class BootstrapStepCannotInjectTest extends AnalysisRuleTest {
  @override
  void setUp() {
    stubAlloyAnnotations(this);
    rule = BootstrapStepCannotInject();
    super.setUp();
  }

  void test_noParameters_isClean() async {
    await assertNoDiagnostics('''
$alloyImport

@alloyBootstrap
class BindPlatform {
  BindPlatform();
  void run() {}
}
''');
  }

  void test_optionalParameters_areClean() async {
    await assertNoDiagnostics('''
$alloyImport

@alloyBootstrap
class BindPlatform {
  BindPlatform({this.verbose = false});
  final bool verbose;
  void run() {}
}
''');
  }

  void test_requiredParameter_isReported() async {
    await assertDiagnostics(
      '''
$alloyImport

class Logger {}

@alloyBootstrap
class BindPlatform {
  BindPlatform(this.logger);
  final Logger logger;
  void run() {}
}
''',
      [lint(99, 12)],
    );
  }
}
