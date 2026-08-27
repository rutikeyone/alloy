import 'package:alloy_flutter/alloy_flutter.dart';
import 'package:alloy_inspector/alloy_inspector.dart';
import 'package:alloy_test/alloy_test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

void main() {
  setUp(() => clocksBuilt = 0);

  test('records what the graph reports', () async {
    final log = AlloyInspectorLog();
    buildGraph(log).get<Clock>();

    await Future<void>.delayed(Duration.zero);

    expect(log.created, hasLength(1));
    expect(
      log.created.single.registrationKind,
      AlloyRegistrationKind.lazySingleton,
    );
  });

  /// Observer callbacks arrive synchronously, in the middle of the work they
  /// describe — including a teardown running while the tree builds, where a
  /// synchronous notification throws `setState() called during build`.
  test('notifies after the turn, never inside the callback', () {
    final log = AlloyInspectorLog();
    var notifications = 0;
    log.addListener(() => notifications++);

    buildGraph(log).get<Clock>();

    expect(
      notifications,
      0,
      reason: 'notifying here would be notifying mid-build',
    );
  });

  test('and does notify once the turn is over', () async {
    final log = AlloyInspectorLog();
    var notifications = 0;
    log.addListener(() => notifications++);

    buildGraph(log).get<Clock>();
    await Future<void>.delayed(Duration.zero);

    expect(notifications, greaterThan(0));
  });

  test('keeps only the last records', () async {
    final log = AlloyInspectorLog(capacity: 2);
    final scope = buildGraph(log);

    scope
      ..get<Api>()
      ..get<Api>()
      ..get<Api>();
    await Future<void>.delayed(Duration.zero);

    expect(log.records, hasLength(2));
  });

  /// Deferring the notification means one can come due after the log is gone:
  /// tearing a scope down emits events, and its owner disposes the log in the
  /// same turn.
  test('a notification that comes due after dispose is dropped', () async {
    final log = AlloyInspectorLog();
    final scope = buildGraph(log)..get<Clock>();

    await scope.dispose();
    log.dispose();
    await Future<void>.delayed(Duration.zero);
  });

  test('an eager singleton is never reported as built', () async {
    final log = AlloyInspectorLog();
    alloyTestRoot(
      name: 'app',
      observers: [log],
    ).registerSingleton<Clock>(const Clock());

    await Future<void>.delayed(Duration.zero);

    expect(
      log.created,
      isEmpty,
      reason: 'the caller built it; the scope only took it over',
    );
  });
}
