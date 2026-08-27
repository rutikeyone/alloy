import 'package:alloy_flutter/alloy_flutter.dart';
import 'package:alloy_test/alloy_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Where the fixtures report their teardown, replaced by every `setUp`.
///
/// It used to be a list cleared per test, which is not the same thing:
/// teardown is not awaited, so a scope from the previous test can still be
/// releasing and append after the clear. A [Service] captures the recorder it
/// was *built* with, so a late report lands in the test it came from.
late DisposeRecorder recorder;

class Service implements Disposable {
  Service(this.label) : _recorder = recorder;

  final String label;
  final DisposeRecorder _recorder;

  @override
  void dispose() => _recorder.record(label);
}

class ServiceFactory implements AlloyFactory<Service> {
  const ServiceFactory(this.label);

  final String label;

  @override
  Service create(AlloyResolver resolver) => Service(label);
}

class SlowService {
  const SlowService();
}

class SlowFactory implements AlloyAsyncFactory<SlowService> {
  const SlowFactory();

  @override
  Future<SlowService> create(AlloyResolver resolver) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return const SlowService();
  }
}

class BoomFactory implements AlloyAsyncFactory<SlowService> {
  const BoomFactory();

  @override
  Future<SlowService> create(AlloyResolver resolver) async =>
      throw StateError('init failed');
}

class SessionScope implements AlloyScopeBuilder {
  const SessionScope();

  @override
  void build(AlloyScope scope) =>
      scope.registerLazySingleton<Service>(const ServiceFactory('session'));
}

class AsyncScope implements AlloyScopeBuilder {
  const AsyncScope({this.fail = false});

  final bool fail;

  @override
  void build(AlloyScope scope) => scope.registerAsyncSingleton<SlowService>(
    fail ? const BoomFactory() : const SlowFactory(),
  );
}

class LabelText extends StatelessWidget {
  const LabelText({super.key});

  @override
  Widget build(BuildContext context) =>
      Text(context.alloy<Service>().label, textDirection: TextDirection.ltr);
}

void main() {
  setUp(() => recorder = DisposeRecorder());

  testWidgets('context.alloy resolves through the widget tree', (tester) async {
    final root = alloyTestRoot(name: 'app')
      ..registerLazySingleton<Service>(const ServiceFactory('root'));

    await tester.pumpWidget(
      AlloyScopeProvider(scope: root, child: const LabelText()),
    );

    expect(find.text('root'), findsOneWidget);
  });

  testWidgets('AlloyScopeWidget shadows the parent inside its subtree', (
    tester,
  ) async {
    final root = alloyTestRoot(name: 'app')
      ..registerLazySingleton<Service>(const ServiceFactory('root'));

    await tester.pumpWidget(
      AlloyScopeProvider(
        scope: root,
        child: const AlloyScopeWidget(
          name: 'session',
          builder: SessionScope(),
          child: LabelText(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('session'), findsOneWidget);
    expect(root.children.single.name, 'session');
  });

  testWidgets('removing the widget disposes the scope it created', (
    tester,
  ) async {
    final root = alloyTestRoot(name: 'app');

    await tester.pumpWidget(
      AlloyScopeProvider(
        scope: root,
        child: const AlloyScopeWidget(
          name: 'session',
          builder: SessionScope(),
          child: LabelText(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('session'), findsOneWidget);

    await tester.pumpWidget(
      AlloyScopeProvider(scope: root, child: const SizedBox.shrink()),
    );
    await tester.pumpAndSettle();

    expect(recorder.entries, ['session']);
    expect(root.children, isEmpty);
  });

  testWidgets('async scopes show the loading widget until init completes', (
    tester,
  ) async {
    final root = alloyTestRoot(name: 'app');

    await tester.pumpWidget(
      AlloyScopeProvider(
        scope: root,
        child: const AlloyScopeWidget(
          name: 'async',
          builder: AsyncScope(),
          loading: Text('loading', textDirection: TextDirection.ltr),
          child: Text('ready', textDirection: TextDirection.ltr),
        ),
      ),
    );

    expect(find.text('loading'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('ready'), findsOneWidget);
  });

  testWidgets('a failing init is routed to errorBuilder', (tester) async {
    final root = alloyTestRoot(name: 'app');

    await tester.pumpWidget(
      AlloyScopeProvider(
        scope: root,
        child: AlloyScopeWidget(
          name: 'async',
          builder: const AsyncScope(fail: true),
          errorBuilder: (context, error) =>
              const Text('failed', textDirection: TextDirection.ltr),
          child: const Text('ready', textDirection: TextDirection.ltr),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('failed'), findsOneWidget);
  });

  testWidgets('resolving without a provider explains what is missing', (
    tester,
  ) async {
    await tester.pumpWidget(const LabelText());

    expect(tester.takeException(), isA<AlloyError>());
  });
}
