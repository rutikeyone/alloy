import 'package:alloy_inspector/alloy_inspector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

void main() {
  late AlloyInspectorLog log;

  setUp(() {
    clocksBuilt = 0;
    log = AlloyInspectorLog();
  });

  Future<void> openLog(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('tab-log')));
    await tester.pumpAndSettle();
  }

  group('the log', () {
    testWidgets('narrows to what the search matches', (tester) async {
      final scope = buildGraph(log)..push('session');
      await tester.pumpWidget(inspectorUnderTest(scope, log));
      await tester.pumpAndSettle();
      await openLog(tester);

      expect(find.byKey(const Key('event-log')), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('log-search')),
        'nothing like this',
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('no-events')), findsOneWidget);

      await tester.enterText(find.byKey(const Key('log-search')), 'session');
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('event-log')), findsOneWidget);
    });

    testWidgets('pausing stops the view moving, and nothing is lost', (
      tester,
    ) async {
      final scope = buildGraph(log);
      await tester.pumpWidget(inspectorUnderTest(scope, log));
      await tester.pumpAndSettle();
      await openLog(tester);

      final before = log.records.length;

      await tester.tap(find.byKey(const Key('pause-log')));
      await tester.pumpAndSettle();
      scope.push('while-paused');
      await tester.pumpAndSettle();

      expect(log.isPaused, isTrue);
      expect(
        find.text('scope "app/while-paused" pushed'),
        findsNothing,
        reason: 'the record arrived; the view was told to hold still',
      );
      expect(log.records.length, greaterThan(before));

      await tester.tap(find.byKey(const Key('pause-log')));
      await tester.pumpAndSettle();

      expect(find.text('scope "app/while-paused" pushed'), findsOneWidget);
    });

    testWidgets('a record opens with its detail and copies', (tester) async {
      final scope = buildGraph(log)..get<Clock>();
      await tester.pumpWidget(inspectorUnderTest(scope, log));
      await tester.pumpAndSettle();
      await openLog(tester);

      await tester.tap(find.textContaining('built Clock').first);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('record-structured')), findsOneWidget);
      expect(find.byKey(const Key('copy-record')), findsOneWidget);
    });
  });

  group('the tree', () {
    testWidgets('collapse all folds every node, and again unfolds', (
      tester,
    ) async {
      final scope = buildGraph(log)..push('session');
      await tester.pumpWidget(inspectorUnderTest(scope, log));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('registration-Clock')), findsWidgets);

      await tester.tap(find.byKey(const Key('collapse-all')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('registration-Clock')), findsNothing);

      await tester.tap(find.byKey(const Key('collapse-all')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('registration-Clock')), findsWidgets);
    });

    testWidgets('the search narrows the registrations, not the scopes', (
      tester,
    ) async {
      final scope = buildGraph(log);
      await tester.pumpWidget(inspectorUnderTest(scope, log));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('tree-search')), 'ticket');
      await tester.pumpAndSettle();

      expect(find.text('app'), findsOneWidget);
      expect(find.byKey(const Key('registration-Clock')), findsNothing);
      expect(find.byKey(const Key('registration-Ticket')), findsOneWidget);
    });

    /// The guard from phase 18: an inspector that resolved rows to show them
    /// would change the graph it exists to observe.
    testWidgets('still builds nothing to render itself', (tester) async {
      final scope = buildGraph(log);
      await tester.pumpWidget(inspectorUnderTest(scope, log));
      await tester.pumpAndSettle();

      expect(clocksBuilt, 0);
      expect(log.created, isEmpty);
    });
  });

  group('the built tab', () {
    testWidgets('regroups without losing a row', (tester) async {
      final scope = buildGraph(log)
        ..get<Clock>()
        ..get<Api>();
      await tester.pumpWidget(inspectorUnderTest(scope, log));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tab-created')));
      await tester.pumpAndSettle();

      final grouped = find.byKey(const Key('created-Clock')).evaluate().length;
      expect(find.byKey(const Key('group-header-app')), findsOneWidget);

      await tester.tap(find.byKey(const Key('group-flat')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('group-header-app')), findsNothing);
      expect(
        find.byKey(const Key('created-Clock')).evaluate().length,
        grouped,
        reason: 'grouping rearranges rows; it does not drop any',
      );

      await tester.tap(find.byKey(const Key('group-byLifetime')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('group-header-lazySingleton')), findsWidgets);
    });
  });
}
