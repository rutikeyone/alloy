import 'package:cobalt/cobalt.dart';
import 'package:cobalt_test/cobalt_test.dart';
import 'package:leak_tracker/leak_tracker.dart';
import 'package:test/test.dart';

import 'support.dart';

class Payload implements Disposable {
  @override
  void dispose() {}
}

class PayloadFactory implements CobaltFactory<Payload> {
  const PayloadFactory();

  @override
  Payload create(CobaltResolver resolver) => Payload();
}

WeakReference<Payload> seed(CobaltScope scope) {
  scope.registerLazySingleton<Payload>(const PayloadFactory());
  return WeakReference(scope.get<Payload>());
}

Future<void> collect() => forceGC(fullGcCycles: 3);

void main() {
  setUp(resetLogs);

  test('a live scope keeps its singletons reachable', () async {
    final scope = cobaltTestRoot();
    final ref = seed(scope);

    await collect();

    expect(ref.target, isNotNull, reason: 'scope is still alive');
    await scope.dispose();
  });

  test('a disposed scope releases its singletons to the collector', () async {
    var scope = cobaltTestRoot();
    final ref = seed(scope);

    await scope.dispose();
    scope = cobaltTestRoot();

    await collect();

    expect(ref.target, isNull);
    await scope.dispose();
  });

  test('disposing a parent releases instances owned by its children', () async {
    var root = cobaltTestRoot();
    final ref = seed(root.push('child'));

    await root.dispose();
    root = cobaltTestRoot();

    await collect();

    expect(ref.target, isNull);
    await root.dispose();
  });

  test('a parent keeps an unreferenced child alive until dispose', () async {
    final root = cobaltTestRoot();
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
      var scope = cobaltTestRoot();
      final ref = seed(scope);
      final keepAlive = scope;

      scope = cobaltTestRoot();
      await collect();

      expect(ref.target, isNotNull, reason: 'owner never called dispose');
      await keepAlive.dispose();
      await scope.dispose();
    },
  );
}
