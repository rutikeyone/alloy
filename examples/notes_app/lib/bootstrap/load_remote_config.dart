import 'package:alloy/alloy.dart';
import 'package:notes_app/bootstrap/boot_log.dart';

@AlloyBootstrap()
class LoadRemoteConfig implements AlloyBootstrapStep {
  LoadRemoteConfig();

  static const unset = 'unset';

  static String apiBaseUrl = unset;

  static void reset() => apiBaseUrl = unset;

  @override
  String get name => 'load-remote-config';

  @override
  Future<void> run() async {
    await Future<void>.delayed(Duration.zero);
    apiBaseUrl = 'https://notes.example/v1';
    BootLog.record(name);
  }
}
