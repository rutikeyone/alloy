import 'package:flutter/material.dart';
import 'package:gallery/catalog/example_host.dart';
import 'package:notes_app/alloy.g.dart';
import 'package:notes_app/app/app_startup.dart';

/// Mounts one `notes_app` screen with the notes graph beneath it.
///
/// Five of the gallery's entries come from that one package, and each gets its
/// own graph rather than sharing one: open two of them and the scope trees are
/// unrelated, which is exactly what the entries are there to show.
Widget notesGraph(Widget screen) => ExampleHost(
  root: const NotesScope(notesEnvironment),
  bootstrap: () => $alloyBootstrap(notesEnvironment),
  rootName: $alloyRootScopeName,
  seedColor: Colors.indigo,
  child: screen,
);
