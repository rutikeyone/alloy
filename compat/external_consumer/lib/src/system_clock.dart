import 'package:cobalt/cobalt.dart';
import 'package:cobalt_external_consumer/src/clock.dart';

@CobaltInject(exposeAs: Clock)
class SystemClock implements Clock {
  SystemClock();

  @override
  DateTime now() => DateTime.utc(2026, 8, 23);
}
