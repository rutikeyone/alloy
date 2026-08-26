import 'package:alloy_flutter/alloy_flutter.dart';
import 'package:alloy_inspector/alloy_inspector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

void main() {
  late AlloyInspectorLog log;
  late AlloyScope scope;

  setUp(() {
    clocksBuilt = 0;
    log = AlloyInspectorLog();
    scope = buildGraph(log);
    addTearDown(scope.dispose);
  });

  group('the tree', () {
    testWidgets('shows the scope and what it registers', (tester) async {
      await tester.pumpWidget(inspectorUnderTest(scope, log));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('scope-tree')), findsOneWidget);
      expect(find.text('app'), findsOneWidget);
      expect(find.byKey(const Key('registration-Clock')), findsOneWidget);
      expect(find.text('lazySingleton · registered here'), findsOneWidget);
    });

    testWidgets('names the owner of an inherited registration', (tester) async {
      final child = scope.push('session');
      addTearDown(child.dispose);

      await tester.pumpWidget(inspectorUnderTest(child, log));
      await tester.pumpAndSettle();

      expect(find.text('session'), findsOneWidget);

      // Only the root opens by itself; a child is a click away.
      await tester.tap(find.byKey(const Key('scope-session-1')));
      await tester.pumpAndSettle();

      expect(find.text('lazySingleton · inherited from "app"'), findsWidgets);
    });

    /// The point of the whole design. `debugResolve` builds what it resolves,
    /// so an inspector that resolved rows in order to display them would
    /// create objects nobody asked for and log its own noise.
    testWidgets('renders without building anything', (tester) async {
      await tester.pumpWidget(inspectorUnderTest(scope, log));
      await tester.pumpAndSettle();

      expect(clocksBuilt, 0);
      expect(log.created, isEmpty);
    });
  });

  testWidgets('opens from a pushed route, above the provider', (tester) async {
    await tester.pumpWidget(inspectorBehindAButton(scope, log));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-inspector')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('scope-tree')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('a registration you tapped', () {
    Future<void> openDetail(WidgetTester tester) async {
      await tester.pumpWidget(inspectorUnderTest(scope, log));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('registration-Clock')));
      await tester.pumpAndSettle();
    }

    testWidgets('shows its facts without touching the graph', (tester) async {
      await openDetail(tester);

      expect(find.byKey(const Key('registration-detail')), findsOneWidget);
      expect(find.text('Owned by'), findsOneWidget);
      expect(clocksBuilt, 0);
    });

    testWidgets('builds only when asked, and says so', (tester) async {
      await openDetail(tester);
      await tester.tap(find.byKey(const Key('build-it')));
      await tester.pumpAndSettle();

      expect(clocksBuilt, 1);
      expect(find.byKey(const Key('built-value')), findsOneWidget);
      expect(log.created, hasLength(1));
    });

    testWidgets('offers no build for a parameterized factory', (tester) async {
      await tester.pumpWidget(inspectorUnderTest(scope, log));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('registration-Ticket')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('not-buildable')), findsOneWidget);
      expect(find.byKey(const Key('build-it')), findsNothing);
    });
  });

  group('what was built', () {
    testWidgets('is empty until something is', (tester) async {
      await tester.pumpWidget(inspectorUnderTest(scope, log));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tab-created')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('nothing-built')), findsOneWidget);
    });

    testWidgets('reports the lifetime of each instance', (tester) async {
      scope.get<Clock>();
      scope.get<Api>();

      await tester.pumpWidget(inspectorUnderTest(scope, log));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tab-created')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('created-Clock')), findsOneWidget);
      expect(
        find.textContaining('lazySingleton'),
        findsWidgets,
        reason: 'the lifetime is the fact the log was extended to carry',
      );
      expect(find.textContaining('transient'), findsWidgets);
    });
  });

  group('the log', () {
    testWidgets('filters by event kind', (tester) async {
      scope.get<Clock>();

      await tester.pumpWidget(inspectorUnderTest(scope, log));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tab-log')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('event-log')), findsOneWidget);

      await tester.tap(find.byKey(const Key('filter-scopePushed')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('no-events')), findsOneWidget);
    });

    testWidgets('clearing empties it', (tester) async {
      scope.get<Clock>();

      await tester.pumpWidget(inspectorUnderTest(scope, log));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('clear-log')));
      await tester.pumpAndSettle();

      expect(log.records, isEmpty);
    });
  });
}
