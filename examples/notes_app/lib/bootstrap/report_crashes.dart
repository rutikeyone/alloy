import 'package:cobalt/cobalt.dart';
import 'package:notes_app/bootstrap/boot_log.dart';

@CobaltBootstrap(order: 20)
@CobaltEnvironment.prod
@CobaltEnvironment.stage
class ReportCrashes implements CobaltBootstrapStep {
  ReportCrashes();

  @override
  String get name => 'report-crashes';

  @override
  void run() => BootLog.record(name);
}
