import 'package:alloy/alloy.dart';
import 'package:notes_app/bootstrap/boot_log.dart';

@AlloyBootstrap(order: 10)
class WarmFonts implements AlloyBootstrapStep {
  WarmFonts();

  @override
  String get name => 'warm-fonts';

  @override
  void run() => BootLog.record(name);
}
