import 'package:alloy_inspector/src/alloy_inspector_log.dart';
import 'package:alloy_inspector/src/l10n/alloy_inspector_l10n.dart';
import 'package:alloy_inspector/src/l10n/inspector_strings.dart';
import 'package:alloy_inspector/src/record_detail_sheet.dart';
import 'package:alloy_inspector/src/theme/alloy_inspector_family.dart';
import 'package:alloy_inspector/src/theme/alloy_inspector_theme.dart';
import 'package:alloy_inspector/src/theme/alloy_inspector_theme_data.dart';
import 'package:alloy_inspector/src/widgets/chrome.dart';
import 'package:flutter/material.dart';

/// Everything the graph reported, newest first.
///
/// Filtered by family and by text, and pausable — the graph does not stop
/// because a screen is open, and a list that reorders under a finger cannot be
/// read. Pausing withholds the repaint, never the record.
class EventLogView extends StatefulWidget {
  /// Reads from [log].
  const EventLogView({required this.log, super.key});

  /// Where the records come from.
  final AlloyInspectorLog log;

  @override
  State<EventLogView> createState() => _EventLogViewState();
}

class _EventLogViewState extends State<EventLogView> {
  AlloyInspectorFamily? _family;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final theme = AlloyInspectorTheme.of(context);
    final strings = inspectorStringsOf(context);

    return ListenableBuilder(
      listenable: widget.log,
      builder: (context, _) {
        final entries = _matching(
          widget.log.entries,
        ).toList().reversed.toList();

        return Container(
          color: theme.background,
          child: Column(
            children: [
              SearchField(
                key: const Key('log-search'),
                hint: strings.logSearchHint,
                theme: theme,
                onChanged: (value) =>
                    setState(() => _query = value.trim().toLowerCase()),
              ),
              _FamilyFilter(
                selected: _family,
                theme: theme,
                strings: strings,
                counts: _counts(widget.log.entries),
                onChanged: (family) => setState(() => _family = family),
              ),
              Divider(height: 1, color: theme.outline),
              Expanded(
                child: entries.isEmpty
                    ? EmptyNote(
                        key: const Key('no-events'),
                        text: widget.log.entries.isEmpty
                            ? strings.logEmpty
                            : strings.logNoMatch,
                        theme: theme,
                      )
                    : ListView.separated(
                        key: const Key('event-log'),
                        itemCount: entries.length,
                        separatorBuilder: (_, _) =>
                            Divider(height: 1, color: theme.outline),
                        itemBuilder: (context, index) => _RecordTile(
                          entry: entries[index],
                          // Newest first, so the one below is the earlier one.
                          previous: index + 1 < entries.length
                              ? entries[index + 1]
                              : null,
                          theme: theme,
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Iterable<AlloyLogEntry> _matching(List<AlloyLogEntry> entries) sync* {
    for (final entry in entries) {
      final record = entry.record;
      if (_family != null && AlloyInspectorFamily.of(record.kind) != _family) {
        continue;
      }
      if (_query.isEmpty) {
        yield entry;
        continue;
      }
      final haystack =
          '${record.message} ${record.kind.name} ${record.scope?.name ?? ''} '
                  '${record.key ?? ''}'
              .toLowerCase();
      if (haystack.contains(_query)) yield entry;
    }
  }

  static Map<AlloyInspectorFamily, int> _counts(List<AlloyLogEntry> entries) {
    final counts = {for (final f in AlloyInspectorFamily.values) f: 0};
    for (final entry in entries) {
      final family = AlloyInspectorFamily.of(entry.record.kind);
      counts[family] = counts[family]! + 1;
    }
    return counts;
  }
}

class _FamilyFilter extends StatelessWidget {
  const _FamilyFilter({
    required this.selected,
    required this.theme,
    required this.strings,
    required this.counts,
    required this.onChanged,
  });

  final AlloyInspectorFamily? selected;
  final AlloyInspectorThemeData theme;
  final AlloyInspectorL10n strings;
  final Map<AlloyInspectorFamily, int> counts;
  final ValueChanged<AlloyInspectorFamily?> onChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 44,
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      children: [
        _Chip(
          name: 'all',
          label: strings.filterAll,
          count: counts.values.fold(0, (sum, n) => sum + n),
          color: theme.accent,
          theme: theme,
          isSelected: selected == null,
          onTap: () => onChanged(null),
        ),
        for (final family in AlloyInspectorFamily.values)
          _Chip(
            name: family.name,
            label: family.label(strings),
            count: counts[family] ?? 0,
            color: theme.colorOfFamily(family),
            theme: theme,
            isSelected: selected == family,
            onTap: () => onChanged(family),
          ),
      ],
    ),
  );
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.name,
    required this.label,
    required this.count,
    required this.color,
    required this.theme,
    required this.isSelected,
    required this.onTap,
  });

  final String name;
  final String label;
  final int count;
  final Color color;
  final AlloyInspectorThemeData theme;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: GestureDetector(
      key: Key('filter-$name'),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: isSelected ? 0.22 : 0.06),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: isSelected ? color : theme.outline,
            width: isSelected ? 1.4 : 1,
          ),
        ),
        child: Text(
          count == 0 ? label : '$label · $count',
          style: TextStyle(
            color: isSelected ? color : theme.muted,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    ),
  );
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({
    required this.entry,
    required this.previous,
    required this.theme,
  });

  final AlloyLogEntry entry;
  final AlloyLogEntry? previous;
  final AlloyInspectorThemeData theme;

  @override
  Widget build(BuildContext context) {
    final record = entry.record;
    final family = AlloyInspectorFamily.of(record.kind);

    return InkWell(
      key: Key('record-${record.kind.name}-${entry.at.microsecondsSinceEpoch}'),
      onTap: () => showModalBottomSheet<void>(
        context: context,
        backgroundColor: theme.background,
        isScrollControlled: true,
        builder: (_) => AlloyInspectorTheme(
          data: theme,
          child: RecordDetailSheet(entry: entry),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FamilyMark(family: family, theme: theme, size: 15),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.message,
                    style: TextStyle(color: theme.onSurface, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        record.kind.name,
                        style: TextStyle(
                          color: theme.colorOfFamily(family),
                          fontSize: 11,
                        ),
                      ),
                      if (record.registrationKind != null) ...[
                        const SizedBox(width: 6),
                        LifetimeBadge(
                          kind: record.registrationKind,
                          theme: theme,
                        ),
                      ],
                      if (record.error != null) ...[
                        const SizedBox(width: 6),
                        Icon(
                          Icons.error_outline,
                          size: 13,
                          color: theme.failure,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Timestamp(at: entry.at, since: previous?.at, theme: theme),
          ],
        ),
      ),
    );
  }
}
