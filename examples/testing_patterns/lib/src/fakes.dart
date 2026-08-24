import 'package:testing_patterns/src/clock.dart';
import 'package:testing_patterns/src/greeting_store.dart';

/// Fakes live in `lib/`, not `test/`, so a consumer of this package can reuse
/// them in their own tests. That is the same reason a package ships a
/// `*_test_utils` library.
class FixedClock implements Clock {
  const FixedClock(this._now);

  final DateTime _now;

  @override
  DateTime now() => _now;
}

class InMemoryGreetingStore implements GreetingStore {
  const InMemoryGreetingStore(this.greeting);

  final String greeting;

  @override
  Future<String> greetingFor(String name) async => greeting;
}
