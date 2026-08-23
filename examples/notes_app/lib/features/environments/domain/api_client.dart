abstract interface class ApiClient {
  String get describe;

  Future<List<String>> fetchHeadlines();
}
