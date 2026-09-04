import 'package:cobalt/cobalt.dart';
import 'package:notes_app/bootstrap/boot_log.dart';

@CobaltBootstrap()
class LoadRemoteConfig implements CobaltBootstrapStep {
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
