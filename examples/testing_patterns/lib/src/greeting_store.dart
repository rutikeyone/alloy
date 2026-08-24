/// Something a test must not reach: the real one would do network I/O.
abstract interface class GreetingStore {
  Future<String> greetingFor(String name);
}

class HttpGreetingStore implements GreetingStore {
  const HttpGreetingStore();

  @override
  Future<String> greetingFor(String name) async {
    await Future<void>.delayed(const Duration(seconds: 2));
    throw UnsupportedError('the real store would hit the network here');
  }
}
