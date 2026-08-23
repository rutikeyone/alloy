import 'package:alloy_flutter/alloy_flutter.dart';
import 'package:flutter/material.dart';
import 'package:notes_app/features/notes/ui/notes_controller.dart';

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
    final notes = _query.isEmpty
        ? _controller.notes
        : _controller.search(_query);

    return Scaffold(
      appBar: AppBar(title: const Text('Property injection')),
      floatingActionButton: FloatingActionButton(
        key: const Key('add-note'),
        onPressed: () => setState(
          () => _controller.add('note ${_controller.notes.length + 1}'),
        ),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              key: const Key('search'),
              decoration: const InputDecoration(labelText: 'search'),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Text('count: ${notes.length}', key: const Key('note-count')),
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
