import 'package:alloy/alloy.dart';
import 'package:alloy_test/alloy_test.dart';
import 'package:leak_tracker/leak_tracker.dart';
import 'package:test/test.dart';

import 'support.dart';

class Payload implements Disposable {
  @override
  void dispose() {}
}

class PayloadFactory implements AlloyFactory<Payload> {
  const PayloadFactory();

  @override
  Payload create(AlloyResolver resolver) => Payload();
}

WeakReference<Payload> seed(AlloyScope scope) {
  scope.registerLazySingleton<Payload>(const PayloadFactory());
  return WeakReference(scope.get<Payload>());
}

Future<void> collect() => forceGC(fullGcCycles: 3);

void main() {
  setUp(resetLogs);

  test('a live scope keeps its singletons reachable', () async {
    final scope = alloyTestRoot();
    final ref = seed(scope);

    await collect();

    expect(ref.target, isNotNull, reason: 'scope is still alive');
    await scope.dispose();
  });

  test('a disposed scope releases its singletons to the collector', () async {
    var scope = alloyTestRoot();
    final ref = seed(scope);

    await scope.dispose();
    scope = alloyTestRoot();

    await collect();

    expect(ref.target, isNull);
    await scope.dispose();
  });

  test('disposing a parent releases instances owned by its children', () async {
    var root = alloyTestRoot();
    final ref = seed(root.push('child'));

    await root.dispose();
    root = alloyTestRoot();

    await collect();

    expect(ref.target, isNull);
    await root.dispose();
  });

  test('a parent keeps an unreferenced child alive until dispose', () async {
    final root = alloyTestRoot();
    final ref = seed(root.push('child'));

    await collect();

    expect(
      ref.target,
      isNotNull,
      reason: 'strong parent-to-child ownership is what guarantees dispose',
    );

    await root.dispose();
  });

  test(
    'a dropped scope that was never disposed still leaks, by design',
    () async {
      var scope = alloyTestRoot();
      final ref = seed(scope);
      final keepAlive = scope;

      scope = alloyTestRoot();
      await collect();

      expect(ref.target, isNotNull, reason: 'owner never called dispose');
      await keepAlive.dispose();
      await scope.dispose();
    },
  );
}
