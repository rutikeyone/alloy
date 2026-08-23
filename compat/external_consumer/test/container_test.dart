import 'package:alloy/alloy.dart';
import 'package:alloy_external_consumer/alloy_external_consumer.dart';
import 'package:test/test.dart';

void main() {
  late AlloyScope scope;

  setUp(() async {
    BootLog.clear();
    scope = await $startAlloy();
  });

  tearDown(() async {
    if (scope.state != AlloyScopeState.disposed) await scope.dispose();
  });

  test('the generated container is named by @AlloyScopeRoot', () {
    expect(scope.name, 'consumer');
  });

  test('a bootstrap step runs before the graph is built', () {
    expect(BootLog.entries, ['bind-platform']);
  });

  test('a bootstrap step is released with the scope', () async {
    await scope.dispose();
    expect(BootLog.entries, ['bind-platform', 'bind-platform released']);
  });

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
}
