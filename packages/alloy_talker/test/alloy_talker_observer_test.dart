import 'package:alloy/alloy.dart';
import 'package:alloy_talker/alloy_talker.dart';
import 'package:talker/talker.dart';
import 'package:test/test.dart';

class Marker implements Disposable {
  @override
  void dispose() {}
}

final class MarkerFactory implements AlloyFactory<Marker> {
  const MarkerFactory();

  @override
  Marker create(AlloyResolver resolver) => Marker();
}

void main() {
  late Talker talker;

  setUp(() => talker = Talker());

  List<String> titles() => [for (final d in talker.history) d.title ?? ''];
  List<String?> messages() => [for (final d in talker.history) d.message];

  group('AlloyTalkerObserver', () {
    test('files each kind of event under its own title', () async {
      final root = AlloyScope.root(
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
      final root = AlloyScope.root(
        name: 'app',
        observers: [AlloyTalkerObserver(talker)],
      )..registerLazySingleton<Marker>(const MarkerFactory());
      addTearDown(root.dispose);

      root.get<Marker>();

      expect(titles(), isNot(contains('alloy-instance')));
    });

    test('reports every instance in verbose mode', () {
      final root = AlloyScope.root(
        name: 'app',
        observers: [AlloyTalkerObserver(talker, verbose: true)],
      )..registerLazySingleton<Marker>(const MarkerFactory());
      addTearDown(root.dispose);

      root.get<Marker>();

      expect(titles(), contains('alloy-instance'));
      expect(messages().join('\n'), contains('built Marker in "app"'));
    });

    test('a teardown failure becomes an alloy-failure entry', () async {
      final root = AlloyScope.root(
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
      final scope = await AlloyApplication.start(
        root: const _MarkerScope(),
        bootstrap: [_Step('platform')],
        rootName: 'app',
        observers: [AlloyTalkerObserver(talker)],
      );
      addTearDown(scope.dispose);

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
}

final class _MarkerScope implements AlloyScopeBuilder {
  const _MarkerScope();

  @override
  void build(AlloyScope scope) =>
      scope.registerLazySingleton<Marker>(const MarkerFactory());
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
