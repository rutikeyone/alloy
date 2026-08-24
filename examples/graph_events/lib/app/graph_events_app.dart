import 'package:alloy_flutter/alloy_flutter.dart';
import 'package:alloy_talker/alloy_talker.dart';
import 'package:flutter/material.dart';
import 'package:graph_events/app/app_scope.dart';
import 'package:graph_events/app/audit_log.dart';
import 'package:graph_events/features/home/ui/home_screen.dart';
import 'package:talker/talker.dart';

class GraphEventsApp extends StatelessWidget {
  const GraphEventsApp({required this.talker, required this.audit, super.key});

  final Talker talker;

  /// A destination Alloy ships no adapter for. See [_observers].
  final AuditLog audit;

  /// Three destinations, two mechanisms.
  ///
  /// `AlloyTalkerObserver` is a full observer, because talker has a notion of
  /// a log *kind* and can colour each event differently. The other two are
  /// sinks fanned out by [AlloyMultiSink], which keeps going when one of them
  /// throws — losing the console should not cost you the audit trail.
  ///
  /// `AlloyLogSink.from` is the whole integration for a logger with no
  /// adapter: one callback, no package, no class.
  List<AlloyObserver> get _observers => [
    AlloyTalkerObserver(talker, verbose: true),
    AlloyLogObserver(
      AlloyMultiSink([
        const AlloyPrintLogSink(),
        AlloyLogSink.from(
          (record) => audit.write('${record.level.name} ${record.message}'),
        ),
      ]),
    ),
  ];

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Alloy observability',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
    ),
    builder: AlloyAppScope.builder(
      root: const AppScope(),
      bootstrap: () => [WarmUp()],
      rootName: 'app',
      observers: _observers,
      loading: const Scaffold(body: Center(child: CircularProgressIndicator())),
    ),
    home: HomeScreen(talker: talker),
  );
}
