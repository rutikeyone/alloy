import 'package:alloy/alloy.dart';
import 'package:notes_app/core/event_log.dart';

@AlloyInit()
class Telemetry implements AsyncInitializable {
  Telemetry(this._log);

  final EventLog _log;

  var isStarted = false;

  @override
  Future<void> init() async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    isStarted = true;
    _log.record('telemetry started');
  }
}
