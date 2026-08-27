import 'dart:convert';

import 'package:alloy_flutter/alloy_flutter.dart';
import 'package:alloy_inspector/src/alloy_inspector_log.dart';
import 'package:alloy_inspector/src/theme/alloy_inspector_family.dart';
import 'package:alloy_inspector/src/theme/alloy_inspector_theme.dart';
import 'package:alloy_inspector/src/widgets/chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Everything one record carries, including what the line could not fit.
///
/// A log line is a summary. The failure, its stack and the structured map are
/// the parts you need once a line has caught your eye, and they are the parts
/// worth copying somewhere else — so the sheet offers that rather than leaving
/// you to retype a stack trace.
class RecordDetailSheet extends StatelessWidget {
  /// Shows [entry].
  const RecordDetailSheet({required this.entry, super.key});

  /// The record and when it arrived.
  final AlloyLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = AlloyInspectorTheme.of(context);
    final record = entry.record;
    final family = AlloyInspectorFamily.of(record.kind);
    final mono = (theme.monospace ?? const TextStyle(fontSize: 12)).copyWith(
      color: theme.onSurface,
      fontSize: 12,
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                FamilyMark(family: family, theme: theme),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    record.kind.name,
                    style: TextStyle(
                      color: theme.colorOfFamily(family),
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
                IconButton(
                  key: const Key('copy-record'),
                  tooltip: 'copy this record',
                  icon: Icon(Icons.copy_all_outlined, color: theme.muted),
                  onPressed: () => _copy(context, record),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SelectableText(record.message, style: mono),
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Field(label: 'level', value: record.level.name),
                    if (record.scope != null)
                      _Field(label: 'scope', value: '${record.scope}'),
                    if (record.key != null)
                      _Field(label: 'key', value: '${record.key}'),
                    if (record.registrationKind != null)
                      _Field(
                        label: 'lifetime',
                        value: record.registrationKind!.name,
                      ),
                    if (record.retained != null)
                      _Field(label: 'retained', value: '${record.retained}'),
                    if (record.error != null)
                      _Field(
                        label: 'error',
                        value: '${record.error}',
                        tint: theme.failure,
                      ),
                    if (record.stackTrace != null)
                      _Field(
                        key: const Key('record-stack'),
                        label: 'stack',
                        value: '${record.stackTrace}',
                      ),
                    _Field(
                      key: const Key('record-structured'),
                      label: 'structured',
                      value: const JsonEncoder.withIndent('  ')
                          .convert(_stringify(record.toStructured())),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copy(BuildContext context, AlloyLogRecord record) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    await Clipboard.setData(
      ClipboardData(
        text: const JsonEncoder.withIndent('  ')
            .convert(_stringify(record.toStructured())),
      ),
    );
    messenger?.showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('Record copied'),
      ),
    );
  }

  /// `toStructured` keeps the error as an object, which JSON cannot encode.
  static Map<String, Object?> _stringify(Map<String, Object?> structured) => {
    for (final entry in structured.entries)
      entry.key: switch (entry.value) {
        null => null,
        final String value => value,
        final num value => value,
        final bool value => value,
        final Object value => '$value',
      },
  };
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.value,
    this.tint,
    super.key,
  });

  final String label;
  final String value;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final theme = AlloyInspectorTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: theme.muted,
              fontSize: 10,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 2),
          SelectableText(
            value,
            style: (theme.monospace ?? const TextStyle(fontSize: 12)).copyWith(
              color: tint ?? theme.onSurface,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
