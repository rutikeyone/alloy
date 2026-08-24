import 'package:alloy_flutter/alloy_flutter.dart';
import 'package:flutter/material.dart';
import 'package:notes_app/bootstrap/boot_log.dart';
import 'package:notes_app/core/app_config.dart';
import 'package:notes_app/features/diagnostics/data/telemetry.dart';
import 'package:notes_app/features/notes/data/note_database.dart';
import 'package:notes_app/features/notes/data/search_index.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final config = context.alloy<AppConfig>();
    final database = context.alloy<NoteDatabase>();
    final index = context.alloy<SearchIndex>();
    final telemetry = context.alloy<Telemetry>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Two-phase startup'),
        actions: [
          IconButton(
            key: const Key('restart-graph'),
            tooltip: 'dispose the app scope and start a new one',
            icon: const Icon(Icons.restart_alt),
            onPressed: () => AlloyAppScope.of(context).restart(),
          ),
        ],
      ),
      body: ListView(
        children: [
          _SectionTitle(
            'Phase 0 — @AlloyBootstrap',
            note:
                'adopted by scope "${context.alloyScope.name}", '
                'released when it is disposed',
          ),
          for (final step in BootLog.steps)
            ListTile(dense: true, title: Text(step, key: Key('boot-$step'))),
          const _SectionTitle('Phase 1 — @AlloyInit'),
          _StatusTile('database open', database.isOpen),
          _StatusTile('search index built', index.isBuilt),
          _StatusTile('telemetry started', telemetry.isStarted),
          ListTile(dense: true, title: Text('api: ${config.apiBaseUrl}')),
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
    title: Text('$label: $isReady'),
  );
}
