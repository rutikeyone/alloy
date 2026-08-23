import 'package:alloy_go_router/alloy_go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Everything disposed so far, in order, shared by the fixtures below.
final disposeLog = <String>[];

/// A flow-scoped value that reports its own teardown.
class Tracked implements Disposable {
  Tracked(this.label);

  final String label;

  @override
  void dispose() => disposeLog.add(label);
}

final class TrackedFactory implements AlloyFactory<Tracked> {
  const TrackedFactory(this.label);

  final String label;

  @override
  Tracked create(AlloyResolver resolver) => Tracked(label);
}

class TrackedScope implements AlloyScopeBuilder {
  const TrackedScope(this.label);

  final String label;

  @override
  void build(AlloyScope scope) =>
      scope.registerLazySingleton<Tracked>(TrackedFactory(label));
}

/// Renders the resolved [Tracked] so a test can compare instances across
/// navigations, plus the scope it came from.
class Probe extends StatelessWidget {
  const Probe({super.key});

  @override
  Widget build(BuildContext context) {
    final tracked = context.alloy<Tracked>();
    return Scaffold(
      body: Column(
        children: [
          Text('scope:${context.alloyScope.name}'),
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
Widget app(AlloyScope scope, GoRouter router) => AlloyScopeProvider(
  scope: scope,
  child: MaterialApp.router(routerConfig: router),
);

/// Pumps without `pumpAndSettle`, which hangs on an indefinite animation.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

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
      AlloyScope? scope = context.alloyScope;
      scope != null;
      scope = scope.parent
    ) {
      names.add(scope.name);
    }
    return Scaffold(body: Text('chain:${names.join('<')}'));
  }
}
