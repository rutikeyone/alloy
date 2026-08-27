# alloy_annotations example

Annotations only — they carry no runtime. The generator in `alloy_generator`
reads them, and `alloy_lint` checks them in the IDE.

```dart
import 'package:alloy/alloy.dart';

part 'notes.g.dart';

@alloyInit
class Database implements AsyncInitializable {
  Database();

  @override
  Future<void> init() async { /* open the file */ }
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

@alloyInject
class NoteEditor {
  NoteEditor(this.store, {@alloyParam required this.id});

  final NoteStore store;
  final int id;
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

`SearchIndex` may state `dependsOn: [Database]` only because `Database` is `@AlloyInit` too.
`dependsOn` sequences phase 1, so it can wait for an async registration and nothing else; naming a
plain one fails the build.

`NoteEditor` takes an `@alloyParam`, so it is registered as a parameterized factory and the
generator writes `typedef $NoteEditorArgs = ({int id});` beside the container. Resolve it with
`getWithParam<NoteEditor, $NoteEditorArgs>((id: 7))` — the store still comes from the graph.
