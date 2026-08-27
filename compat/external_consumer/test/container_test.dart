import 'package:alloy/alloy.dart';
import 'package:alloy_external_consumer/alloy_external_consumer.dart';
import 'package:alloy_test/alloy_test.dart';
import 'package:test/test.dart';

void main() {
  late AlloyScope scope;

  setUp(() async {
    BootLog.clear();
    scope = await $startAlloy();
  });

  // The closing form, because the tests below hand `scope` a different graph.
  // No guard on the state: dispose() returns early when it already ran.
  tearDown(() => scope.dispose());

  test('the generated container is named by @AlloyScopeRoot', () {
    expect(scope.name, 'consumer');
  });

  test('a bootstrap step runs before the graph is built', () {
    expect(BootLog.entries, ['bind-platform']);
  });

  test(
    'a bootstrap step is released with the scope, and released last',
    () async {
      await scope.dispose();
      // The module's channel is closed on the way down too; the bootstrap step
      // was adopted before anything else existed, so it goes after all of it.
      expect(BootLog.entries, [
        'bind-platform',
        'channel closed',
        'bind-platform released',
      ]);
    },
  );

  test('exposeAs publishes the interface, not the implementation', () {
    expect(scope.get<Clock>(), isA<SystemClock>());
    expect(scope.isRegistered<SystemClock>(), isFalse);
  });

  test('dependsOn is honoured across async initializers', () {
    expect(scope.get<Database>().isOpen, isTrue);
    expect(scope.get<SearchIndex>().isBuilt, isTrue);
  });

  test('property injection fills late final fields', () {
    expect(
      scope.get<Report>().render(),
      'report 2026-08-23T00:00:00.000Z indexed=true',
    );
  });

  test('a transient is a fresh instance per resolution', () {
    expect(identical(scope.get<Report>(), scope.get<Report>()), isFalse);
  });

  test('two instantiations of one generic are separate registrations', () {
    expect(scope.get<Repository<User>>(), isA<UserRepository>());
    expect(scope.get<Repository<Order>>(), isA<OrderRepository>());
  });

  test('a generic dependency resolves the matching instantiation', () {
    final catalog = scope.get<Catalog>();
    expect(catalog.users.all().single.name, 'ada');
    expect(catalog.orders.all().map((order) => order.id), [1, 2]);
  });

  group('a module registers types the package does not own', () {
    test('a member becomes an ordinary registration', () {
      expect(scope.get<Channel>().name, 'channel');
    });

    test('an async member is built during startup and gets its argument', () {
      final envelope = scope.get<Envelope>();
      expect(envelope.stamp, 'stamped');
      expect(identical(envelope.channel, scope.get<Channel>()), isTrue);
    });

    test(
      'the dispose function closes it, after what was built on it',
      () async {
        final channel = scope.get<Channel>();
        scope.get<Envelope>();
        BootLog.clear();

        await scope.dispose();

        expect(channel.isOpen, isFalse);
        // The bootstrap step was adopted first, so it is released last; the
        // channel closes before it and after everything that used it.
        expect(BootLog.entries, ['channel closed', 'bind-platform released']);
      },
    );
  });

  group('an optional dependency', () {
    test('arrives null when the graph supplies nothing', () {
      expect(scope.get<Reporter>().telemetry, isNull);
      expect(scope.get<Reporter>().describe(), 'reporting disabled');
    });

    test('did not stop the required one beside it from resolving', () {
      expect(scope.get<Reporter>().clock, isA<SystemClock>());
    });

    test('getOrNull says absent where get would throw', () {
      expect(scope.getOrNull<Telemetry>(), isNull);
      expect(() => scope.get<Telemetry>(), throwsA(isA<AlloyError>()));
    });
  });

  group('a registration promised through provides', () {
    test('is not emitted by the generator, only trusted', () {
      expect(scope.isRegistered<DeviceInfo>(), isFalse);
    });

    test(
      'resolves once a builder composes it with the generated one',
      () async {
        await scope.dispose();
        scope = await startConsumer(device: const DeviceInfo('pixel'));

        expect(scope.get<Diagnostics>().describe(), startsWith('pixel at '));
      },
    );
  });

  // checkGraph's own tests run on fixtures. This is the first time it walks a
  // generated graph, and it does it from outside the workspace, where the
  // helper package resolves like any other dependency.
  group('checking the graph by running it', () {
    test('names the promised registration nothing keeps', () async {
      final report = await checkGraph(scope);

      expect(report.isComplete, isFalse);
      expect(
        report.failures.map((f) => f.key.toString()),
        contains(contains('Diagnostics')),
        reason: 'provides tells the build to trust; only running finds out',
      );
    });

    test('and reports it complete once a builder keeps it', () async {
      await scope.dispose();
      scope = await startConsumer(device: const DeviceInfo('pixel'));

      final report = await checkGraph(scope);

      expect(report.isComplete, isTrue, reason: '$report');
    });
  });

  group('a class taking values from the call site', () {
    test('is registered as a parameterized factory, not a plain one', () {
      expect(
        scope.debugKindOf(const AlloyKey(NoteEditor)),
        AlloyRegistrationKind.parameterized,
      );
      expect(
        () => scope.get<NoteEditor>(),
        throwsA(isA<AlloyParamRequiredError>()),
      );
    });

    test('takes its values by name and the rest from the graph', () {
      final editor = scope.getWithParam<NoteEditor, $NoteEditorArgs>((
        id: 7,
        title: 'notes',
        draft: true,
      ));

      expect(
        editor.describe(),
        '7 "notes" (draft) at 2026-08-23T00:00:00.000Z',
      );
      expect(
        editor.clock,
        isA<SystemClock>(),
        reason: 'the clock came from the container, the rest from here',
      );
    });

    test('builds a fresh one per call, and the scope keeps neither', () {
      final first = scope.getWithParam<NoteEditor, $NoteEditorArgs>((
        id: 1,
        title: 'a',
        draft: false,
      ));
      final second = scope.getWithParam<NoteEditor, $NoteEditorArgs>((
        id: 1,
        title: 'a',
        draft: false,
      ));

      expect(identical(first, second), isFalse);
    });
  });
}
