import 'package:alloy/alloy.dart';
import 'package:notes_app/core/app_config.dart';
import 'package:notes_app/features/environments/domain/api_client.dart';

@AlloyInject(exposeAs: ApiClient)
@AlloyEnvironment.prod
@AlloyEnvironment.stage
class LiveApiClient implements ApiClient {
  LiveApiClient(this._config);

  final AppConfig _config;

  @override
  String get describe => 'LiveApiClient → ${_config.apiBaseUrl}';

  @override
  Future<List<String>> fetchHeadlines() async {
    await Future<void>.delayed(Duration.zero);
    return ['the network would answer here'];
  }
}
