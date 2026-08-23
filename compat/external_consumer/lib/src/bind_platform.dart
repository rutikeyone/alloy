import 'package:alloy/alloy.dart';
import 'package:alloy_external_consumer/src/boot_log.dart';

@AlloyBootstrap(order: -10)
class BindPlatform implements AlloyBootstrapStep, Disposable {
  BindPlatform();

  @override
  String get name => 'bind-platform';

  @override
  void run() => BootLog.record(name);

  @override
  void dispose() => BootLog.record('$name released');
}
