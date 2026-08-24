import 'package:alloy_go_router/alloy_go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support.dart';

void main() {
  late AlloyScope root;
  late GlobalKey<StatefulNavigationShellState> shellKey;

  setUp(() {
    disposeLog.clear();
    root = AlloyScope.root(name: 'app');
    shellKey = GlobalKey<StatefulNavigationShellState>();
  });

  tearDown(() async => root.dispose());

  Future<void> start(WidgetTester tester, GoRouter router) async {
    addTearDown(router.dispose);
    await tester.pumpWidget(app(root, router));
    await settle(tester);
    await settle(tester);
  }

  group('AlloyStatefulShellBranch', () {
    GoRouter branchRouter() => GoRouter(
      initialLocation: '/feed',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('out')),
        ),
        StatefulShellRoute.indexedStack(
          key: shellKey,
          builder: (_, _, shell) => shell,
          branches: [
            AlloyStatefulShellBranch(
              name: 'feed',
              scope: (_) => const TrackedScope('feed'),
              routes: [
                GoRoute(path: '/feed', builder: (_, _) => const Probe()),
              ],
            ),
            AlloyStatefulShellBranch(
              name: 'profile',
              scope: (_) => const TrackedScope('profile'),
              routes: [
                GoRoute(path: '/profile', builder: (_, _) => const Probe()),
              ],
            ),
          ],
        ),
      ],
    );

    testWidgets('each branch resolves from a scope of its own', (tester) async {
      await start(tester, branchRouter());
      expect(find.text('label:feed'), findsOneWidget);

      shellKey.currentState!.goBranch(1);
      await settle(tester);
      await settle(tester);

      expect(find.text('label:profile'), findsOneWidget);
    });

    testWidgets('a branch scope is built on first visit, not before', (
      tester,
    ) async {
      await start(tester, branchRouter());

      expect(root.children.map((s) => s.name), ['feed']);

      shellKey.currentState!.goBranch(1);
      await settle(tester);
      await settle(tester);

      expect(root.children.map((s) => s.name), ['feed', 'profile']);
    });

    testWidgets('switching away keeps the branch alive, by design', (
      tester,
    ) async {
      await start(tester, branchRouter());
      shellKey.currentState!.goBranch(1);
      await settle(tester);
      await settle(tester);

      expect(
        disposeLog,
        isEmpty,
        reason:
            'branch navigators are preserved off-screen, so a branch scope is '
            'kept alive rather than kept visible',
      );
    });

    testWidgets('leaving the shell disposes every branch scope', (
      tester,
    ) async {
      final router = branchRouter();
      await start(tester, router);
      shellKey.currentState!.goBranch(1);
      await settle(tester);
      await settle(tester);
      expect(root.children, hasLength(2));

      router.go('/');
      await settle(tester);

      expect(root.children, isEmpty);
      expect(disposeLog, containsAll(<String>['feed', 'profile']));
    });
  });

  group('AlloyStatefulShellRoute', () {
    testWidgets('the shell scope is the parent of every branch scope', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/w/feed',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: Text('out')),
          ),
          AlloyStatefulShellRoute.indexedStack(
            key: shellKey,
            name: 'workspace',
            scope: (_) => const TrackedScope('workspace'),
            branches: [
              AlloyStatefulShellBranch(
                name: 'feed',
                scope: (_) => const TrackedScope('feed'),
                routes: [
                  GoRoute(
                    path: '/w/feed',
                    builder: (_, _) => const ScopeChain(),
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      await start(tester, router);
      await settle(tester);

      expect(find.text('chain:feed<workspace<app'), findsOneWidget);
      expect(root.children.single.name, 'workspace');
      expect(root.children.single.children.single.name, 'feed');

      router.go('/');
      await settle(tester);

      expect(root.children, isEmpty);
    });
  });
}
