import 'package:cobalt/cobalt.dart';
import 'package:cobalt_external_consumer/src/clock.dart';
import 'package:cobalt_external_consumer/src/telemetry.dart';

@cobaltInject
class Reporter {
  Reporter(this.clock, this.telemetry);

  final Clock clock;

  /// Optional: nothing registers [Telemetry], so this arrives null rather than
  /// failing the build. Making it non-nullable is a build error.
  final Telemetry? telemetry;

  String describe() => telemetry == null
      ? 'reporting disabled'
      : 'reporting to ${telemetry!.endpoint}';
}
