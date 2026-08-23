import 'package:alloy/alloy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/alloy.g.dart';
import 'package:notes_app/app/app_startup.dart';
import 'package:notes_app/bootstrap/boot_log.dart';
import 'package:notes_app/core/event_log.dart';
import 'package:notes_app/features/diagnostics/data/telemetry.dart';
import 'package:notes_app/features/notes/data/note_database.dart';
import 'package:notes_app/features/notes/data/search_index.dart';

void main() {
  setUp(BootLog.reset);

  group('generated bootstrap', () {
    test('runs every annotated step, ordered by its declared order', () async {
      final app = await startNotesApp();
      addTearDown(app.dispose);

      expect(BootLog.steps, [
        'bind-platform',
        'load-remote-config',
        'warm-fonts',
      ]);
    });

    test('finishes before any dependency is constructed', () async {
      final app = await startNotesApp();
      addTearDown(app.dispose);

      final log = app.get<EventLog>().entries;
      expect(BootLog.steps, hasLength(3));
      expect(log, isNot(contains('bind-platform')));
      expect(log, contains('database opened'));
    });

    test('independent initializers share a level, so neither waits', () async {
      final app = await startNotesApp();
      addTearDown(app.dispose);

      final log = app.get<EventLog>().entries;
      expect(
        log,
        containsAll(['database opened', 'telemetry started']),
        reason: 'both run, and which lands first is not a contract',
      );
      expect(
        log.indexOf('search index built'),
        greaterThan(log.indexOf('database opened')),
        reason: 'dependsOn is the only ordering the graph promises',
      );
    });

    test('the root scope takes its name from @AlloyScopeRoot', () async {
      final app = await startNotesApp();
      addTearDown(app.dispose);

      expect($alloyRootScopeName, 'app');
      expect(app.name, 'app');
    });

    test('a failing step aborts the start and names itself', () async {
      await expectLater(
        AlloyApplication.start(
          root: const $AlloyRootScope(environment: AlloyEnvironment.test),
          bootstrap: [_ExplodingStep()],
        ),
        throwsA(
          isA<AlloyBootstrapError>().having((e) => e.step, 'step', 'exploding'),
        ),
      );
    });
  });

  group('the root scope owns the bootstrap steps', () {
    test('a step holding a resource is released with the scope', () async {
      final app = await startNotesApp();
      final binding = BootLog.steps;

      expect(binding, contains('bind-platform'));
      expect(binding, isNot(contains('bind-platform released')));

      await app.dispose();

      expect(BootLog.steps, contains('bind-platform released'));
    });

    test('every start gets its own step instances', () async {
      final first = await startNotesApp();
      await first.dispose();

      BootLog.reset();
      final second = await startNotesApp();
      addTearDown(second.dispose);

      expect(BootLog.steps, [
        'bind-platform',
        'load-remote-config',
        'warm-fonts',
      ], reason: 'a stored list would have reused the first run instances');
    });
  });

  group('generated async init graph', () {
    test('every @AlloyInit service is ready when start returns', () async {
      final app = await startNotesApp();
      addTearDown(app.dispose);

      expect(app.get<NoteDatabase>().isOpen, isTrue);
      expect(app.get<SearchIndex>().isBuilt, isTrue);
      expect(app.get<Telemetry>().isStarted, isTrue);
    });

    test('dependsOn is honoured: the index waits for the database', () async {
      final app = await startNotesApp();
      addTearDown(app.dispose);

      final entries = app.get<EventLog>().entries;
      expect(
        entries.indexOf('database opened'),
        lessThan(entries.indexOf('search index built')),
      );
    });

    test(
      'independent initializers share a level and run in parallel',
      () async {
        final watch = Stopwatch()..start();
        final app = await startNotesApp();
        watch.stop();
        addTearDown(app.dispose);

        expect(app.get<Telemetry>().isStarted, isTrue);
        expect(
          watch.elapsedMilliseconds,
          lessThan(60),
          reason: 'database and telemetry run together, then the index',
        );
      },
    );

    test('async services are unavailable before init', () {
      final scope = AlloyScope.root();
      const $AlloyRootScope(environment: AlloyEnvironment.test).build(scope);

      expect(
        () => scope.get<NoteDatabase>(),
        throwsA(isA<AlloyNotReadyError>()),
      );
    });
  });
}

class _ExplodingStep implements AlloyBootstrapStep {
  @override
  String get name => 'exploding';

  @override
  void run() => throw StateError('no native library');
}
