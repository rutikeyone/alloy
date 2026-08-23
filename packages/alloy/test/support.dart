import 'dart:async';

import 'package:alloy/alloy.dart';

final disposeLog = <String>[];
final initLog = <String>[];

class Recorder implements Disposable {
  Recorder(this.label);

  final String label;

  @override
  void dispose() => disposeLog.add(label);
}

class AsyncRecorder implements AsyncDisposable {
  AsyncRecorder(this.label);

  final String label;

  @override
  Future<void> dispose() async {
    await Future<void>.delayed(Duration.zero);
    disposeLog.add(label);
  }
}

class Logger extends Recorder {
  Logger() : super('Logger');
}

class ApiClient extends Recorder {
  ApiClient(this.logger) : super('ApiClient');

  final Logger logger;
}

class LoggerFactory implements AlloyFactory<Logger> {
  const LoggerFactory();

  @override
  Logger create(AlloyResolver resolver) => Logger();
}

class ApiClientFactory implements AlloyFactory<ApiClient> {
  const ApiClientFactory();

  @override
  ApiClient create(AlloyResolver resolver) => ApiClient(resolver.get<Logger>());
}

class PropertyTarget implements AlloyInjectable {
  late final Logger logger;
  var injected = false;

  @override
  void onInject(AlloyResolver resolver) {
    logger = resolver.get<Logger>();
    injected = true;
  }
}

class PropertyTargetFactory implements AlloyFactory<PropertyTarget> {
  const PropertyTargetFactory();

  @override
  PropertyTarget create(AlloyResolver resolver) => PropertyTarget();
}

class Greeting {
  Greeting(this.text);

  final String text;
}

class GreetingFactory implements AlloyParamFactory<Greeting, String> {
  const GreetingFactory();

  @override
  Greeting create(AlloyResolver resolver, String param) =>
      Greeting('hi $param');
}

class SlowService {
  SlowService(this.label);

  final String label;
}

class SlowFactory implements AlloyAsyncFactory<SlowService> {
  const SlowFactory(this.label, this.millis);

  final String label;
  final int millis;

  @override
  Future<SlowService> create(AlloyResolver resolver) async {
    await Future<void>.delayed(Duration(milliseconds: millis));
    initLog.add(label);
    return SlowService(label);
  }
}

void resetLogs() {
  disposeLog.clear();
  initLog.clear();
}

class RecorderFactory implements AlloyAsyncFactory<AsyncRecorder> {
  const RecorderFactory();

  @override
  Future<AsyncRecorder> create(AlloyResolver resolver) async {
    await Future<void>.delayed(const Duration(milliseconds: 30));
    return AsyncRecorder('async-singleton');
  }
}

/// Runs [body] capturing everything it prints into [lines].
void runZonedPrint(List<String> lines, void Function() body) => runZoned(
  body,
  zoneSpecification: ZoneSpecification(
    print: (_, _, _, line) => lines.add(line),
  ),
);
