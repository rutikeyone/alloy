import 'package:notes_app/features/notes/domain/note.dart';

abstract interface class NoteStore {
  List<Note> visible();

  Note create(String title);

  List<Note> search(String query);
}
