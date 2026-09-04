import 'package:cobalt/cobalt.dart';
import 'package:notes_app/bootstrap/boot_log.dart';

@CobaltBootstrap(order: 10)
class WarmFonts implements CobaltBootstrapStep {
  WarmFonts();

  @override
  String get name => 'warm-fonts';

  @override
  void run() => BootLog.record(name);
}
