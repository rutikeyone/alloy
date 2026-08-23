import 'package:alloy/alloy.dart';
import 'package:notes_app/bootstrap/load_remote_config.dart';

@alloySingleton
class AppConfig {
  AppConfig();

  final String apiBaseUrl = LoadRemoteConfig.apiBaseUrl;
}
