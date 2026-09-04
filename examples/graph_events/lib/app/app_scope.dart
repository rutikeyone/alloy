import 'package:cobalt_flutter/cobalt_flutter.dart';
import 'package:graph_events/core/telemetry.dart';

/// What the app owns for as long as it runs.
class AppScope implements CobaltScopeBuilder {
  const AppScope();

  @override
  void build(CobaltScope scope) =>
      scope.registerAsyncSingleton<Telemetry>(const TelemetryFactory());
}

/// A bootstrap step, so phase 0 shows up in the log too.
class WarmUp implements CobaltBootstrapStep, Disposable {
  WarmUp();

  @override
  String get name => 'warm-up';

  @override
  Future<void> run() async =>
      Future<void>.delayed(const Duration(milliseconds: 20));

  @override
  void dispose() {}
}
