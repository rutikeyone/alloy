import 'package:alloy/alloy.dart';
import 'package:notes_app/core/event_log.dart';
import 'package:notes_app/features/notes/data/note_database.dart';

@AlloyInit(dependsOn: [NoteDatabase])
class SearchIndex implements AsyncInitializable {
  SearchIndex(this._database, this._log);

  final NoteDatabase _database;
  final EventLog _log;

  var isBuilt = false;

  @override
  Future<void> init() async {
    if (!_database.isOpen) {
      throw StateError('SearchIndex ran before NoteDatabase was open');
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
    isBuilt = true;
    _log.record('search index built');
  }

  Iterable<String> search(String query) => _database
      .all()
      .where((note) => note.title.toLowerCase().contains(query.toLowerCase()))
      .map((note) => note.id);
}
