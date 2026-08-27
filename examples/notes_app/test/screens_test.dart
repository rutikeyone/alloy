import 'package:alloy_flutter/alloy_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/bootstrap/boot_log.dart';
import 'package:notes_app/core/event_log.dart';
import 'package:notes_app/features/session/data/session_activity_log.dart';
import 'package:notes_app/features/session/domain/session_user.dart';
import 'package:notes_app/features/diagnostics/ui/scope_tree_screen.dart';
import 'package:notes_app/features/environments/ui/environments_screen.dart';
import 'package:notes_app/features/formatting/ui/formatters_screen.dart';
import 'package:notes_app/features/home/ui/home_screen.dart';
import 'package:notes_app/features/note_detail/ui/note_detail_screen.dart';
import 'package:notes_app/features/notes/ui/notes_screen.dart';
import 'package:notes_app/features/session/session_manager.dart';
import 'package:notes_app/features/session/ui/session_screen.dart';

import 'support.dart';

void main() {
  /// The graph the mounted app owns. Assigned by [pumpApp], because
  /// `AlloyAppScope` builds the root itself — nothing hands it one.
  late AlloyScope app;

  setUp(BootLog.reset);

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  /// Mounts [screen] with its own graph and records the graph as [app].
  Future<void> open(WidgetTester tester, Widget screen) async {
    await tester.pumpWidget(notesScreenUnderTest(screen));
    await settle(tester);
    await settle(tester);
    // Climbs to the root: a screen that owns a scope publishes its own
    // provider, so the nearest one is the screen's, not the graph's.
    app = AlloyScopeProvider.of(tester.element(find.byType(Scaffold).first))
        .root;
  }

  Future<void> pumpApp(WidgetTester tester) => open(tester, const HomeScreen());

  /// A graph without widgets, for assertions that are about the graph alone.
  Future<AlloyScope> startGraph() async {
    final scope = await startNotesGraph();
    return scope;
  }

  group('home — the two startup phases', () {
    testWidgets('lists every bootstrap step in order', (tester) async {
      await pumpApp(tester);

      expect(find.byKey(const Key('boot-bind-platform')), findsOneWidget);
      expect(find.byKey(const Key('boot-load-remote-config')), findsOneWidget);
      expect(find.byKey(const Key('boot-warm-fonts')), findsOneWidget);
    });

    testWidgets('every async initializer is ready on the first frame', (
      tester,
    ) async {
      await pumpApp(tester);

      expect(find.text('database open: true'), findsOneWidget);
      expect(find.text('search index built: true'), findsOneWidget);
      expect(find.text('telemetry started: true'), findsOneWidget);
      expect(find.text('api: https://notes.example/v1'), findsOneWidget);
    });
  });

  group('property injection', () {
    testWidgets('a controller with no constructor arguments works', (
      tester,
    ) async {
      await open(tester, const NotesScreen());

      expect(find.byKey(const Key('note-count')), findsOneWidget);
      expect(find.text('count: 0'), findsOneWidget);

      await tester.tap(find.byKey(const Key('add-note')));
      await settle(tester);

      expect(find.text('count: 1'), findsOneWidget);
    });

    testWidgets('search runs through the initialized index', (tester) async {
      await open(tester, const NotesScreen());

      await tester.tap(find.byKey(const Key('add-note')));
      await settle(tester);
      await tester.enterText(find.byKey(const Key('search')), 'note');
      await settle(tester);

      expect(find.text('count: 1'), findsOneWidget);
    });
  });

  group('widget-owned scope', () {
    testWidgets('the screen creates a child scope named after itself', (
      tester,
    ) async {
      await open(tester, const NoteDetailScreen());

      expect(find.text('scope: NoteDetailScreen'), findsOneWidget);
      expect(app.children.single.name, 'NoteDetailScreen');
    });

    testWidgets('a parameterized factory renders through a named formatter', (
      tester,
    ) async {
      await open(tester, const NoteDetailScreen());

      await tester.enterText(find.byKey(const Key('draft-field')), 'milk');
      await settle(tester);

      expect(find.text('# milk'), findsOneWidget);
    });

    testWidgets('leaving the screen disposes the scope it owned', (
      tester,
    ) async {
      await open(tester, const NoteDetailScreen());
      expect(app.children, hasLength(1));

      // Swapping the child while the root stays put: AlloyAppScope reads its
      // graph once, so reusing the same element keeps the graph and unmounts
      // only the screen — which is the thing under test.
      await tester.pumpWidget(notesScreenUnderTest(const Scaffold()));
      await settle(tester);
      await settle(tester);

      expect(app.children, isEmpty);
      expect(app.get<EventLog>().entries, contains('draft discarded'));
    });
  });

  group('session scope', () {
    testWidgets('signing in pushes a scope, signing out disposes it', (
      tester,
    ) async {
      await open(tester, const SessionScreen());

      expect(find.text('signed out'), findsOneWidget);

      await tester.tap(find.byKey(const Key('sign-in')));
      await settle(tester);

      expect(find.text('signed in as Ada'), findsOneWidget);
      expect(find.text('scope: session:u-1'), findsOneWidget);
      expect(app.children.map((s) => s.name), contains('session:u-1'));

      await tester.tap(find.byKey(const Key('sign-out')));
      await settle(tester);

      expect(find.text('signed out'), findsOneWidget);
      expect(app.children, isEmpty);
    });

    test('a second session starts from empty state', () async {
      final manager = (await startGraph()).get<SessionManager>();

      await manager.signIn(const SessionUser(id: 'u-1', displayName: 'Ada'));
      final first = manager.scope!.get<SessionActivityLog>()
        ..record('opened notes')
        ..record('edited a note');
      expect(first.entries, hasLength(2));

      await manager.signIn(const SessionUser(id: 'u-1', displayName: 'Ada'));
      final second = manager.scope!.get<SessionActivityLog>();

      expect(second, isNot(same(first)));
      expect(second.entries, isEmpty);
      expect(first.isClosed, isTrue);
    });

    test('closing a session reports it to the app scope', () async {
      final scope = await startGraph();
      final manager = scope.get<SessionManager>();
      await manager.signIn(const SessionUser(id: 'u-1', displayName: 'Ada'));
      manager.scope!.get<SessionActivityLog>().record('opened notes');
      await manager.signOut();

      expect(
        scope.get<EventLog>().entries,
        contains('session u-1 closed with 1 entries'),
      );
    });
  });

  group('named and multi-injection', () {
    testWidgets('getAll collects every formatter', (tester) async {
      await open(tester, const FormattersScreen());

      expect(find.text('3 registrations'), findsOneWidget);
      expect(find.byKey(const Key('formatter-plain')), findsOneWidget);
      expect(find.byKey(const Key('formatter-markdown')), findsOneWidget);
      expect(find.byKey(const Key('formatter-shouting')), findsOneWidget);
    });

    testWidgets('a named lookup picks exactly one', (tester) async {
      await open(tester, const FormattersScreen());

      expect(find.text('# shopping list'), findsNWidgets(2));
      expect(find.text('SHOPPING LIST!'), findsOneWidget);
    });
  });

  group('scope tree', () {
    // After pumpApp, not in a group setUp: the graph now belongs to the
    // mounted app, so there is nothing to sign into until it is on screen.
    Future<void> signIn(WidgetTester tester) async {
      await app.get<SessionManager>().signIn(
        const SessionUser(id: 'u-9', displayName: 'Grace'),
      );
      await settle(tester);
    }

    testWidgets('renders every scope that is alive right now', (tester) async {
      await pumpApp(tester);
      await signIn(tester);
      await open(tester, const ScopeTreeScreen());

      expect(find.textContaining('app  [active]'), findsOneWidget);
      expect(find.textContaining('  session:u-9  [active]'), findsOneWidget);
    });

    testWidgets('a widget-owned scope shows up as a third level', (
      tester,
    ) async {
      await pumpApp(tester);
      await signIn(tester);
      await open(tester, const NoteDetailScreen());
      await open(tester, const ScopeTreeScreen());

      expect(
        find.textContaining('  NoteDetailScreen  [active]'),
        findsOneWidget,
      );
    });
  });

  group('environments', () {
    testWidgets('shows which implementation this build got', (tester) async {
      await open(tester, const EnvironmentsScreen());

      expect(
        find.descendant(
          of: find.byKey(const Key('active-environment')),
          matching: find.text('dev'),
        ),
        findsOneWidget,
      );
      expect(find.text('FakeApiClient \u2192 no network'), findsOneWidget);
    });

    testWidgets('reports the bootstrap step it did not run', (tester) async {
      await open(tester, const EnvironmentsScreen());

      expect(find.text('skipped in this environment'), findsOneWidget);
    });

    group('started without choosing one', () {
      testWidgets('says nothing claims it, instead of guessing', (
        tester,
      ) async {
        await tester.pumpWidget(
          notesScreenUnderTest(
            const EnvironmentsScreen(),
            environment: AlloyEnvironment.defaultEnvironment,
          ),
        );
        await settle(tester);
        await settle(tester);

        expect(find.textContaining('nothing registered'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(const Key('active-environment')),
            matching: find.text('default'),
          ),
          findsOneWidget,
        );
      });
    });
  });

  group('restarting the graph', () {
    testWidgets('releases the bootstrap steps of the old scope', (
      tester,
    ) async {
      await pumpApp(tester);
      expect(find.text('bind-platform released'), findsNothing);

      await tester.tap(find.byKey(const Key('restart-graph')));
      await settle(tester);
      await settle(tester);

      expect(find.text('bind-platform released'), findsOneWidget);
    });

    testWidgets('the new graph is fully initialized again', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.byKey(const Key('restart-graph')));
      await settle(tester);
      await settle(tester);

      expect(find.text('database open: true'), findsOneWidget);
      expect(find.text('search index built: true'), findsOneWidget);
      expect(find.text('bind-platform'), findsNWidgets(2));
    });
  });
}
