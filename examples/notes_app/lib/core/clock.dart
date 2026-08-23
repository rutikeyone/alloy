import 'package:alloy/alloy.dart';

@alloyInject
class Clock {
  Clock();

  DateTime now() => DateTime.utc(2026, 8, 22);
}
