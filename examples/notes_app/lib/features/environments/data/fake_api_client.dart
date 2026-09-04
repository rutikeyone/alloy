import 'package:cobalt/cobalt.dart';
import 'package:notes_app/features/environments/domain/api_client.dart';

@CobaltInject(exposeAs: ApiClient)
@CobaltEnvironment.dev
@CobaltEnvironment.test
class FakeApiClient implements ApiClient {
  FakeApiClient();

  @override
  String get implementation => 'FakeApiClient';

  @override
  String? get endpoint => null;

  @override
  Future<List<String>> fetchHeadlines() async => const [
    'a canned headline',
    'another canned headline',
  ];
}
