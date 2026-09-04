import 'package:cobalt/cobalt.dart';
import 'package:notes_app/core/event_log.dart';
import 'package:notes_app/features/notes/domain/note.dart';

@CobaltInit()
class NoteDatabase implements AsyncInitializable, AsyncDisposable {
  NoteDatabase(this._log);

  final EventLog _log;
  final _rows = <String, Note>{};

  var isOpen = false;

  @override
  Future<void> init() async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    isOpen = true;
    _log.record('database opened');
  }

  Iterable<Note> all() => _rows.values;

  Note? find(String id) => _rows[id];

  void save(Note note) => _rows[note.id] = note;

  @override
  Future<void> dispose() async {
    isOpen = false;
    _log.record('database closed');
  }
}
