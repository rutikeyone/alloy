import 'package:alloy_flutter/alloy_flutter.dart';
import 'package:flutter/material.dart';
import 'package:notes_app/features/formatting/domain/note_formatter.dart';
import 'package:notes_app/l10n/notes_app_l10n.dart';

class FormattersScreen extends StatelessWidget {
  const FormattersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = NotesL10n.of(context);
    final all = context.alloyAll<NoteFormatter>();
    final markdown = context.alloy<NoteFormatter>(name: 'markdown');

    return Scaffold(
      appBar: AppBar(title: Text(l10n.namedAndMulti)),
      body: ListView(
        children: [
          ListTile(
            title: const Text('getAll<NoteFormatter>()'),
            subtitle: Text(l10n.registrationCount(all.length)),
            key: const Key('formatter-count'),
          ),
          const Divider(),
          for (final formatter in all)
            ListTile(
              key: Key('formatter-${formatter.label}'),
              title: Text(formatter.label),
              subtitle: Text(formatter.format(l10n.sampleNote)),
            ),
          const Divider(),
          ListTile(
            key: const Key('named-pick'),
            title: const Text("get<NoteFormatter>(name: 'markdown')"),
            subtitle: Text(markdown.format(l10n.sampleNote)),
          ),
        ],
      ),
    );
  }
}
