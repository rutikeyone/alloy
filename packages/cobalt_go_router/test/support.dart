import 'package:cobalt_go_router/cobalt_go_router.dart';
import 'package:cobalt_test/cobalt_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

// Re-exported so every test file here keeps reaching `settle` through this
// one import, which is what they all did when it was defined below.
export 'package:cobalt_test_flutter/cobalt_test_flutter.dart';

/// Where the fixtures below report their teardown, replaced by every `setUp`.
///
/// This was a plain list cleared at the start of each test, which does not
/// isolate anything: teardown is not awaited, so the previous test's scope can
/// still be releasing and append after the clear. A [Tracked] captures whichever
/// recorder was current when it was *built*, so a late report lands in the test
/// it belongs to instead of the one now running.
late DisposeRecorder recorder;

/// A flow-scoped value that reports its own teardown.
class Tracked implements Disposable {
  Tracked(this.label) : _recorder = recorder;

  final String label;
  final DisposeRecorder _recorder;

  @override
  void dispose() => _recorder.record(label);
}

class TrackedScope implements CobaltScopeBuilder {
  const TrackedScope(this.label);

  final String label;

  @override
  void build(CobaltScope scope) =>
      scope.registerLazySingleton<Tracked>(FnFactory((_) => Tracked(label)));
}

/// Renders the resolved [Tracked] so a test can compare instances across
/// navigations, plus the scope it came from.
class Probe extends StatelessWidget {
  const Probe({super.key});

  @override
  Widget build(BuildContext context) {
    final tracked = context.cobalt<Tracked>();
    return Scaffold(
      body: Column(
        children: [
          Text('scope:${context.cobaltScope.name}'),
          Text('label:${tracked.label}'),
          Text('instance:${identityHashCode(tracked)}'),
        ],
      ),
    );
  }
}

/// Mounts [router] under [scope]. The root scope is built in `setUp`, never
/// here — `testWidgets` runs in a fake-async zone where an initializer that
/// awaits a real delay never completes.
Widget app(CobaltScope scope, GoRouter router) => CobaltScopeProvider(
  scope: scope,
  child: MaterialApp.router(routerConfig: router),
);

String textStartingWith(String prefix) {
  final finder = find.textContaining(prefix);
  return (finder.evaluate().single.widget as Text).data!;
}

/// Names every scope from the one nearest this widget up to the root.
class ScopeChain extends StatelessWidget {
  const ScopeChain({super.key});

  @override
  Widget build(BuildContext context) {
    final names = <String>[];
    for (
      CobaltScope? scope = context.cobaltScope;
      scope != null;
      scope = scope.parent
    ) {
      names.add(scope.name);
    }
    return Scaffold(body: Text('chain:${names.join('<')}'));
  }
}
