import 'package:alloy_flutter/alloy_flutter.dart';
import 'package:alloy_inspector/src/alloy_inspector_log.dart';
import 'package:flutter/material.dart';

/// Everything the graph reported, newest first, filtered by kind.
class EventLogView extends StatefulWidget {
  /// Reads from [log].
  const EventLogView({required this.log, super.key});

  /// Where the records come from.
  final AlloyInspectorLog log;

  @override
  State<EventLogView> createState() => _EventLogViewState();
}

class _EventLogViewState extends State<EventLogView> {
  AlloyEventKind? _only;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.log,
    builder: (context, _) {
      final records =
          (_only == null ? widget.log.records : widget.log.ofKind(_only!))
              .reversed
              .toList();

      return Column(
        children: [
          _KindFilter(
            selected: _only,
            onChanged: (kind) => setState(() => _only = kind),
          ),
          const Divider(height: 1),
          Expanded(
            child: records.isEmpty
                ? const Center(
                    key: Key('no-events'),
                    child: Text('Nothing reported yet'),
                  )
                : ListView.builder(
                    key: const Key('event-log'),
                    itemCount: records.length,
                    itemBuilder: (context, index) =>
                        _RecordTile(record: records[index]),
                  ),
          ),
        ],
      );
    },
  );
}

class _KindFilter extends StatelessWidget {
  const _KindFilter({required this.selected, required this.onChanged});

  final AlloyEventKind? selected;
  final ValueChanged<AlloyEventKind?> onChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 56,
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      children: [
        _Chip(
          label: 'all',
          isSelected: selected == null,
          onTap: () => onChanged(null),
        ),
        for (final kind in AlloyEventKind.values)
          _Chip(
            label: kind.name,
            isSelected: selected == kind,
            onTap: () => onChanged(kind),
          ),
      ],
    ),
  );
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: FilterChip(
      key: Key('filter-$label'),
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
    ),
  );
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({required this.record});

  final AlloyLogRecord record;

  @override
  Widget build(BuildContext context) {
    final lifetime = record.registrationKind;

    return ListTile(
      dense: true,
      title: Text(record.message),
      subtitle: Text(
        lifetime == null
            ? '${record.kind.name} · ${record.level.name}'
            : '${record.kind.name} · ${lifetime.name} · '
                  '${record.retained ?? false ? 'kept' : 'loose'}',
      ),
      trailing: record.isFailure
          ? const Icon(Icons.error_outline, size: 18)
          : null,
    );
  }
}
