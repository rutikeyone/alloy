import 'package:alloy/alloy.dart';

class Clock {
  DateTime now() => DateTime.now();
}

class EventLog implements Disposable {
  final entries = <String>[];
  var isClosed = false;

  void add(String entry) => entries.add(entry);

  @override
  void dispose() => isClosed = true;
}

class CounterStorage implements AsyncDisposable {
  CounterStorage(this._log);

  final EventLog _log;
  final _values = <String, int>{};
  var isClosed = false;

  Future<void> warmUp() async {
    await Future<void>.delayed(Duration.zero);
    _log.add('storage warmed up');
  }

  int read(String key) => _values[key] ?? 0;

  void write(String key, int value) => _values[key] = value;

  @override
  Future<void> dispose() async {
    isClosed = true;
    _log.add('storage closed');
  }
}

class Counter {
  Counter(this._storage, this._log, this.sessionId);

  final CounterStorage _storage;
  final EventLog _log;
  final String sessionId;

  int get value => _storage.read(sessionId);

  void increment() {
    _storage.write(sessionId, value + 1);
    _log.add('$sessionId -> $value');
  }
}

class ClockFactory implements AlloyFactory<Clock> {
  const ClockFactory();

  @override
  Clock create(AlloyResolver resolver) => Clock();
}

class EventLogFactory implements AlloyFactory<EventLog> {
  const EventLogFactory();

  @override
  EventLog create(AlloyResolver resolver) => EventLog();
}

class CounterStorageFactory implements AlloyAsyncFactory<CounterStorage> {
  const CounterStorageFactory();

  @override
  Future<CounterStorage> create(AlloyResolver resolver) async {
    final storage = CounterStorage(resolver.get<EventLog>());
    await storage.warmUp();
    return storage;
  }
}

class CounterFactory implements AlloyParamFactory<Counter, String> {
  const CounterFactory();

  @override
  Counter create(AlloyResolver resolver, String param) =>
      Counter(resolver.get<CounterStorage>(), resolver.get<EventLog>(), param);
}

class BindPlatform implements AlloyBootstrapStep {
  const BindPlatform();

  @override
  String get name => 'platform-binding';

  @override
  void run() {}
}

class AppScope implements AlloyScopeBuilder {
  const AppScope();

  @override
  void build(AlloyScope scope) {
    scope
      ..registerLazySingleton<Clock>(const ClockFactory())
      ..registerLazySingleton<EventLog>(const EventLogFactory())
      ..registerAsyncSingleton<CounterStorage>(const CounterStorageFactory());
  }
}

AlloyScope openSession(AlloyScope root, String id) =>
    root.push('session:$id')
      ..registerParamFactory<Counter, String>(const CounterFactory());

Future<AlloyScope> startApp() => AlloyApplication.start(
  root: const AppScope(),
  bootstrap: const [BindPlatform()],
  rootName: 'app',
);
