import 'package:alloy_lint/src/rules/injected_field_must_be_late_final.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InjectedFieldMustBeLateFinalTest);
  });
}

@reflectiveTest
class InjectedFieldMustBeLateFinalTest extends AnalysisRuleTest {
  @override
  void setUp() {
    stubAlloyAnnotations(this);
    rule = InjectedFieldMustBeLateFinal();
    super.setUp();
  }

  void test_lateFinal_isClean() async {
    await assertNoDiagnostics('''
$alloyImport

class Bloc {
  @injected
  late final String value;
}
''');
  }

  void test_mutableField_isReported() async {
    await assertDiagnostics(
      '''
$alloyImport

class Bloc {
  @injected
  String? value;
}
''',
      [lint(75, 26)],
    );
  }

  void test_finalWithoutLate_isReported() async {
    await assertDiagnostics(
      '''
$alloyImport

class Bloc {
  @injected
  final String value = '';
}
''',
      [lint(75, 36)],
    );
  }

  void test_staticField_isReported() async {
    await assertDiagnostics(
      '''
$alloyImport

class Bloc {
  @injected
  static late final String value = '';
}
''',
      [lint(75, 48)],
    );
  }

  void test_unannotatedField_isClean() async {
    await assertNoDiagnostics(r'''
class Bloc {
  String? value;
}
''');
  }
}
