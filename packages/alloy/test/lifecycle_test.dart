import 'package:alloy/alloy.dart';
import 'package:alloy_test/alloy_test.dart';
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
  AsyncLeaf() : _recorder = recorder;

  final DisposeRecorder _recorder;

  @override
  Future<void> dispose() async => _recorder.record('AsyncLeaf');
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
      final scope = alloyTestRoot()
        ..registerLazySingleton<Trunk>(const TrunkFactory())
        ..registerLazySingleton<Leaf>(const LeafFactory());

      scope.get<Trunk>();
      await scope.dispose();

      expect(recorder.entries, ['Trunk', 'Leaf']);
    });

    test('children are disposed before the parent', () async {
      final root = alloyTestRoot()..registerSingleton(Recorder('root'));
      final child = root.push('child')..registerSingleton(Recorder('child'));
      child.push('grandchild').registerSingleton(Recorder('grandchild'));

      await root.dispose();

      expect(recorder.entries, ['grandchild', 'child', 'root']);
    });

    test('sibling scopes dispose last in first out', () async {
      final root = alloyTestRoot();
      root.push('first').registerSingleton(Recorder('first'));
      root.push('second').registerSingleton(Recorder('second'));

      await root.dispose();

      expect(recorder.entries, ['second', 'first']);
    });

    test('async disposables are awaited', () async {
      final scope = alloyTestRoot()
        ..registerSingleton(AsyncRecorder('slow'))
        ..registerSingleton(Recorder('fast'));

      await scope.dispose();

      expect(recorder.entries, ['fast', 'slow']);
    });

    test('transient instances are not owned by the scope', () async {
      final scope = alloyTestRoot()..registerFactory<Leaf>(const LeafFactory());

      scope.get<Leaf>();
      await scope.dispose();

      expect(recorder.entries, isEmpty);
    });

    test('a disposed child detaches from its parent', () async {
      final root = alloyTestRoot();
      final child = root.push('child');

      await child.dispose();

      expect(root.children, isEmpty);
      expect(child.state, AlloyScopeState.disposed);
      expect(root.state, AlloyScopeState.open);
    });

    test('dispose is idempotent', () async {
      final scope = alloyTestRoot()..registerSingleton(Recorder('only'));

      await scope.dispose();
      await scope.dispose();

      expect(recorder.entries, ['only']);
    });

    test('a disposed scope refuses further use', () async {
      final scope = alloyTestRoot()
        ..registerLazySingleton<Leaf>(const LeafFactory());
      await scope.dispose();

      expect(() => scope.get<Leaf>(), throwsA(isA<AlloyScopeStateError>()));
      expect(() => scope.push('late'), throwsA(isA<AlloyScopeStateError>()));
    });
  });

  group('async initialization', () {
    test('runs dependents strictly after their dependencies', () async {
      final scope = alloyTestRoot()
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
      final scope = alloyTestRoot()
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
      final scope = alloyTestRoot()
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
      final scope = alloyTestRoot()
        ..registerAsyncSingleton<SlowService>(const SlowFactory('x', 0));

      expect(
        () => scope.get<SlowService>(),
        throwsA(isA<AlloyNotReadyError>()),
      );
    });

    test('a cycle fails loudly instead of deadlocking', () async {
      final scope = alloyTestRoot()
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
      final scope = alloyTestRoot()
        ..registerAsyncSingleton<SlowService>(const SlowFactory('once', 0));

      await scope.init();
      await scope.init();

      expect(initLog, ['once']);
    });

    test(
      'async singletons are disposed like any other owned instance',
      () async {
        final scope = alloyTestRoot()
          ..registerAsyncSingleton<AsyncLeaf>(const AsyncLeafFactory());

        await scope.init();
        await scope.dispose();

        expect(recorder.entries, ['AsyncLeaf']);
      },
    );
  });
}
