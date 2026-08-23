import 'dart:async';
import 'dart:ui' show AppExitResponse;

import 'package:alloy_flutter/alloy_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class Marker implements Disposable {
  Marker(this.label, this._log);

  final String label;
  final List<String> _log;

  @override
  void dispose() => _log.add(label);
}

/// The log is per test, not global: teardown is not awaited, so a scope from
/// one test can finish releasing while the next one runs.
final class MarkerFactory implements AlloyFactory<Marker> {
  const MarkerFactory(this.label, this.log);

  final String label;
  final List<String> log;

  @override
  Marker create(AlloyResolver resolver) => Marker(label, log);
}

/// Renders what the graph resolved, so tests can compare instances.
class Probe extends StatelessWidget {
  const Probe({super.key});

  @override
  Widget build(BuildContext context) {
    final marker = context.alloy<Marker>();
    return Text(
      '${marker.label}:${identityHashCode(marker)}',
      textDirection: TextDirection.ltr,
    );
  }
}

/// A child scope under the root, to prove a restart rebuilds the subtree.
class ChildScope implements AlloyScopeBuilder {
  const ChildScope();

  @override
  void build(AlloyScope scope) =>
      scope.registerLazySingleton<String>(const _NameFactory());
}

final class _NameFactory implements AlloyFactory<String> {
  const _NameFactory();

  @override
  String create(AlloyResolver resolver) => resolver.get<Marker>().label;
}

class RootBuilder implements AlloyScopeBuilder {
  const RootBuilder(this.label, this.log);

  final String label;
  final List<String> log;

  // Eager, so the instance exists as soon as the graph is built — a lazy one
  // nobody resolved would leave nothing to release.
  @override
  void build(AlloyScope scope) =>
      scope.registerSingleton<Marker>(MarkerFactory(label, log).create(scope));
}

void main() {
  late List<String> disposeLog;

  setUp(() => disposeLog = <String>[]);

  // Factories here are synchronous on purpose: these tests build the graph
  // inside testWidgets, where a real Future.delayed would never complete.
  Future<AlloyScope> startOk() => AlloyApplication.start(
    root: RootBuilder('root', disposeLog),
    rootName: 'app',
  );

  Future<AlloyScope> startBoom() async => throw StateError('startup failed');

  String rendered() =>
      (find.byType(Text).evaluate().first.widget as Text).data!;

  group('starting', () {
    testWidgets('shows loading until the graph is ready, then the child', (
      tester,
    ) async {
      await tester.pumpWidget(
        AlloyAppScope(
          start: startOk,
          loading: const Text('loading', textDirection: TextDirection.ltr),
          child: const Probe(),
        ),
      );

      expect(find.text('loading'), findsOneWidget);
      await tester.pumpAndSettle();

      expect(find.text('loading'), findsNothing);
      expect(rendered(), startsWith('root:'));
    });
  });

  group('a failed start', () {
    testWidgets('reaches errorBuilder instead of killing the app', (
      tester,
    ) async {
      await tester.pumpWidget(
        AlloyAppScope(
          start: startBoom,
          errorBuilder: (context, error, retry) =>
              Text('failed: $error', textDirection: TextDirection.ltr),
          child: const Probe(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('startup failed'), findsOneWidget);
    });

    testWidgets('is rethrown in build when there is no errorBuilder', (
      tester,
    ) async {
      await tester.pumpWidget(
        AlloyAppScope(start: startBoom, child: const Probe()),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isA<StateError>());
    });

    testWidgets('retry brings the graph up on the second attempt', (
      tester,
    ) async {
      var attempts = 0;
      Future<AlloyScope> flaky() async {
        attempts++;
        if (attempts == 1) throw StateError('not yet');
        return startOk();
      }

      await tester.pumpWidget(
        AlloyAppScope(
          start: flaky,
          errorBuilder: (context, error, retry) => GestureDetector(
            onTap: retry,
            child: const Text('retry', textDirection: TextDirection.ltr),
          ),
          child: const Probe(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('retry'), findsOneWidget);

      await tester.tap(find.text('retry'));
      await tester.pumpAndSettle();

      expect(rendered(), startsWith('root:'));
      expect(attempts, 2);
    });
  });

  group('unmounting', () {
    testWidgets('disposes the root it owned', (tester) async {
      await tester.pumpWidget(
        AlloyAppScope(start: startOk, child: const Probe()),
      );
      await tester.pumpAndSettle();
      expect(disposeLog, isEmpty);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();

      expect(disposeLog, ['root']);
    });

    testWidgets('releases a graph that finished starting too late', (
      tester,
    ) async {
      final gate = Completer<void>();
      Future<AlloyScope> slow() async {
        await gate.future;
        return startOk();
      }

      await tester.pumpWidget(AlloyAppScope(start: slow, child: const Probe()));
      await tester.pump();

      await tester.pumpWidget(const SizedBox.shrink());
      gate.complete();
      await tester.pumpAndSettle();

      expect(disposeLog, [
        'root',
      ], reason: 'a scope nobody is waiting for still has to be released');
    });
  });

  group('restart', () {
    testWidgets('disposes the old graph and builds a new one', (tester) async {
      await tester.pumpWidget(
        AlloyAppScope(
          start: startOk,
          loading: const Text('loading', textDirection: TextDirection.ltr),
          child: const Probe(),
        ),
      );
      await tester.pumpAndSettle();
      final before = rendered();

      final controller = AlloyAppScope.of(tester.element(find.byType(Probe)));
      await controller.restart();
      await tester.pumpAndSettle();

      expect(disposeLog, ['root']);
      expect(rendered(), isNot(before));
    });

    testWidgets('rebuilds the subtree, so child scopes get the new root', (
      tester,
    ) async {
      await tester.pumpWidget(
        AlloyAppScope(
          start: startOk,
          child: const AlloyScopeWidget(
            name: 'child',
            builder: ChildScope(),
            child: _ChildProbe(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final firstRoot = _rootOf(tester);

      await AlloyAppScope.of(tester.element(find.byType(_ChildProbe)))
          .restart();
      await tester.pumpAndSettle();

      expect(_rootOf(tester), isNot(same(firstRoot)));
      expect(
        _rootOf(tester).children.single.name,
        'child',
        reason: 'the child scope was rebuilt under the new root, not orphaned',
      );
    });
  });

  group('disposeOnExitRequest', () {
    testWidgets('is off by default, so nothing observes the exit', (
      tester,
    ) async {
      await tester.pumpWidget(
        AlloyAppScope(start: startOk, child: const Probe()),
      );
      await tester.pumpAndSettle();

      expect(await tester.binding.handleRequestAppExit(), AppExitResponse.exit);
      expect(disposeLog, isEmpty);
    });

    testWidgets('when on, the graph is released before the app quits', (
      tester,
    ) async {
      await tester.pumpWidget(
        AlloyAppScope(
          start: startOk,
          disposeOnExitRequest: true,
          child: const Probe(),
        ),
      );
      await tester.pumpAndSettle();

      final response = await tester.binding.handleRequestAppExit();

      expect(response, AppExitResponse.exit);
      expect(disposeLog, ['root']);
    });
  });
}

/// Climbs to the root: the probe sits below the child scope, so the nearest
/// provider is that child, not the root.
AlloyScope _rootOf(WidgetTester tester) {
  var scope = AlloyScopeProvider.of(tester.element(find.byType(_ChildProbe)));
  for (var parent = scope.parent; parent != null; parent = scope.parent) {
    scope = parent;
  }
  return scope;
}

class _ChildProbe extends StatelessWidget {
  const _ChildProbe();

  @override
  Widget build(BuildContext context) =>
      Text(context.alloy<String>(), textDirection: TextDirection.ltr);
}
