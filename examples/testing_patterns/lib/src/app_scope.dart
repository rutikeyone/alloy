import 'package:alloy/alloy.dart';
import 'package:testing_patterns/src/clock.dart';
import 'package:testing_patterns/src/greeter.dart';
import 'package:testing_patterns/src/greeting_store.dart';

/// The production graph. Tests use this one — not a special test graph.
///
/// That is the point: a test that builds a different graph proves the test
/// graph works, which is not the thing anybody wanted to know.
class AppScope implements AlloyScopeBuilder {
  const AppScope();

  @override
  void build(AlloyScope scope) {
    scope
      ..registerLazySingleton<Clock>(const _SystemClockFactory())
      ..registerLazySingleton<GreetingStore>(const _HttpGreetingStoreFactory())
      ..registerLazySingleton<Greeter>(const GreeterFactory());
  }
}

final class _SystemClockFactory implements AlloyFactory<Clock> {
  const _SystemClockFactory();

  @override
  Clock create(AlloyResolver resolver) => const SystemClock();
}

final class _HttpGreetingStoreFactory implements AlloyFactory<GreetingStore> {
  const _HttpGreetingStoreFactory();

  @override
  GreetingStore create(AlloyResolver resolver) => const HttpGreetingStore();
}

/// Public because overriding a consumer in a child scope needs to re-register
/// it, and re-registering means naming its factory.
final class GreeterFactory implements AlloyFactory<Greeter> {
  const GreeterFactory();

  @override
  Greeter create(AlloyResolver resolver) =>
      Greeter(resolver.get<Clock>(), resolver.get<GreetingStore>());
}
