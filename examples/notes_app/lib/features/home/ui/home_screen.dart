import 'package:alloy_flutter/alloy_flutter.dart';
import 'package:flutter/material.dart';
import 'package:notes_app/bootstrap/boot_log.dart';
import 'package:notes_app/core/app_config.dart';
import 'package:notes_app/features/diagnostics/data/telemetry.dart';
import 'package:notes_app/features/notes/data/note_database.dart';
import 'package:notes_app/features/notes/data/search_index.dart';
import 'package:notes_app/l10n/notes_app_l10n.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = NotesL10n.of(context);
    final config = context.alloy<AppConfig>();
    final database = context.alloy<NoteDatabase>();
    final index = context.alloy<SearchIndex>();
    final telemetry = context.alloy<Telemetry>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.twoPhaseStartup),
        actions: [
          IconButton(
            key: const Key('restart-graph'),
            tooltip: l10n.restartGraph,
            icon: const Icon(Icons.restart_alt),
            onPressed: () => AlloyAppScope.of(context).restart(),
          ),
        ],
      ),
      body: ListView(
        children: [
          _SectionTitle(
            l10n.phaseZero,
            note: l10n.phaseZeroNote(context.alloyScope.name),
          ),
          // The step names are identifiers — they are how you find the code
          // that ran — so they read the same in every language.
          for (final step in BootLog.steps)
            ListTile(dense: true, title: Text(step, key: Key('boot-$step'))),
          _SectionTitle(l10n.phaseOne),
          _StatusTile(l10n.databaseOpen, database.isOpen),
          _StatusTile(l10n.searchIndexBuilt, index.isBuilt),
          _StatusTile(l10n.telemetryStarted, telemetry.isStarted),
          ListTile(dense: true, title: Text(l10n.apiLine(config.apiBaseUrl))),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {this.note});

  final String text;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final note = this.note;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: theme.titleSmall),
          if (note != null) Text(note, style: theme.bodySmall),
        ],
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile(this.label, this.isReady);

  final String label;
  final bool isReady;

  @override
  Widget build(BuildContext context) => ListTile(
    dense: true,
    leading: Icon(isReady ? Icons.check_circle : Icons.error_outline),
    title: Text(NotesL10n.of(context).statusLine(label, '$isReady')),
  );
}
