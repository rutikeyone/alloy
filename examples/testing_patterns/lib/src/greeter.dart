import 'package:testing_patterns/src/clock.dart';
import 'package:testing_patterns/src/greeting_store.dart';

/// The unit under test. It knows nothing about how its dependencies arrived.
class Greeter {
  Greeter(this._clock, this._store);

  final Clock _clock;
  final GreetingStore _store;

  Future<String> greet(String name) async {
    final greeting = await _store.greetingFor(name);
    return '$greeting, $name — it is ${_clock.now().hour}:00';
  }
}
