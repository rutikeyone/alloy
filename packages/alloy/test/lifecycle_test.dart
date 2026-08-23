import 'package:alloy/alloy.dart';
import 'package:test/test.dart';

import 'support.dart';

class Leaf extends Recorder {
  Leaf() : super('Leaf');
}

class Trunk extends Recorder {
  Trunk(this.leaf) : super('Trunk');

  final Leaf leaf;
}

class LeafFactory implements AlloyFactory<Leaf> {
  const LeafFactory();

  @override
  Leaf create(AlloyResolver resolver) => Leaf();
}

class TrunkFactory implements AlloyFactory<Trunk> {
  const TrunkFactory();

  @override
  Trunk create(AlloyResolver resolver) => Trunk(resolver.get<Leaf>());
}

class AsyncLeaf implements AsyncDisposable {
  @override
  Future<void> dispose() async => disposeLog.add('AsyncLeaf');
}

class AsyncLeafFactory implements AlloyAsyncFactory<AsyncLeaf> {
  const AsyncLeafFactory();

  @override
  Future<AsyncLeaf> create(AlloyResolver resolver) async => AsyncLeaf();
}

void main() {
  setUp(resetLogs);

  group('dispose ordering', () {
    test('disposes by creation order, not registration order', () async {
      final scope = AlloyScope.root()
        ..registerLazySingleton<Trunk>(const TrunkFactory())
        ..registerLazySingleton<Leaf>(const LeafFactory());

      scope.get<Trunk>();
      await scope.dispose();

      expect(disposeLog, ['Trunk', 'Leaf']);
    });

    test('children are disposed before the parent', () async {
      final root = AlloyScope.root()..registerSingleton(Recorder('root'));
      final child = root.push('child')..registerSingleton(Recorder('child'));
      child.push('grandchild').registerSingleton(Recorder('grandchild'));

      await root.dispose();

      expect(disposeLog, ['grandchild', 'child', 'root']);
    });

    test('sibling scopes dispose last in first out', () async {
      final root = AlloyScope.root();
      root.push('first').registerSingleton(Recorder('first'));
      root.push('second').registerSingleton(Recorder('second'));

      await root.dispose();

      expect(disposeLog, ['second', 'first']);
    });

    test('async disposables are awaited', () async {
      final scope = AlloyScope.root()
        ..registerSingleton(AsyncRecorder('slow'))
        ..registerSingleton(Recorder('fast'));

      await scope.dispose();

      expect(disposeLog, ['fast', 'slow']);
    });

    test('transient instances are not owned by the scope', () async {
      final scope = AlloyScope.root()
        ..registerFactory<Leaf>(const LeafFactory());

      scope.get<Leaf>();
      await scope.dispose();

      expect(disposeLog, isEmpty);
    });

    test('a disposed child detaches from its parent', () async {
      final root = AlloyScope.root();
      final child = root.push('child');

      await child.dispose();

      expect(root.children, isEmpty);
      expect(child.state, AlloyScopeState.disposed);
      expect(root.state, AlloyScopeState.open);
    });

    test('dispose is idempotent', () async {
      final scope = AlloyScope.root()..registerSingleton(Recorder('only'));

      await scope.dispose();
      await scope.dispose();

      expect(disposeLog, ['only']);
    });

    test('a disposed scope refuses further use', () async {
      final scope = AlloyScope.root()
        ..registerLazySingleton<Leaf>(const LeafFactory());
      await scope.dispose();

      expect(() => scope.get<Leaf>(), throwsA(isA<AlloyScopeStateError>()));
      expect(() => scope.push('late'), throwsA(isA<AlloyScopeStateError>()));
    });
  });

  group('async initialization', () {
    test('runs dependents strictly after their dependencies', () async {
      final scope = AlloyScope.root()
        ..registerAsyncSingleton<SlowService>(const SlowFactory('database', 10))
        ..registerAsyncSingleton<AsyncLeaf>(
          const AsyncLeafFactory(),
          dependsOn: {const AlloyKey(SlowService)},
        );

      await scope.init();

      expect(scope.state, AlloyScopeState.active);
      expect(initLog, ['database']);
    });

    test('independent branches run in parallel', () async {
      final scope = AlloyScope.root()
        ..registerAsyncSingleton<SlowService>(const SlowFactory('a', 120))
        ..registerAsyncSingleton<SlowService>(
          const SlowFactory('b', 120),
          name: 'b',
        );

      final watch = Stopwatch()..start();
      await scope.init();
      watch.stop();

      expect(initLog, hasLength(2));
      expect(watch.elapsedMilliseconds, lessThan(220));
    });

    test('a dependent chain runs sequentially', () async {
      final scope = AlloyScope.root()
        ..registerAsyncSingleton<SlowService>(const SlowFactory('first', 120))
        ..registerAsyncSingleton<SlowService>(
          const SlowFactory('second', 120),
          name: 'second',
          dependsOn: {const AlloyKey(SlowService)},
        );

      final watch = Stopwatch()..start();
      await scope.init();
      watch.stop();

      expect(initLog, ['first', 'second']);
      expect(watch.elapsedMilliseconds, greaterThanOrEqualTo(220));
    });

    test('an async singleton is unavailable before init', () {
      final scope = AlloyScope.root()
        ..registerAsyncSingleton<SlowService>(const SlowFactory('x', 0));

      expect(
        () => scope.get<SlowService>(),
        throwsA(isA<AlloyNotReadyError>()),
      );
    });

    test('a cycle fails loudly instead of deadlocking', () async {
      final scope = AlloyScope.root()
        ..registerAsyncSingleton<SlowService>(
          const SlowFactory('a', 0),
          dependsOn: {const AlloyKey(AsyncLeaf)},
        )
        ..registerAsyncSingleton<AsyncLeaf>(
          const AsyncLeafFactory(),
          dependsOn: {const AlloyKey(SlowService)},
        );

      await expectLater(scope.init(), throwsA(isA<AlloyCycleError>()));
    });

    test('init is idempotent', () async {
      final scope = AlloyScope.root()
        ..registerAsyncSingleton<SlowService>(const SlowFactory('once', 0));

      await scope.init();
      await scope.init();

      expect(initLog, ['once']);
    });

    test(
      'async singletons are disposed like any other owned instance',
      () async {
        final scope = AlloyScope.root()
          ..registerAsyncSingleton<AsyncLeaf>(const AsyncLeafFactory());

        await scope.init();
        await scope.dispose();

        expect(disposeLog, ['AsyncLeaf']);
      },
    );
  });
}
