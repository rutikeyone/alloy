import 'package:alloy/alloy.dart';
import 'package:alloy_external_consumer/src/clock.dart';

@AlloyInject(exposeAs: Clock)
class SystemClock implements Clock {
  SystemClock();

  @override
  DateTime now() => DateTime.utc(2026, 8, 23);
}
