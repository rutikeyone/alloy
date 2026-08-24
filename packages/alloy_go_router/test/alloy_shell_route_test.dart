import 'package:alloy_go_router/alloy_go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support.dart';

GoRouter flowRouter({String initialLocation = '/'}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(
      path: '/',
      builder: (_, _) => const Scaffold(body: Text('home')),
    ),
    alloyShellRoute(
      name: 'order',
      identity: (state) => state.pathParameters['id'],
      scope: (state) => TrackedScope('order-${state.pathParameters['id']}'),
      routes: [
        GoRoute(path: '/orders/:id/summary', builder: (_, _) => const Probe()),
        GoRoute(path: '/orders/:id/payment', builder: (_, _) => const Probe()),
      ],
    ),
  ],
);

void main() {
  late AlloyScope root;
  late GoRouter router;

  setUp(() {
    disposeLog.clear();
    root = AlloyScope.root(name: 'app');
    router = flowRouter();
  });

  tearDown(() async {
    router.dispose();
    await root.dispose();
  });

  Future<void> open(WidgetTester tester, String location) async {
    router.go(location);
    await settle(tester);
  }

  Future<void> start(WidgetTester tester) async {
    await tester.pumpWidget(app(root, router));
    await settle(tester);
  }

  group('entering a flow', () {
    testWidgets('builds a child scope the flow resolves from', (tester) async {
      await start(tester);
      await open(tester, '/orders/7/summary');

      expect(find.text('scope:order:7'), findsOneWidget);
      expect(find.text('label:order-7'), findsOneWidget);
      expect(root.children.single.name, 'order:7');
    });

    testWidgets('the flow shadows the root while it is open', (tester) async {
      root.registerLazySingleton<Tracked>(const TrackedFactory('root'));

      await start(tester);
      await open(tester, '/orders/7/summary');

      expect(find.text('label:order-7'), findsOneWidget);
      expect(root.get<Tracked>().label, 'root');
    });
  });

  group('navigating inside a flow', () {
    testWidgets('keeps the same scope and the same instance', (tester) async {
      await start(tester);
      await open(tester, '/orders/7/summary');
      final before = textStartingWith('instance:');

      await open(tester, '/orders/7/payment');

      expect(textStartingWith('instance:'), before);
      expect(disposeLog, isEmpty);
      expect(root.children.single.name, 'order:7');
    });
  });

  group('leaving a flow', () {
    testWidgets('disposes the scope it owned', (tester) async {
      await start(tester);
      await open(tester, '/orders/7/summary');
      expect(find.text('label:order-7'), findsOneWidget);

      await open(tester, '/');

      expect(disposeLog, ['order-7']);
      expect(root.children, isEmpty);
    });

    testWidgets('re-entering builds a fresh scope', (tester) async {
      await start(tester);
      await open(tester, '/orders/7/summary');
      final first = textStartingWith('instance:');

      await open(tester, '/');
      await open(tester, '/orders/7/summary');

      expect(textStartingWith('instance:'), isNot(first));
      expect(root.children.single.state, AlloyScopeState.active);
    });
  });

  group('changing the flow identity', () {
    testWidgets('tears the old run down and builds a new one', (tester) async {
      await start(tester);
      await open(tester, '/orders/7/summary');
      final first = textStartingWith('instance:');

      await open(tester, '/orders/8/summary');

      expect(disposeLog, ['order-7']);
      expect(find.text('label:order-8'), findsOneWidget);
      expect(textStartingWith('instance:'), isNot(first));
      expect(root.children.single.name, 'order:8');
    });

    testWidgets('a flow without an identity keeps one scope', (tester) async {
      final plain = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: Text('home')),
          ),
          alloyShellRoute(
            name: 'wizard',
            scope: (_) => const TrackedScope('wizard'),
            routes: [
              GoRoute(path: '/wizard/a', builder: (_, _) => const Probe()),
              GoRoute(path: '/wizard/b', builder: (_, _) => const Probe()),
            ],
          ),
        ],
      );
      addTearDown(plain.dispose);

      await tester.pumpWidget(app(root, plain));
      await settle(tester);
      plain.go('/wizard/a');
      await settle(tester);
      final before = textStartingWith('instance:');

      plain.go('/wizard/b');
      await settle(tester);

      expect(find.text('scope:wizard'), findsOneWidget);
      expect(textStartingWith('instance:'), before);
      expect(disposeLog, isEmpty);
    });
  });

  group('deep linking straight into a flow', () {
    testWidgets('builds the scope without passing through home', (
      tester,
    ) async {
      final deep = flowRouter(initialLocation: '/orders/9/payment');
      addTearDown(deep.dispose);

      await tester.pumpWidget(app(root, deep));
      await settle(tester);

      expect(find.text('label:order-9'), findsOneWidget);
      expect(root.children.single.name, 'order:9');
    });
  });
}
