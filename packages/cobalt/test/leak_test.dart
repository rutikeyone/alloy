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

/// A long-lived service that keeps whatever registers with it.
class Hub {
  final held = <Object>[];
  void listen(Object who) => held.add(who);
}

class HubFactory implements CobaltFactory<Hub> {
  const HubFactory();

  @override
  Hub create(CobaltResolver resolver) => Hub();
}

class SessionState implements Disposable {
  @override
  void dispose() {}
}

class SessionStateFactory implements CobaltFactory<SessionState> {
  const SessionStateFactory();

  @override
  SessionState create(CobaltResolver resolver) {
    final state = SessionState();
    resolver.get<Hub>().listen(state);
    return state;
  }
}

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

  /// A scope releases what it owns; it cannot take back what it handed out.
  ///
  /// `dispose()` runs on the session object and the scope lets go of it, but
  /// the root-lived hub still points at it, so the collector cannot have it.
  /// No container can do better — the reference is in application code.
  ///
  /// It is pinned because the framework's headline is that a session scope
  /// removes the nine hand-written unsubscribes those two applications carry,
  /// and an application that keeps the subscriptions *and* adds the scope
  /// keeps the leak too. See "What ownership does not do" in the README.
  test(
    'an object handed to something longer-lived outlives its scope',
    () async {
      final root = cobaltTestRoot()
        ..registerLazySingleton<Hub>(const HubFactory());
      final session = root.push('session')
        ..registerLazySingleton<SessionState>(const SessionStateFactory());

      final ref = WeakReference(session.get<SessionState>());
      await session.dispose();
      await collect();

      expect(
        ref.target,
        isNotNull,
        reason:
            'the hub still holds it. If this ever passes as null, either the '
            'runtime started reaching into user references — which it must not '
            '— or the test stopped holding one.',
      );
      expect(root.get<Hub>().held, hasLength(1));

      await root.dispose();
    },
  );
}
