import 'package:flutter/material.dart';
import 'package:gallery/catalog/example_host.dart';
import 'package:notes_app/alloy.g.dart';
import 'package:notes_app/app/app_startup.dart';
import 'package:notes_app/bootstrap/boot_log.dart';

/// Mounts one `notes_app` screen with the notes graph beneath it.
///
/// Seven of the gallery's entries come from that one package, and each gets its
/// own graph rather than sharing one: open two of them and the scope trees are
/// unrelated, which is exactly what the entries are there to show.
Widget notesGraph(Widget screen) => _NotesExample(screen: screen);

class _NotesExample extends StatefulWidget {
  const _NotesExample({required this.screen});

  final Widget screen;

  @override
  State<_NotesExample> createState() => _NotesExampleState();
}

class _NotesExampleState extends State<_NotesExample> {
  @override
  void initState() {
    super.initState();
    // The boot log is a process-wide static, and it has to be: phase 0 runs
    // before the container exists, so nothing can be injected into a bootstrap
    // step — the generated `$alloyBootstrap` builds them with no arguments at
    // all. Standing alone that was invisible, because one process meant one
    // graph. Here a visit builds a graph and leaving disposes it, so without
    // this every visit would stack another cycle onto the last one's.
    //
    // Cleared per visit rather than per start, deliberately: a restart should
    // still show "bind-platform released" followed by the next cycle, which is
    // the point of the restart button on this screen.
    BootLog.reset();
  }

  @override
  Widget build(BuildContext context) => ExampleHost(
    root: const NotesScope(notesEnvironment),
    bootstrap: () => $alloyBootstrap(notesEnvironment),
    rootName: $alloyRootScopeName,
    seedColor: Colors.indigo,
    child: widget.screen,
  );
}
