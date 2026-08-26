import 'package:alloy_flutter/alloy_flutter.dart';
import 'package:alloy_talker/alloy_talker.dart';
import 'package:graph_events/app/audit_log.dart';
import 'package:graph_events/app/report_log.dart';
import 'package:talker/talker.dart';

/// Four destinations, three mechanisms.
///
/// `AlloyTalkerObserver` is a full observer, because talker has a notion of a
/// log *kind* and can colour each event differently. Two more are sinks fanned
/// out by [AlloyMultiSink], which keeps going when one of them throws — losing
/// the console should not cost you the audit trail. `AlloyLogSink.from` is the
/// whole integration for a logger with no adapter: one callback, no package,
/// no class.
///
/// `AlloyDevToolsObserver` is the fifth, and costs nothing to add: it posts
/// each event to the VM service, where DevTools' Logging view shows it without
/// any extension installed. It is guarded because a release build has no
/// business paying for it.
///
/// `AlloyErrorObserver` is the fourth, and a different shape on purpose. A log
/// sink is handed every line; this is handed only failures, each with the
/// events that led up to it — which is what a crash reporter can actually act
/// on. [reports] gets `reportAt: warning` because this example exists to show
/// a teardown failure, and teardown failures are warnings; the default stays
/// at `error` so a real app does not page its reporter on every hiccup.
List<AlloyObserver> graphEventsObservers({
  required Talker talker,
  required AuditLog audit,
  required ReportLog reports,
}) => [
  AlloyTalkerObserver(talker, verbose: true),
  AlloyLogObserver(
    AlloyMultiSink([
      const AlloyPrintLogSink(),
      AlloyLogSink.from(
        (record) => audit.write('${record.level.name} ${record.message}'),
      ),
    ]),
  ),
  AlloyErrorObserver(
    AlloyErrorSink.from(reports.add),
    reportAt: AlloyLogLevel.warning,
  ),
  if (_devToolsEnabled) const AlloyDevToolsObserver(),
];

/// True only where asserts run, which is where the VM service exists at all.
bool get _devToolsEnabled {
  var enabled = false;
  assert(() {
    enabled = true;
    return true;
  }());
  return enabled;
}
