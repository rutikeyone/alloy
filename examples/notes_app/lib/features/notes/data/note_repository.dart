import 'package:alloy/alloy.dart';
import 'package:notes_app/core/clock.dart';
import 'package:notes_app/features/notes/data/note_database.dart';
import 'package:notes_app/features/notes/data/search_index.dart';
import 'package:notes_app/features/notes/domain/note.dart';
import 'package:notes_app/features/notes/domain/note_store.dart';

@AlloyInject(exposeAs: NoteStore)
class NoteRepository implements NoteStore {
  NoteRepository(this._database, this._index, this._clock);

  final NoteDatabase _database;
  final SearchIndex _index;
  final Clock _clock;

  var _sequence = 0;

  @override
  List<Note> visible() => _database.all().toList(growable: false);

  @override
  Note create(String title) {
    final note = Note(
      id: 'note-${++_sequence}',
      title: title,
      createdAt: _clock.now(),
    );
    _database.save(note);
    return note;
  }

  @override
  List<Note> search(String query) => [
    for (final id in _index.search(query)) ?_database.find(id),
  ];
}
