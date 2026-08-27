import 'package:alloy_flutter/alloy_flutter.dart';
import 'package:alloy_inspector/src/alloy_inspector_log.dart';
import 'package:alloy_inspector/src/theme/alloy_inspector_theme.dart';
import 'package:alloy_inspector/src/theme/alloy_inspector_theme_data.dart';
import 'package:alloy_inspector/src/widgets/chrome.dart';
import 'package:flutter/material.dart';

/// How the built instances are arranged.
enum CreatedGrouping {
  /// Newest first, one flat list.
  flat,

  /// Gathered under the scope that built them.
  byScope,

  /// Gathered by how long they live.
  byLifetime;

  /// What the switch shows for this option.
  String get label => switch (this) {
    CreatedGrouping.flat => 'flat',
    CreatedGrouping.byScope => 'by scope',
    CreatedGrouping.byLifetime => 'by lifetime',
  };
}

/// What the graph actually built, newest first.
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
class CreatedView extends StatefulWidget {
  /// Reads from [log].
  const CreatedView({required this.log, super.key});

  /// Where the creation events come from.
  final AlloyInspectorLog log;

  @override
  State<CreatedView> createState() => _CreatedViewState();
}

class _CreatedViewState extends State<CreatedView> {
  CreatedGrouping _grouping = CreatedGrouping.byScope;

  @override
  Widget build(BuildContext context) {
    final theme = AlloyInspectorTheme.of(context);

    return ListenableBuilder(
      listenable: widget.log,
      builder: (context, _) {
        final created = [
          for (final entry in widget.log.entries)
            if (entry.record.kind == AlloyEventKind.instanceCreated) entry,
        ].reversed.toList();

        return Container(
          color: theme.background,
          child: Column(
            children: [
              _GroupingSwitch(
                selected: _grouping,
                theme: theme,
                onChanged: (grouping) => setState(() => _grouping = grouping),
              ),
              Divider(height: 1, color: theme.outline),
              Expanded(
                child: created.isEmpty
                    ? EmptyNote(
                        key: const Key('nothing-built'),
                        text: 'Nothing built yet',
                        theme: theme,
                      )
                    : ListView(
                        key: const Key('created-list'),
                        children: _rows(created, theme),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _rows(List<AlloyLogEntry> created, AlloyInspectorThemeData t) {
    if (_grouping == CreatedGrouping.flat) {
      return [
        for (final entry in created) _CreatedTile(entry: entry, theme: t),
      ];
    }

    final groups = <String, List<AlloyLogEntry>>{};
    for (final entry in created) {
      final key = _grouping == CreatedGrouping.byScope
          ? entry.record.scope?.name ?? '?'
          : entry.record.registrationKind?.name ?? 'unknown';
      groups.putIfAbsent(key, () => []).add(entry);
    }

    return [
      for (final group in groups.entries) ...[
        _GroupHeader(label: group.key, count: group.value.length, theme: t),
        for (final entry in group.value) _CreatedTile(entry: entry, theme: t),
      ],
    ];
  }
}

class _GroupingSwitch extends StatelessWidget {
  const _GroupingSwitch({
    required this.selected,
    required this.theme,
    required this.onChanged,
  });

  final CreatedGrouping selected;
  final AlloyInspectorThemeData theme;
  final ValueChanged<CreatedGrouping> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
    child: Row(
      children: [
        for (final grouping in CreatedGrouping.values)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              key: Key('group-${grouping.name}'),
              onTap: () => onChanged(grouping),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: theme.accent.withValues(
                    alpha: selected == grouping ? 0.2 : 0.06,
                  ),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: selected == grouping ? theme.accent : theme.outline,
                  ),
                ),
                child: Text(
                  grouping.label,
                  style: TextStyle(
                    color: selected == grouping ? theme.accent : theme.muted,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({
    required this.label,
    required this.count,
    required this.theme,
  });

  final String label;
  final int count;
  final AlloyInspectorThemeData theme;

  @override
  Widget build(BuildContext context) => Container(
    key: Key('group-header-$label'),
    width: double.infinity,
    color: theme.surface,
    padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
    child: Text(
      '$label · $count',
      style: TextStyle(color: theme.muted, fontSize: 11, letterSpacing: 0.4),
    ),
  );
}

class _CreatedTile extends StatelessWidget {
  const _CreatedTile({required this.entry, required this.theme});

  final AlloyLogEntry entry;
  final AlloyInspectorThemeData theme;

  @override
  Widget build(BuildContext context) {
    final record = entry.record;
    return Padding(
      key: Key('created-${record.key}'),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${record.key}',
                  style: (theme.monospace ?? const TextStyle(fontSize: 13))
                      .copyWith(color: theme.onSurface, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  'in "${record.scope?.name ?? '?'}" · '
                  '${record.retained ?? false ? 'torn down with the scope' : 'caller owns it'}',
                  style: TextStyle(color: theme.muted, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          LifetimeBadge(kind: record.registrationKind, theme: theme),
        ],
      ),
    );
  }
}
