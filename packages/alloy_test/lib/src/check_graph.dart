import 'package:alloy/alloy.dart';
import 'package:alloy_test/src/alloy_graph_report.dart';

/// Resolves everything [scope] can see, and reports what happened.
///
/// This is the only way to check a hand-written graph. The generator rejects an
/// incomplete graph at build time, but it only sees what it generated: a
/// factory never declares what it will ask for, so a graph assembled by hand
/// can only be checked by running it.
///
/// [params] supplies a value for parameterized registrations, keyed the same
/// way they were registered. Anything without one is reported as unchecked
/// rather than passed over.
///
/// **This is terminal for the scope.** Resolving is the check, so there is no
/// dry run — and afterwards every lazy singleton in the graph is built and
/// owned, which changes the order teardown releases things in. Give it a scope
/// nothing else will assert on, or make it the last thing the test does.
///
/// Transients are built and, since the scope does not retain them, disposed
/// here. Async singletons need their owner initialised, so each owning scope is
/// initialised first; `init()` is idempotent, so this is free when it already
/// ran.
Future<AlloyGraphReport> checkGraph(
  AlloyScope scope, {
  Map<AlloyKey, Object> params = const {},
}) async {
  final visible = scope.visibleKeys;

  for (final owner in {...visible.values}) {
    await owner.init();
  }

  final entries = <AlloyGraphEntry>[];
  final loose = <Object>[];

  for (final entry in visible.entries) {
    final key = entry.key;
    final kind = scope.debugKindOf(key);

    if (kind == AlloyRegistrationKind.parameterized) {
      final param = params[key];
      if (param == null) {
        entries.add(
          AlloyGraphEntry(
            key,
            AlloyGraphOutcome.unchecked,
            reason: 'parameterized; pass a value for it in params',
          ),
        );
        continue;
      }
      entries.add(_resolveParam(scope, key, param, loose));
      continue;
    }

    try {
      final instance = scope.debugResolve(key);
      if (kind == AlloyRegistrationKind.transient && instance != null) {
        loose.add(instance);
      }
      entries.add(AlloyGraphEntry(key, AlloyGraphOutcome.resolved));
    } on Object catch (error) {
      entries.add(AlloyGraphEntry(key, AlloyGraphOutcome.failed, error: error));
    }
  }

  await _release(loose);
  return AlloyGraphReport(entries);
}

/// Fails the test unless every registration [scope] can see resolves.
///
/// Reports all of them at once — a graph with three holes should take one run
/// to find, not three.
Future<void> expectGraphResolves(
  AlloyScope scope, {
  Map<AlloyKey, Object> params = const {},
}) async {
  final report = await checkGraph(scope, params: params);
  if (report.isComplete) return;
  throw StateError('The graph did not resolve completely.\n$report');
}

AlloyGraphEntry _resolveParam(
  AlloyScope scope,
  AlloyKey key,
  Object param,
  List<Object> loose,
) {
  try {
    final instance = scope.debugResolveWithParam(key, param);
    if (instance != null) loose.add(instance);
    return AlloyGraphEntry(key, AlloyGraphOutcome.resolved);
  } on Object catch (error) {
    return AlloyGraphEntry(key, AlloyGraphOutcome.failed, error: error);
  }
}

Future<void> _release(List<Object> instances) async {
  for (final instance in instances.reversed) {
    switch (instance) {
      case AsyncDisposable():
        await instance.dispose();
      case Disposable():
        instance.dispose();
    }
  }
}
