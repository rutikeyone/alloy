import 'package:cobalt_flutter/cobalt_flutter.dart';
import 'package:cobalt_talker/cobalt_talker.dart';
import 'package:graph_events/app/audit_log.dart';
import 'package:graph_events/app/report_log.dart';
import 'package:talker/talker.dart';

/// Four destinations, three mechanisms.
///
/// `CobaltTalkerObserver` is a full observer, because talker has a notion of a
/// log *kind* and can colour each event differently. Two more are sinks fanned
/// out by [CobaltMultiSink], which keeps going when one of them throws — losing
/// the console should not cost you the audit trail. `CobaltLogSink.from` is the
/// whole integration for a logger with no adapter: one callback, no package,
/// no class.
///
/// `CobaltErrorObserver` is the fourth, and a different shape on purpose. A log
/// sink is handed every line; this is handed only failures, each with the
/// events that led up to it — which is what a crash reporter can actually act
/// on. [reports] gets `reportAt: warning` because this example exists to show
/// a teardown failure, and teardown failures are warnings; the default stays
/// at `error` so a real app does not page its reporter on every hiccup.
List<CobaltObserver> graphEventsObservers({
  required Talker talker,
  required AuditLog audit,
  required ReportLog reports,
}) => [
  CobaltTalkerObserver(talker, verbose: true),
  CobaltLogObserver(
    CobaltMultiSink([
      const CobaltPrintLogSink(),
      CobaltLogSink.from(
        (record) => audit.write('${record.level.name} ${record.message}'),
      ),
    ]),
  ),
  CobaltErrorObserver(
    CobaltErrorSink.from(reports.add),
    reportAt: CobaltLogLevel.warning,
  ),
];
