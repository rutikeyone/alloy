import 'package:alloy/alloy.dart';
import 'package:notes_app/bootstrap/boot_log.dart';

@AlloyBootstrap(order: 20)
@AlloyEnvironment.prod
@AlloyEnvironment.stage
class ReportCrashes implements AlloyBootstrapStep {
  ReportCrashes();

  @override
  String get name => 'report-crashes';

  @override
  void run() => BootLog.record(name);
}
