import 'package:alloy/alloy.dart';
import 'package:notes_app/bootstrap/boot_log.dart';

@AlloyBootstrap(order: -10)
class BindPlatform implements AlloyBootstrapStep, Disposable {
  BindPlatform();

  var isBound = false;

  @override
  String get name => 'bind-platform';

  @override
  void run() {
    isBound = true;
    BootLog.record(name);
  }

  @override
  void dispose() {
    isBound = false;
    BootLog.record('$name released');
  }
}
