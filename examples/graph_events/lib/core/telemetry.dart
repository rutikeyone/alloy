import 'package:cobalt_flutter/cobalt_flutter.dart';

/// An async service, so the example has an init graph worth watching.
class Telemetry implements AsyncInitializable, Disposable {
  Telemetry();

  var isStarted = false;

  @override
  Future<void> init() async {
    await Future<void>.delayed(const Duration(milliseconds: 40));
    isStarted = true;
  }

  @override
  void dispose() => isStarted = false;
}

final class TelemetryFactory implements CobaltAsyncFactory<Telemetry> {
  const TelemetryFactory();

  @override
  Future<Telemetry> create(CobaltResolver resolver) async {
    final telemetry = Telemetry();
    await telemetry.init();
    return telemetry;
  }
}

/// Refuses to be released, so the example can show a teardown failure.
class StubbornResource implements Disposable {
  StubbornResource();

  @override
  void dispose() => throw StateError('this handle will not close');
}

final class StubbornResourceFactory implements CobaltFactory<StubbornResource> {
  const StubbornResourceFactory();

  @override
  StubbornResource create(CobaltResolver resolver) => StubbornResource();
}
