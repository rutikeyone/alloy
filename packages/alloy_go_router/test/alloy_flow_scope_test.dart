import 'package:alloy_go_router/alloy_go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support.dart';

void main() {
  late AlloyScope root;

  setUp(() {
    disposeLog.clear();
    root = AlloyScope.root(name: 'app');
  });

  tearDown(() async => root.dispose());

  group('a flow inside a flow', () {
    testWidgets('stacks scopes instead of replacing them', (tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: Text('home')),
          ),
          alloyFlowRoute(
            name: 'outer',
            scope: (_) => const TrackedScope('outer'),
            routes: [
              alloyFlowRoute(
                name: 'inner',
                scope: (_) => const TrackedScope('inner'),
                routes: [
                  GoRoute(
                    path: '/outer/inner',
                    builder: (_, _) => const ScopeChain(),
                  ),
                ],
              ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(app(root, router));
      await settle(tester);
      router.go('/outer/inner');
      await settle(tester);
      await settle(tester);

      expect(
        find.text('chain:inner<outer<app'),
        findsOneWidget,
        reason: 'nested flows each cost a frame before they publish a scope',
      );

      final outer = root.children.single;
      final inner = outer.children.single;
      expect(outer.name, 'outer');
      expect(inner.name, 'inner');

      router.go('/');
      await settle(tester);

      expect(root.children, isEmpty);
      expect(inner.state, AlloyScopeState.disposed);
      expect(
        outer.state,
        AlloyScopeState.disposed,
        reason: 'closing the outer flow takes the nested one with it',
      );
    });
  });

  group('StatefulShellRoute branches', () {
    testWidgets('keep their scope alive after switching away', (tester) async {
      final shellKey = GlobalKey<StatefulNavigationShellState>();
      final router = GoRouter(
        initialLocation: '/a',
        routes: [
          StatefulShellRoute.indexedStack(
            key: shellKey,
            builder: (_, _, shell) => shell,
            branches: [
              StatefulShellBranch(
                routes: [
                  alloyFlowRoute(
                    name: 'branch-a',
                    scope: (_) => const TrackedScope('a'),
                    routes: [
                      GoRoute(path: '/a', builder: (_, _) => const Probe()),
                    ],
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  alloyFlowRoute(
                    name: 'branch-b',
                    scope: (_) => const TrackedScope('b'),
                    routes: [
                      GoRoute(path: '/b', builder: (_, _) => const Probe()),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(app(root, router));
      await settle(tester);
      expect(find.text('label:a'), findsOneWidget);

      shellKey.currentState!.goBranch(1);
      await settle(tester);

      expect(
        disposeLog,
        isEmpty,
        reason:
            'a branch is kept alive off-screen, so its scope outlives the tab '
            'being visible — this is go_router behaviour, pinned so a change '
            'to it is noticed',
      );
      expect(
        root.children.map((scope) => scope.name),
        containsAll(<String>['branch-a', 'branch-b']),
      );
    });
  });
}
