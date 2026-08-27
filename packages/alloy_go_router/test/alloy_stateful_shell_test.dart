import 'package:alloy_go_router/alloy_go_router.dart';
import 'package:flutter/material.dart';
import 'package:alloy_test/alloy_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support.dart';

void main() {
  late AlloyScope root;
  late GlobalKey<StatefulNavigationShellState> shellKey;

  setUp(() {
    recorder = DisposeRecorder();
    root = alloyTestRoot(name: 'app');
    shellKey = GlobalKey<StatefulNavigationShellState>();
  });

  Future<void> start(WidgetTester tester, GoRouter router) async {
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
        recorder.entries,
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
      expect(recorder.entries, containsAll(<String>['feed', 'profile']));
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

    /// The primary constructor, which mirrors `StatefulShellRoute.new` and
    /// takes the container builder itself. Only `.indexedStack` was exercised
    /// before, and tabs are the feature.
    testWidgets('the primary constructor owns a scope just the same', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/w/feed',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: Text('out')),
          ),
          AlloyStatefulShellRoute(
            key: shellKey,
            name: 'workspace',
            scope: (_) => const TrackedScope('workspace'),
            navigatorContainerBuilder: (_, navigationShell, children) =>
                IndexedStack(
                  index: navigationShell.currentIndex,
                  children: children,
                ),
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

      router.go('/');
      await settle(tester);

      expect(
        root.children,
        isEmpty,
        reason:
            'the scope itself, not its teardown log: nobody resolved the '
            'workspace Tracked, so a lazy singleton was never built and there '
            'is nothing to have released',
      );
    });

    /// `shell` is the wrapper the tab bar lives in; without it the shell route
    /// renders the navigation shell bare.
    testWidgets('the shell wrapper is rendered around the branches', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/w/feed',
        routes: [
          AlloyStatefulShellRoute.indexedStack(
            key: shellKey,
            name: 'workspace',
            scope: (_) => const TrackedScope('workspace'),
            shell: (_, _, navigationShell) => Column(
              children: [
                const Text('tabs'),
                Expanded(child: navigationShell),
              ],
            ),
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

      expect(find.text('tabs'), findsOneWidget);
      expect(find.text('chain:feed<workspace<app'), findsOneWidget);
    });
  });
}
