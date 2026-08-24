import 'package:alloy_flutter/alloy_flutter.dart';
import 'package:flutter/material.dart';
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

/// Mounts one screen with the notes graph beneath it.
///
/// There is no app widget any more — the gallery owns that, and every screen
/// here is reached directly. So a test mounts exactly the screen it is about.
Widget notesScreenUnderTest(
  Widget screen, {
  AlloyEnvironment environment = notesEnvironment,
}) => MaterialApp(
  home: AlloyAppScope(
    root: NotesScope(environment),
    bootstrap: () => $alloyBootstrap(environment),
    rootName: $alloyRootScopeName,
    loading: const Scaffold(body: Center(child: CircularProgressIndicator())),
    child: screen,
  ),
);
