import 'package:alloy/alloy.dart';
import 'package:alloy_test/alloy_test.dart';
import 'package:alloy_talker/alloy_talker.dart';
import 'package:talker/talker.dart';
import 'package:test/test.dart';

class Marker implements Disposable {
  @override
  void dispose() {}
}

void main() {
  late Talker talker;

  setUp(() => talker = Talker());

  List<String> titles() => [for (final d in talker.history) d.title ?? ''];
  List<String?> messages() => [for (final d in talker.history) d.message];

  group('AlloyTalkerObserver', () {
    test('files each kind of event under its own title', () async {
      final root = alloyTestRoot(
        name: 'app',
        observers: [AlloyTalkerObserver(talker)],
      );
      root.push('session');
      await root.dispose();

      expect(titles(), contains('alloy-scope'));
      expect(
        messages().join('\n'),
        allOf(contains('scope "app/session" pushed'), contains('disposing')),
      );
    });

    test('stays quiet about instances unless asked', () {
      final root = alloyTestRoot(
        name: 'app',
        observers: [AlloyTalkerObserver(talker)],
      )..registerLazySingleton<Marker>(FnFactory((_) => Marker()));

      root.get<Marker>();

      expect(titles(), isNot(contains('alloy-instance')));
    });

    test('reports every instance in verbose mode', () {
      final root = alloyTestRoot(
        name: 'app',
        observers: [AlloyTalkerObserver(talker, verbose: true)],
      )..registerLazySingleton<Marker>(FnFactory((_) => Marker()));

      root.get<Marker>();

      expect(titles(), contains('alloy-instance'));
      expect(messages().join('\n'), contains('built Marker in "app"'));
    });

    test('a teardown failure becomes an alloy-failure entry', () async {
      final root = alloyTestRoot(
        name: 'app',
        observers: [AlloyTalkerObserver(talker)],
      )..registerSingleton<_Angry>(_Angry());

      await expectLater(root.dispose(), throwsA(isA<AlloyDisposeError>()));

      expect(titles(), contains('alloy-failure'));
      final failure = talker.history.firstWhere(
        (d) => d.title == 'alloy-failure',
      );
      expect(failure.exception, isA<StateError>());
      expect(failure.logLevel, LogLevel.warning);
    });

    test('startup milestones carry the step names', () async {
      await alloyTestScope(
        root: const _MarkerScope(),
        bootstrap: [_Step('platform')],
        rootName: 'app',
        observers: [AlloyTalkerObserver(talker)],
      );

      expect(titles(), contains('alloy-startup'));
      expect(
        messages().join('\n'),
        allOf(
          contains('bootstrap "platform" started'),
          contains('bootstrap "platform" done'),
        ),
      );
    });
  });

  /// Coverage found these five mappings unexercised, three of them the failure
  /// paths — in an adapter that exists so failures are visible.
  group('the paths you need when something breaks', () {
    test(
      'a failing async initializer becomes an alloy-failure entry',
      () async {
        await expectLater(
          alloyTestScope(
            root: const _ExplodingScope(),
            rootName: 'app',
            observers: [AlloyTalkerObserver(talker)],
          ),
          throwsA(isA<StateError>()),
        );

        final failure = talker.history.firstWhere(
          (entry) => entry.title == 'alloy-failure',
        );
        expect(failure.message, contains('failed to initialize'));
        expect(failure.exception, isA<StateError>());
        expect(failure.logLevel, LogLevel.error);
      },
    );

    test('a failing bootstrap step names the step', () async {
      await expectLater(
        alloyTestScope(
          root: const _MarkerScope(),
          bootstrap: [_Exploding('platform')],
          rootName: 'app',
          observers: [AlloyTalkerObserver(talker)],
        ),
        throwsA(isA<AlloyBootstrapError>()),
      );

      final failure = talker.history.firstWhere(
        (entry) => entry.title == 'alloy-failure',
      );
      expect(failure.message, 'bootstrap "platform" failed');
      expect(failure.logLevel, LogLevel.error);
    });

    /// The event phase 3 added to replace a swallowed `catch (_)`: a step that
    /// ran, then could not be released while a later failure rolled startup
    /// back. Reported as a warning — the headline is the step that failed.
    test(
      'a step that cannot be released while rolling back is reported',
      () async {
        await expectLater(
          alloyTestScope(
            root: const _MarkerScope(),
            bootstrap: [_Stubborn('platform'), _Exploding('config')],
            rootName: 'app',
            observers: [AlloyTalkerObserver(talker)],
          ),
          throwsA(isA<AlloyBootstrapError>()),
        );

        final messages = [for (final entry in talker.history) entry.message];
        expect(
          messages.join('\n'),
          allOf(
            contains('bootstrap "config" failed'),
            contains('bootstrap "platform" could not be released'),
          ),
        );
        final release = talker.history.firstWhere(
          (entry) => entry.message?.contains('could not be released') ?? false,
        );
        expect(release.logLevel, LogLevel.warning);
      },
    );
  });

  group('startup that succeeds', () {
    test(
      'reports the levels it is about to run and how long it took',
      () async {
        final scope = await alloyTestScope(
          root: const _AsyncScope(),
          rootName: 'app',
          observers: [AlloyTalkerObserver(talker)],
        );
        expect(scope.state, AlloyScopeState.active);

        expect(
          messages().join('\n'),
          allOf(
            contains('scope "app" initializing, 1 level(s)'),
            contains('scope "app" ready in'),
          ),
        );
      },
    );

    test('a transient is marked loose, because the scope does not keep it', () {
      final root = alloyTestRoot(
        name: 'app',
        observers: [AlloyTalkerObserver(talker, verbose: true)],
      )..registerFactory<Marker>(FnFactory((_) => Marker()));

      root.get<Marker>();

      expect(
        messages().join('\n'),
        contains('built Marker in "app" as transient (loose)'),
      );
    });
  });
}

final class _MarkerScope implements AlloyScopeBuilder {
  const _MarkerScope();

  @override
  void build(AlloyScope scope) =>
      scope.registerLazySingleton<Marker>(FnFactory((_) => Marker()));
}

class _Step implements AlloyBootstrapStep {
  _Step(this.name);

  @override
  final String name;

  @override
  void run() {}
}

class _Angry implements Disposable {
  @override
  void dispose() => throw StateError('no');
}

final class _AsyncScope implements AlloyScopeBuilder {
  const _AsyncScope();

  @override
  void build(AlloyScope scope) => scope.registerAsyncSingleton<Marker>(
    AsyncFnFactory((_) async => Marker()),
  );
}

final class _ExplodingScope implements AlloyScopeBuilder {
  const _ExplodingScope();

  @override
  void build(AlloyScope scope) => scope.registerAsyncSingleton<Marker>(
    AsyncFnFactory((_) async => throw StateError('no')),
  );
}

class _Exploding implements AlloyBootstrapStep {
  _Exploding(this.name);

  @override
  final String name;

  @override
  void run() => throw StateError('no');
}

/// Runs, then refuses to be released.
class _Stubborn implements AlloyBootstrapStep, Disposable {
  _Stubborn(this.name);

  @override
  final String name;

  @override
  void run() {}

  @override
  void dispose() => throw StateError('no');
}
