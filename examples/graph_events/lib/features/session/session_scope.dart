import 'package:cobalt_flutter/cobalt_flutter.dart';
import 'package:graph_events/core/telemetry.dart';

/// A child scope worth opening and closing while watching the log.
///
/// [breaks] decides whether closing it fails — the interesting case, because
/// a teardown failure is exactly what you want a log for.
class SessionScope implements CobaltScopeBuilder {
  const SessionScope({required this.breaks});

  final bool breaks;

  @override
  void build(CobaltScope scope) {
    scope.registerAsyncSingleton<Telemetry>(const TelemetryFactory());
    if (breaks) {
      scope.registerSingleton<StubbornResource>(
        const StubbornResourceFactory().create(scope),
      );
    }
  }
}
