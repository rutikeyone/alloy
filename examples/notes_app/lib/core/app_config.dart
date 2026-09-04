import 'package:cobalt/cobalt.dart';
import 'package:notes_app/bootstrap/load_remote_config.dart';

@cobaltSingleton
class AppConfig {
  AppConfig();

  final String apiBaseUrl = LoadRemoteConfig.apiBaseUrl;
}
