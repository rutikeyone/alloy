# alloy_annotations example

Annotations only — they carry no runtime. The generator in `alloy_generator`
reads them, and `alloy_lint` checks them in the IDE.

```dart
import 'package:alloy/alloy.dart';

part 'notes.g.dart';

@alloyInject
class Database {
  Database();
}

@AlloyInject(exposeAs: NoteStore)
class NoteRepository implements NoteStore {
  NoteRepository(this.database);
  final Database database;
}

@AlloyInit(dependsOn: [Database])
class SearchIndex implements AsyncInitializable {
  SearchIndex(this.database);
  final Database database;

  @override
  Future<void> init() async { /* build the index */ }
}

@alloyTransient
class NotesController with _$NotesController {
  NotesController();

  @injected
  late final NoteStore _store;
}
```

A full application using every annotation lives in
[`examples/notes_app`](https://github.com/rutikeyone/alloy/tree/main/examples/notes_app).
