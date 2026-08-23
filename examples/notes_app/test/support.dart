import 'package:alloy/alloy.dart';
import 'package:notes_app/alloy.g.dart';
import 'package:notes_app/app/app_startup.dart';

/// Builds the graph without mounting the app.
///
/// The same three pieces `AlloyAppScope` is given in `NotesApp.build`; the app
/// itself needs no such function, which is why this one lives in `test/`.
Future<AlloyScope> startNotesGraph({
  AlloyEnvironment environment = notesEnvironment,
}) => AlloyApplication.start(
  root: NotesScope(environment),
  bootstrap: $alloyBootstrap(environment),
  rootName: $alloyRootScopeName,
);
