import 'package:cobalt/cobalt.dart';
import 'package:testing_patterns/src/clock.dart';
import 'package:testing_patterns/src/greeter.dart';
import 'package:testing_patterns/src/greeting_store.dart';

/// The production graph. Tests use this one — not a special test graph.
///
/// That is the point: a test that builds a different graph proves the test
/// graph works, which is not the thing anybody wanted to know.
class AppScope implements CobaltScopeBuilder {
  const AppScope();

  @override
  void build(CobaltScope scope) {
    scope
      ..registerLazySingleton<Clock>(const _SystemClockFactory())
      ..registerLazySingleton<GreetingStore>(const _HttpGreetingStoreFactory())
      ..registerLazySingleton<Greeter>(const GreeterFactory());
  }
}

final class _SystemClockFactory implements CobaltFactory<Clock> {
  const _SystemClockFactory();

  @override
  Clock create(CobaltResolver resolver) => const SystemClock();
}

final class _HttpGreetingStoreFactory implements CobaltFactory<GreetingStore> {
  const _HttpGreetingStoreFactory();

  @override
  GreetingStore create(CobaltResolver resolver) => const HttpGreetingStore();
}

/// Public because overriding a consumer in a child scope needs to re-register
/// it, and re-registering means naming its factory.
final class GreeterFactory implements CobaltFactory<Greeter> {
  const GreeterFactory();

  @override
  Greeter create(CobaltResolver resolver) =>
      Greeter(resolver.get<Clock>(), resolver.get<GreetingStore>());
}
