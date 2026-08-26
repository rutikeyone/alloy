import 'package:alloy_flutter/alloy_flutter.dart';
import 'package:alloy_inspector/src/alloy_inspector_log.dart';
import 'package:flutter/material.dart';

/// What the graph actually built, newest first, grouped by lifetime.
///
/// This is the one view that has to come from events. A scope's registrations
/// say what was *declared* — a lazy singleton nobody resolved is listed there
/// exactly like one that is built — so only a creation event proves an object
/// exists.
///
/// One thing it will never show: an eager singleton. That instance is built by
/// whoever called `registerSingleton` and handed over already made, so the
/// scope has nothing to report constructing. It appears in the tree, with its
/// lifetime, and never here.
class CreatedView extends StatelessWidget {
  /// Reads from [log].
  const CreatedView({required this.log, super.key});

  /// Where the creation events come from.
  final AlloyInspectorLog log;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: log,
    builder: (context, _) {
      final created = log.created.reversed.toList();
      if (created.isEmpty) {
        return const Center(
          key: Key('nothing-built'),
          child: Text('Nothing built yet'),
        );
      }

      return ListView.builder(
        key: const Key('created-list'),
        itemCount: created.length,
        itemBuilder: (context, index) => _CreatedTile(record: created[index]),
      );
    },
  );
}

class _CreatedTile extends StatelessWidget {
  const _CreatedTile({required this.record});

  final AlloyLogRecord record;

  @override
  Widget build(BuildContext context) => ListTile(
    key: Key('created-${record.key}'),
    dense: true,
    title: Text('${record.key}'),
    subtitle: Text(
      '${record.registrationKind?.name ?? 'unknown'} · '
      'in "${record.scope?.name ?? '?'}" · '
      '${record.retained ?? false ? 'torn down with the scope' : 'caller owns it'}',
    ),
  );
}
