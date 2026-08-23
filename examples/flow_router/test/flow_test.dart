import 'package:alloy_go_router/alloy_go_router.dart';
import 'package:flow_router/app/app_router.dart';
import 'package:flow_router/app/flow_router_app.dart';
import 'package:flow_router/core/event_log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  late AlloyScope app;
  late GoRouter router;

  setUp(() => router = buildAppRouter());

  tearDown(() => router.dispose());

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> start(WidgetTester tester) async {
    await tester.pumpWidget(FlowRouterApp(router: router));
    await settle(tester);
    await settle(tester);
    app = AlloyScopeProvider.of(tester.element(find.byType(MaterialApp)));
  }

  Future<void> go(WidgetTester tester, String location) async {
    router.go(location);
    await settle(tester);
  }

  group('the flow owns its dependencies', () {
    testWidgets('opening a flow pushes a scope named after the order', (
      tester,
    ) async {
      await start(tester);
      await go(tester, '/orders/1/summary');

      expect(find.text('scope: order:1'), findsOneWidget);
      expect(app.children.single.name, 'order:1');
    });

    testWidgets('moving inside the flow keeps the same draft', (tester) async {
      await start(tester);
      await go(tester, '/orders/1/summary');
      await tester.tap(find.byKey(const Key('to-payment')));
      await settle(tester);

      expect(find.byKey(const Key('payment-draft')), findsOneWidget);
      expect(app.get<EventLog>().entries, ['draft 1 created']);
    });

    testWidgets('leaving the flow disposes the draft', (tester) async {
      await start(tester);
      await go(tester, '/orders/1/summary');
      await go(tester, '/');

      expect(app.get<EventLog>().entries, [
        'draft 1 created',
        'draft 1 disposed',
      ]);
      expect(app.children, isEmpty);
    });

    testWidgets('switching order rebuilds the flow scope', (tester) async {
      await start(tester);
      await go(tester, '/orders/1/summary');
      await go(tester, '/orders/2/summary');

      expect(app.get<EventLog>().entries, [
        'draft 1 created',
        'draft 1 disposed',
        'draft 2 created',
      ]);
      expect(app.children.single.name, 'order:2');
    });
  });

  group('the tabbed workspace', () {
    testWidgets('the shell and the first tab each build a scope', (
      tester,
    ) async {
      await start(tester);
      await go(tester, '/workspace/feed');
      await settle(tester);

      expect(find.text('shell scope: workspace'), findsOneWidget);
      expect(app.get<EventLog>().entries, [
        'workspace scope built',
        'feed scope built',
      ]);
      expect(app.children.single.name, 'workspace');
      expect(app.children.single.children.single.name, 'feed');
    });

    testWidgets('switching tabs adds a scope and disposes nothing', (
      tester,
    ) async {
      await start(tester);
      await go(tester, '/workspace/feed');
      await settle(tester);

      await tester.tap(find.byKey(const Key('tab-profile')));
      await settle(tester);
      await settle(tester);

      expect(app.get<EventLog>().entries, [
        'workspace scope built',
        'feed scope built',
        'profile scope built',
      ]);
      expect(app.children.single.children.map((s) => s.name), [
        'feed',
        'profile',
      ]);
    });

    testWidgets('leaving the workspace disposes all three scopes', (
      tester,
    ) async {
      await start(tester);
      await go(tester, '/workspace/feed');
      await settle(tester);
      await go(tester, '/');

      expect(
        app.get<EventLog>().entries,
        containsAll(<String>[
          'feed scope disposed',
          'workspace scope disposed',
        ]),
      );
      expect(app.children, isEmpty);
    });
  });

  group('the scope tree screen', () {
    testWidgets('shows only the root once the flow is closed', (tester) async {
      await start(tester);
      await go(tester, '/orders/1/summary');
      await go(tester, '/');
      await go(tester, '/scope-tree');

      expect(find.byKey(const Key('scope-app')), findsOneWidget);
      expect(find.byKey(const Key('scope-order:1')), findsNothing);
    });
  });
}
