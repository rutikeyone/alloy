import 'package:alloy/alloy.dart';
import 'package:alloy_external_consumer/src/clock.dart';
import 'package:alloy_external_consumer/src/device_info.dart';

@alloyInject
class Diagnostics {
  Diagnostics(this.device, this.clock);

  final DeviceInfo device;
  final Clock clock;

  String describe() => '${device.model} at ${clock.now().toIso8601String()}';
}
