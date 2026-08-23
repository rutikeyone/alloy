import 'package:alloy_lint/src/rules/injectable_must_be_constructible.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InjectableMustBeConstructibleTest);
  });
}

@reflectiveTest
class InjectableMustBeConstructibleTest extends AnalysisRuleTest {
  @override
  void setUp() {
    stubAlloyAnnotations(this);
    rule = InjectableMustBeConstructible();
    super.setUp();
  }

  void test_publicConstructor_isClean() async {
    await assertNoDiagnostics('''
$alloyImport

@alloyInject
class Service {
  Service();
}
''');
  }

  void test_implicitConstructor_isClean() async {
    await assertNoDiagnostics('''
$alloyImport

@alloyInject
class Service {}
''');
  }

  void test_abstractClass_isReported() async {
    await assertDiagnostics(
      '''
$alloyImport

@alloyInject
abstract class Service {}
''',
      [lint(88, 7)],
    );
  }

  void test_privateConstructorOnly_isReported() async {
    await assertDiagnostics(
      '''
$alloyImport

@alloyInject
class Service {
  Service._();
}
''',
      [lint(79, 7)],
    );
  }

  void test_unannotatedClass_isClean() async {
    await assertNoDiagnostics(r'''
abstract class Service {}
''');
  }
}
