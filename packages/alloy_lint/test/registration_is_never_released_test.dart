import 'package:alloy_lint/src/rules/registration_is_never_released.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RegistrationIsNeverReleasedTest);
  });
}

@reflectiveTest
class RegistrationIsNeverReleasedTest extends AnalysisRuleTest {
  @override
  void setUp() {
    stubAlloyAnnotations(this);
    stubAlloyRuntime(this);
    rule = RegistrationIsNeverReleased();
    super.setUp();
  }

  void test_disposeMethodWithoutTheInterface_isReported() async {
    await assertDiagnostics(
      '''
$alloyImport

@alloyInject
class Notes {
  void dispose() {}
}
''',
      [lint(79, 5)],
    );
  }

  void test_closeMethodWithoutTheInterface_isReported() async {
    await assertDiagnostics(
      '''
$alloyImport

@alloyInject
class Session {
  Future<void> close() async {}
}
''',
      [lint(79, 7)],
    );
  }

  void test_inheritedFromABaseClass_isReported() async {
    // The shape of every Bloc and every ChangeNotifier: the closing method
    // belongs to a base class the author did not write.
    await assertDiagnostics(
      '''
$alloyImport

abstract class Notifier {
  void dispose() {}
}

@alloyInject
class Notes extends Notifier {}
''',
      [lint(128, 5)],
    );
  }

  void test_declaringTheInterface_isClean() async {
    await assertNoDiagnostics('''
$alloyImport
$alloyRuntimeImport

@alloyInject
class Notes implements Disposable {
  @override
  void dispose() {}
}
''');
  }

  void test_declaringTheAsyncInterface_isClean() async {
    await assertNoDiagnostics('''
$alloyImport
$alloyRuntimeImport

@alloyInject
class Session implements AsyncDisposable {
  Future<void> close() async {}

  @override
  Future<void> dispose() => close();
}
''');
  }

  void test_namingADisposeFunction_isClean() async {
    await assertNoDiagnostics('''
$alloyImport

void closeNotes(Notes notes) {}

@AlloyInject(dispose: closeNotes)
class Notes {
  void dispose() {}
}
''');
  }

  void test_aTransient_isClean() async {
    // The scope never retains one, so there is nothing for it to release.
    await assertNoDiagnostics('''
$alloyImport

@alloyTransient
class Notes {
  void dispose() {}
}
''');
  }

  void test_aMethodThatIsNotATeardown_isClean() async {
    // `close` here answers something and takes an argument. Reporting it would
    // be the rule guessing at meaning from a name.
    await assertNoDiagnostics('''
$alloyImport

@alloyInject
class Notes {
  bool close(String reason) => true;
}
''');
  }

  void test_nothingToClose_isClean() async {
    await assertNoDiagnostics('''
$alloyImport

@alloyInject
class Notes {}
''');
  }

  void test_unregisteredClass_isClean() async {
    await assertNoDiagnostics(r'''
class Notes {
  void dispose() {}
}
''');
  }
}
