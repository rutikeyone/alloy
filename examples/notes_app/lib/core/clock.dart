import 'package:cobalt/cobalt.dart';

@cobaltInject
class Clock {
  Clock();

  DateTime now() => DateTime.utc(2026, 8, 22);
}
