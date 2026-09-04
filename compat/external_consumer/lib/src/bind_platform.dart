import 'package:cobalt/cobalt.dart';
import 'package:cobalt_external_consumer/src/boot_log.dart';

@CobaltBootstrap(order: -10)
class BindPlatform implements CobaltBootstrapStep, Disposable {
  BindPlatform();

  @override
  String get name => 'bind-platform';

  @override
  void run() => BootLog.record(name);

  @override
  void dispose() => BootLog.record('$name released');
}
