import 'package:alloy_flutter/alloy_flutter.dart';
import 'package:alloy_talker/alloy_talker.dart';
import 'package:logging_example/core/telemetry.dart';
import 'package:talker/talker.dart';

/// What the app owns for as long as it runs.
class AppScope implements AlloyScopeBuilder {
  const AppScope();

  @override
  void build(AlloyScope scope) =>
      scope.registerAsyncSingleton<Telemetry>(const TelemetryFactory());
}

/// A bootstrap step, so phase 0 shows up in the log too.
class WarmUp implements AlloyBootstrapStep, Disposable {
  WarmUp();

  @override
  String get name => 'warm-up';

  @override
  Future<void> run() async =>
      Future<void>.delayed(const Duration(milliseconds: 20));

  @override
  void dispose() {}
}

/// Builds the graph with talker watching it.
Future<AlloyScope> startLoggingExample(Talker talker) => AlloyApplication.start(
  root: const AppScope(),
  bootstrap: [WarmUp()],
  rootName: 'app',
  observers: [AlloyTalkerObserver(talker, verbose: true)],
);
