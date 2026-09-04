import 'package:cobalt/cobalt.dart';
import 'package:cobalt_external_consumer/src/clock.dart';
import 'package:cobalt_external_consumer/src/device_info.dart';

@cobaltInject
class Diagnostics {
  Diagnostics(this.device, this.clock);

  final DeviceInfo device;
  final Clock clock;

  String describe() => '${device.model} at ${clock.now().toIso8601String()}';
}
