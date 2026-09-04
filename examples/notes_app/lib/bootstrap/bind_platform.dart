import 'package:cobalt/cobalt.dart';
import 'package:notes_app/bootstrap/boot_log.dart';

@CobaltBootstrap(order: -10)
class BindPlatform implements CobaltBootstrapStep, Disposable {
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
