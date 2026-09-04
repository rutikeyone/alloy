import 'package:cobalt/cobalt.dart';

@cobaltInject
class Config {
  Config();

  final String environment = 'test';
}

@cobaltInject
class Repository {
  Repository(this.config);

  final Config config;

  final _values = <String, int>{};

  int read(String key) => _values[key] ?? 0;

  void write(String key, int value) => _values[key] = value;
}

@cobaltInject
class Telemetry implements Disposable {
  Telemetry();

  final events = <String>[];
  var isClosed = false;

  void record(String event) => events.add(event);

  @override
  void dispose() => isClosed = true;
}
