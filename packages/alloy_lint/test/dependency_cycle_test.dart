// `test_reflective_loader` finds tests by a `test_` prefix, which is not a
// Dart identifier name. The rule is off per file rather than through a
// `test/analysis_options.yaml`: that file had to `include` the repository
// root, and a copy of this package taken out of the tree — which
// tool/floor_check.sh does — cannot reach it.
// ignore_for_file: non_constant_identifier_names

import 'package:alloy_lint/src/rules/dependency_cycle.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DependencyCycleTest);
  });
}

@reflectiveTest
class DependencyCycleTest extends AnalysisRuleTest {
  @override
  void setUp() {
    stubAlloyAnnotations(this);
    rule = DependencyCycle();
    super.setUp();
  }

  void test_aChainThatEnds_isClean() async {
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

  void test_aDependencyNothingRegisters_isNotAnEdge() async {
    await assertNoDiagnostics('''
$alloyImport

@alloyInject
class Api {
  Api(this.client);
  final HttpClient client;
}

class HttpClient {}
''');
  }

  void test_aClassThatTakesItself_isReported() async {
    await assertDiagnostics(
      '''
$alloyImport

@alloyInject
class Api {
  Api(this.self);
  final Api self;
}
''',
      [lint(79, 3)],
    );
  }

  void test_twoClassesInOneFile_areBothReported() async {
    await assertDiagnostics(
      '''
$alloyImport

@alloyInject
class Api {
  Api(this.cache);
  final Cache cache;
}

@alloyInject
class Cache {
  Cache(this.api);
  final Api api;
}
''',
      [lint(79, 3), lint(147, 5)],
    );
  }

  void test_aLoopThatSpansFiles_isReported() async {
    newFile('$testPackageLibPath/cache.dart', '''
$alloyImport

import 'api.dart';

@alloyInject
class Cache {
  Cache(this.api);
  final Api api;
}
''');

    await assertDiagnostics(
      '''
$alloyImport

import 'cache.dart';

@alloyInject
class Api {
  Api(this.cache);
  final Cache cache;
}
''',
      [lint(101, 3)],
    );
  }

  /// Being next to a loop is not being in one.
  void test_aClassThatOnlyTouchesTheLoop_isClean() async {
    newFile('$testPackageLibPath/cache.dart', '''
$alloyImport

import 'api.dart';

@alloyInject
class Cache {
  Cache(this.api);
  final Api api;
}
''');

    newFile('$testPackageLibPath/api.dart', '''
$alloyImport

import 'cache.dart';

@alloyInject
class Api {
  Api(this.cache);
  final Cache cache;
}
''');

    await assertNoDiagnostics('''
$alloyImport

import 'api.dart';

@alloyInject
class Reporter {
  Reporter(this.api);
  final Api api;
}
''');
  }

  void test_aLoopThroughPropertyInjection_isReported() async {
    newFile('$testPackageLibPath/cache.dart', '''
$alloyImport

import 'api.dart';

@alloyInject
class Cache {
  Cache(this.api);
  final Api api;
}
''');

    await assertDiagnostics(
      '''
$alloyImport

import 'cache.dart';

@alloyInject
class Api {
  Api();

  @injected
  late final Cache cache;
}
''',
      [lint(101, 3)],
    );
  }

  void test_aLoopThroughExposeAs_isReported() async {
    newFile('$testPackageLibPath/notes.dart', '''
$alloyImport

import 'editor.dart';

abstract interface class Notes {}

@AlloyInject(exposeAs: Notes)
class SqlNotes implements Notes {
  SqlNotes(this.editor);
  final Editor editor;
}
''');

    await assertDiagnostics(
      '''
$alloyImport

import 'notes.dart';

@alloyInject
class Editor {
  Editor(this.notes);
  final Notes notes;
}
''',
      [lint(101, 6)],
    );
  }

  void test_aLoopThroughDependsOn_isReported() async {
    newFile('$testPackageLibPath/index.dart', '''
$alloyImport

import 'db.dart';

@AlloyInit(dependsOn: [Database])
class SearchIndex {
  Future<void> init() async {}
}
''');

    await assertDiagnostics(
      '''
$alloyImport

import 'index.dart';

@AlloyInit(dependsOn: [SearchIndex])
class Database {
  Future<void> init() async {}
}
''',
      [lint(125, 8)],
    );
  }

  void test_aLoopThroughAnOptionalDependency_isReported() async {
    newFile('$testPackageLibPath/cache.dart', '''
$alloyImport

import 'api.dart';

@alloyInject
class Cache {
  Cache(this.api);
  final Api? api;
}
''');

    await assertDiagnostics(
      '''
$alloyImport

import 'cache.dart';

@alloyInject
class Api {
  Api(this.cache);
  final Cache cache;
}
''',
      [lint(101, 3)],
    );
  }

  /// Two classes of the same name are two registrations the build accepts, and
  /// fusing them by name is how a graph with no loop grows one.
  void test_oneNameTwoLibraries_staysSilent() async {
    newFile('$testPackageLibPath/plain.dart', '''
$alloyImport

@alloyInject
class Clock {}
''');

    newFile('$testPackageLibPath/ticking.dart', '''
$alloyImport

import 'api.dart';

@alloyInject
class Clock {
  Clock(this.api);
  final Api api;
}
''');

    await assertDiagnostics('''
$alloyImport

import 'plain.dart';

@alloyInject
class Api {
  Api(this.clock);
  final Clock clock;
}
''', []);
  }
}
