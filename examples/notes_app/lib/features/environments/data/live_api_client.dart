import 'package:cobalt/cobalt.dart';
import 'package:notes_app/core/app_config.dart';
import 'package:notes_app/features/environments/domain/api_client.dart';

@CobaltInject(exposeAs: ApiClient)
@CobaltEnvironment.prod
@CobaltEnvironment.stage
class LiveApiClient implements ApiClient {
  LiveApiClient(this._config);

  final AppConfig _config;

  @override
  String get implementation => 'LiveApiClient';

  @override
  String? get endpoint => _config.apiBaseUrl;

  @override
  Future<List<String>> fetchHeadlines() async {
    await Future<void>.delayed(Duration.zero);
    return ['the network would answer here'];
  }
}
