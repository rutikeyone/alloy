import 'dart:convert';

import 'package:cobalt_flutter/cobalt_flutter.dart';
import 'package:cobalt_inspector/src/cobalt_inspector_log.dart';
import 'package:cobalt_inspector/src/theme/cobalt_inspector_family.dart';
import 'package:cobalt_inspector/src/l10n/cobalt_inspector_l10n.dart';
import 'package:cobalt_inspector/src/l10n/inspector_strings.dart';
import 'package:cobalt_inspector/src/theme/cobalt_inspector_theme.dart';
import 'package:cobalt_inspector/src/widgets/chrome.dart';
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
  final CobaltLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = CobaltInspectorTheme.of(context);
    final strings = inspectorStringsOf(context);
    final record = entry.record;
    final family = CobaltInspectorFamily.of(record.kind);
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
                  tooltip: strings.copyRecord,
                  icon: Icon(Icons.copy_all_outlined, color: theme.muted),
                  onPressed: () => _copy(context, record, strings),
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
                    _Field(
                      label: strings.fieldLevel,
                      value: record.level.name,
                      tint: theme.colorOfLevel(record.level),
                    ),
                    if (record.scope != null)
                      _Field(
                        label: strings.fieldScope,
                        value: '${record.scope}',
                      ),
                    if (record.key != null)
                      _Field(label: strings.fieldKey, value: '${record.key}'),
                    if (record.registrationKind != null)
                      _Field(
                        label: strings.fieldLifetime,
                        value: record.registrationKind!.name,
                      ),
                    if (record.retained != null)
                      _Field(
                        label: strings.fieldRetained,
                        value: '${record.retained}',
                      ),
                    if (record.error != null)
                      _Field(
                        label: strings.fieldError,
                        value: '${record.error}',
                        tint: theme.failure,
                      ),
                    if (record.stackTrace != null)
                      _Field(
                        key: const Key('record-stack'),
                        label: strings.fieldStack,
                        value: '${record.stackTrace}',
                      ),
                    _Field(
                      key: const Key('record-structured'),
                      label: strings.fieldStructured,
                      value: const JsonEncoder.withIndent(
                        '  ',
                      ).convert(_stringify(record.toStructured())),
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

  Future<void> _copy(
    BuildContext context,
    CobaltLogRecord record,
    CobaltInspectorL10n strings,
  ) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    await Clipboard.setData(
      ClipboardData(
        text: const JsonEncoder.withIndent(
          '  ',
        ).convert(_stringify(record.toStructured())),
      ),
    );
    messenger?.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(strings.recordCopied),
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
    final theme = CobaltInspectorTheme.of(context);
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
