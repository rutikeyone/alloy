import 'package:alloy_lint/src/rules/dependency_is_not_registered.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DependencyIsNotRegisteredTest);
  });
}

@reflectiveTest
class DependencyIsNotRegisteredTest extends AnalysisRuleTest {
  @override
  void setUp() {
    stubAlloyAnnotations(this);
    rule = DependencyIsNotRegistered();
    super.setUp();
  }

  void test_registeredInTheSameFile_isClean() async {
    await assertNoDiagnostics('''
$alloyImport

@alloyInject
class Logger {}

@alloyInject
class Api {
  Api(this.logger);
  final Logger logger;
}
''');
  }

  void test_registeredInAnotherFile_isClean() async {
    newFile('$testPackageLibPath/logger.dart', '''
$alloyImport

@alloyInject
class Logger {}
''');

    await assertNoDiagnostics('''
$alloyImport

import 'logger.dart';

@alloyInject
class Api {
  Api(this.logger);
  final Logger logger;
}
''');
  }

  void test_exposedByAnotherClass_isClean() async {
    newFile('$testPackageLibPath/notes.dart', '''
$alloyImport

abstract interface class Notes {}

@AlloyInject(exposeAs: Notes)
class SqlNotes implements Notes {}
''');

    await assertNoDiagnostics('''
$alloyImport

import 'notes.dart';

@alloyInject
class Editor {
  Editor(this.notes);
  final Notes notes;
}
''');
  }

  void test_promisedByTheScopeRoot_isClean() async {
    newFile('$testPackageLibPath/app_scope.dart', '''
$alloyImport

import 'session.dart';

@AlloyScopeRoot(name: 'app', provides: [SessionManager])
class AppScope {
  const AppScope();
}
''');
    newFile('$testPackageLibPath/session.dart', '''
class SessionManager {}
''');

    await assertNoDiagnostics('''
$alloyImport

import 'session.dart';

@alloyInject
class Profile {
  Profile(this.session);
  final SessionManager session;
}
''');
  }

  void test_promisedByName_isClean() async {
    newFile('$testPackageLibPath/app_scope.dart', '''
$alloyImport

import 'audit.dart';

@AlloyScopeRoot(name: 'app', provides: [AlloyProvided(Auditor, name: 'audit')])
class AppScope {
  const AppScope();
}
''');
    newFile('$testPackageLibPath/audit.dart', '''
class Auditor {}
''');

    await assertNoDiagnostics('''
$alloyImport

import 'audit.dart';

@alloyInject
class Ledger {
  Ledger(this.auditor);
  final Auditor auditor;
}
''');
  }

  void test_nothingRegistersIt_isReported() async {
    newFile('$testPackageLibPath/http.dart', '''
class HttpClient {}
''');

    await assertDiagnostics(
      '''
$alloyImport

import 'http.dart';

@alloyInject
class Api {
  Api(this.client);
  final HttpClient client;
}
''',
      [lint(100, 3)],
    );
  }

  void test_anInjectedProperty_isReported() async {
    newFile('$testPackageLibPath/http.dart', '''
class HttpClient {}
''');

    await assertDiagnostics(
      '''
$alloyImport

import 'http.dart';

@alloyInject
class Api {
  Api();

  @injected
  late final HttpClient _client;
}
''',
      [lint(100, 3)],
    );
  }

  void test_dependsOn_isReported() async {
    newFile('$testPackageLibPath/database.dart', '''
class Database {}
''');

    await assertDiagnostics(
      '''
$alloyImport

import 'database.dart';

@AlloyInit(dependsOn: [Database])
class Index {
  Index();
  Future<void> init() async {}
}
''',
      [lint(125, 5)],
    );
  }

  void test_anUnannotatedClass_isClean() async {
    newFile('$testPackageLibPath/http.dart', '''
class HttpClient {}
''');

    await assertNoDiagnostics('''
$alloyImport

import 'http.dart';

@alloyInject
class Settings {}

class Api {
  Api(this.client);
  final HttpClient client;
}
''');
  }

  void test_aMalformedInjectable_isLeftToItsOwnRule() async {
    newFile('$testPackageLibPath/http.dart', '''
class HttpClient {}
''');

    await assertNoDiagnostics('''
$alloyImport

import 'http.dart';

@alloyInject
abstract class Api {
  Api(this.client);
  final HttpClient client;
}
''');
  }

  /// The index holds bare names, so a qualifier it cannot see never turns into
  /// a report. The build still rejects this graph — see the rule's doc for why
  /// the editor is deliberately the weaker of the two.
  void test_aNameTheRegistrationDoesNotCarry_isNotReported() async {
    await assertNoDiagnostics('''
$alloyImport

@alloyInject
class Logger {}

@alloyInject
class Api {
  Api(@Named('audit') this.logger);
  final Logger logger;
}
''');
  }

  void test_providedByAModuleInAnotherFile_isClean() async {
    newFile('$testPackageLibPath/network.dart', '''
$alloyImport

class Dio {}

@alloyModule
class NetworkModule {
  const NetworkModule();

  @alloyInject
  Dio dio() => Dio();
}
''');

    await assertNoDiagnostics('''
$alloyImport

import 'network.dart';

@alloyInject
class Api {
  Api(this.dio);
  final Dio dio;
}
''');
  }

  void test_providedAsyncByAModule_isClean() async {
    newFile('$testPackageLibPath/storage.dart', '''
$alloyImport

class Prefs {}

@alloyModule
class StorageModule {
  const StorageModule();

  @alloyInject
  Future<Prefs> get prefs async => Prefs();
}
''');

    await assertNoDiagnostics('''
$alloyImport

import 'storage.dart';

@alloyInject
class Settings {
  Settings(this.prefs);
  final Prefs prefs;
}
''');
  }

  void test_aModuleMemberWantingSomethingUnregistered_isReported() async {
    newFile('$testPackageLibPath/http.dart', '''
class HttpClient {}
class Dio {}
''');

    await assertDiagnostics(
      '''
$alloyImport

import 'http.dart';

@alloyModule
class NetworkModule {
  const NetworkModule();

  @alloyInject
  Dio dio(HttpClient client) => Dio();
}
''',
      [lint(100, 13)],
    );
  }

  /// Same reason: type arguments are not part of the index, so any
  /// `Repository` registration answers for every instantiation.
  void test_anotherInstantiationOfAGeneric_isNotReported() async {
    await assertNoDiagnostics('''
$alloyImport

class User {}
class Order {}

abstract interface class Repository<T> {}

@AlloyInject(exposeAs: Repository<User>)
class UserRepository implements Repository<User> {}

@alloyInject
class Catalog {
  Catalog(this.orders);
  final Repository<Order> orders;
}
''');
  }
}
