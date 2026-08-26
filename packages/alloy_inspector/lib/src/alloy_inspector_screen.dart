import 'package:alloy_flutter/alloy_flutter.dart';
import 'package:alloy_inspector/src/alloy_inspector_log.dart';
import 'package:alloy_inspector/src/created_view.dart';
import 'package:alloy_inspector/src/event_log_view.dart';
import 'package:alloy_inspector/src/scope_tree_view.dart';
import 'package:flutter/material.dart';

/// The inspector: the live tree, what was built, and everything reported.
///
/// Push it from a debug menu, reading the scope at the push site:
///
/// ```dart
/// Navigator.of(context).push(
///   MaterialPageRoute<void>(
///     builder: (_) =>
///         AlloyInspectorScreen(log: log, scope: context.alloyScope),
///   ),
/// );
/// ```
///
/// [scope] is passed rather than read from this screen's own context on
/// purpose. A pushed route is built by the navigator, which sits *above* the
/// `AlloyScopeProvider` in the tree — so looking the scope up from in here
/// finds nothing, however deep the button that opened it was. Any scope will
/// do; the screen climbs to its root.
///
/// [log] has to be the one passed to the graph when it was built. Observers
/// are fixed at construction, so an inspector cannot start listening to a
/// scope that is already running.
class AlloyInspectorScreen extends StatelessWidget {
  /// Shows the graph [scope] belongs to, as recorded by [log].
  const AlloyInspectorScreen({
    required this.log,
    required this.scope,
    super.key,
  });

  /// The recorder installed when the graph was built.
  final AlloyInspectorLog log;

  /// Any scope in the graph to show. The root is found from it.
  final AlloyScope scope;

  @override
  Widget build(BuildContext context) {
    final root = scope.root;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Alloy · inspector'),
          actions: [
            IconButton(
              key: const Key('clear-log'),
              tooltip: 'forget what has been recorded',
              icon: const Icon(Icons.delete_outline),
              onPressed: log.clear,
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(key: Key('tab-tree'), text: 'Tree'),
              Tab(key: Key('tab-created'), text: 'Built'),
              Tab(key: Key('tab-log'), text: 'Log'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _Reactive(
              log: log,
              child: ScopeTreeView(root: root),
            ),
            CreatedView(log: log),
            EventLogView(log: log),
          ],
        ),
      ),
    );
  }
}

/// Rebuilds [child] whenever the graph reports anything.
///
/// A scope is not a [Listenable] and pushing one notifies nothing, so a view
/// over the live tree would otherwise keep showing the tree as it was when the
/// screen opened. The event stream is the only signal there is that something
/// moved; it does not say *what* moved, which is enough to re-walk the tree.
class _Reactive extends StatelessWidget {
  const _Reactive({required this.log, required this.child});

  final AlloyInspectorLog log;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      ListenableBuilder(listenable: log, builder: (context, _) => child);
}
