import 'package:gallery/catalog/example_entry.dart';
import 'package:gallery/catalog/glyphs.dart';

/// Every example in the repository, in the order worth reading them.
///
/// `open` stays null until an example is wired in; a null one shows its
/// transcript instead of a button, which is also the permanent state of the
/// three that have no UI.
List<ExampleEntry> buildCatalog() => [
  ExampleEntry(
    id: 'notes',
    title: 'Notes',
    kind: ExampleKind.screen,
    teaches:
        'The full tour — both startup phases, scopes, property injection, '
        'environments.',
    glyph: Glyphs.notes,
    points: const [
      'Phase 0 bootstrap steps, adopted by the root scope and released with it',
      'An async @AlloyInit graph where dependsOn decides the order',
      'Sign-out as one dispose() — no session listeners, no reset() on repositories',
      'The live scope tree, rendered from AlloyScope.children',
    ],
    transcriptLabel: 'Run it standalone',
    transcript: 'cd examples/notes_app\nflutter run',
  ),
  ExampleEntry(
    id: 'flow',
    title: 'Flow scopes',
    kind: ExampleKind.screen,
    teaches: 'A scope that lives exactly as long as a navigation flow is open.',
    glyph: Glyphs.flow,
    points: const [
      'AlloyShellRoute — enter the flow and the scope appears; leave and it is gone',
      'identity rebuilds the scope when the flow’s subject changes',
      'Tabs: a branch is kept alive, not visible, so switching disposes nothing',
      'No router listener anywhere — ownership belongs to the widget tree',
    ],
    transcriptLabel: 'Run it standalone',
    transcript: 'cd examples/flow_scopes\nflutter run',
  ),
  ExampleEntry(
    id: 'events',
    title: 'Graph events',
    kind: ExampleKind.screen,
    teaches: 'The graph reporting on itself, streamed into a logger you already use.',
    glyph: Glyphs.events,
    points: const [
      'AlloyObserver events — scopes pushed, instances built, teardown failing',
      'One line to adapt talker, logging, logger, or any logger at all',
      'AlloyMultiSink fans a record out; a failing sink does not silence the rest',
      'Resolution is deliberately not reported — a cache hit is the hot path',
    ],
    transcriptLabel: 'Run it standalone',
    transcript: 'cd examples/graph_events\nflutter run',
  ),
  ExampleEntry(
    id: 'codegen',
    title: 'Codegen basics',
    kind: ExampleKind.screen,
    teaches: 'The smallest generated container there is, and what the generator writes.',
    glyph: Glyphs.codegen,
    points: const [
      'Put @alloyInject on a class and lib/alloy.g.dart appears',
      'Named const factory classes in the output — never closures',
      'Registrations ordered by a compile-time topological sort',
      '@injected fields filled by a mixin generated beside the class',
    ],
    transcriptLabel: 'Run it standalone',
    transcript:
        'cd examples/codegen_basics\ndart run build_runner build\nflutter run',
  ),
  ExampleEntry(
    id: 'teardown',
    title: 'Teardown',
    kind: ExampleKind.terminal,
    teaches: 'What disposal actually guarantees — order, failures, timeouts, adoption.',
    glyph: Glyphs.teardown,
    points: const [
      'LIFO by creation order, not by the order things were declared',
      'A dispose that throws is recorded; everything else still runs',
      'A dispose that hangs hits the deadline and is reported, not awaited forever',
      'adopt() ties a non-dependency’s life to the scope',
    ],
    transcriptLabel: 'Console output',
    transcript: 'cd examples/teardown\ndart run bin/main.dart',
  ),
  ExampleEntry(
    id: 'manual',
    title: 'Manual mode',
    kind: ExampleKind.terminal,
    teaches: 'The runtime with no generation and no Flutter — the same graph, written out.',
    glyph: Glyphs.manual,
    points: const [
      'The generator writes exactly this, using only the public API',
      'Pure Dart — runs in a CLI, on a server, in a plain test',
      'AlloyScopeBuilder composes; that is what replaces modules',
      'AlloyPrintLogSink for a first look at what the graph is doing',
    ],
    transcriptLabel: 'Console output',
    transcript: 'cd examples/manual_mode\ndart run bin/main.dart',
  ),
  ExampleEntry(
    id: 'testing',
    title: 'Testing patterns',
    kind: ExampleKind.terminal,
    teaches: 'How to test an app built on Alloy — overriding dependencies, and the traps.',
    glyph: Glyphs.testing,
    points: const [
      'Override by pushing a child scope and registering again — shadowing, not mutation',
      'Build the graph in setUp; testWidgets runs inside a fake-async zone',
      'No global container, so one test cannot leak into the next',
      'A duplicate in one scope is an error; shadowing from a child is the supported way',
    ],
    transcriptLabel: 'Test output',
    transcript: 'cd examples/testing_patterns\nflutter test',
  ),
];
