import 'package:alloy/alloy.dart';
import 'package:notes_app/core/event_log.dart';
import 'package:notes_app/features/notes/domain/note.dart';
import 'package:notes_app/features/notes/domain/note_store.dart';

part 'notes_controller.g.dart';

@alloyTransient
class NotesController with _$NotesController {
  NotesController();

  @injected
  late final NoteStore _store;

  @injected
  late final EventLog _log;

  List<Note> get notes => _store.visible();

  Note add(String title) {
    final note = _store.create(title);
    _log.record('created ${note.id}');
    return note;
  }

  List<Note> search(String query) => _store.search(query);
}
