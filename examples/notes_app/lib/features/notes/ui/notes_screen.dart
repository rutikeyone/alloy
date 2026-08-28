import 'package:alloy_flutter/alloy_flutter.dart';
import 'package:flutter/material.dart';
import 'package:notes_app/features/notes/ui/notes_controller.dart';
import 'package:notes_app/l10n/notes_app_l10n.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  late final NotesController _controller = context.alloy<NotesController>();
  var _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = NotesL10n.of(context);
    final notes = _query.isEmpty
        ? _controller.notes
        : _controller.search(_query);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.propertyInjection)),
      floatingActionButton: FloatingActionButton(
        key: const Key('add-note'),
        onPressed: () => setState(
          () => _controller.add(l10n.newNote(_controller.notes.length + 1)),
        ),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              key: const Key('search'),
              decoration: InputDecoration(labelText: l10n.search),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Text(l10n.noteCount(notes.length), key: const Key('note-count')),
          Expanded(
            child: ListView(
              children: [
                for (final note in notes)
                  ListTile(title: Text(note.title), subtitle: Text(note.id)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
