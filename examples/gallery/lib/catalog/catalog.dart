import 'package:alloy/alloy.dart';
import 'package:alloy_talker/alloy_talker.dart';
import 'package:codegen_basics/alloy.g.dart' as codegen;
import 'package:codegen_basics/counter_screen.dart';
import 'package:flutter/material.dart';
import 'package:gallery/catalog/example_entry.dart';
import 'package:gallery/catalog/example_host.dart';
import 'package:gallery/catalog/example_section.dart';
import 'package:gallery/catalog/flow_scopes_host.dart';
import 'package:gallery/catalog/glyphs.dart';
import 'package:gallery/catalog/notes_graph.dart';
import 'package:graph_events/app/app_scope.dart';
import 'package:graph_events/app/audit_log.dart';
import 'package:graph_events/features/home/ui/home_screen.dart' as events;
import 'package:notes_app/features/diagnostics/ui/scope_tree_screen.dart';
import 'package:notes_app/features/environments/ui/environments_screen.dart';
import 'package:notes_app/features/formatting/ui/formatters_screen.dart';
import 'package:notes_app/features/home/ui/home_screen.dart' as notes;
import 'package:notes_app/features/note_detail/ui/note_detail_screen.dart';
import 'package:notes_app/features/notes/ui/notes_screen.dart';
import 'package:notes_app/features/session/ui/session_screen.dart';
import 'package:talker/talker.dart';

/// Every capability the framework has an example for.
///
/// Ordered by section, and within a section by what to read first. The list is
/// deliberately not grouped by which package a screen came from — that is an
/// implementation detail of the repository, not something a reader is looking
/// for.
List<ExampleEntry> buildCatalog() => [
  // ── Startup ───────────────────────────────────────────────────────────
  ExampleEntry(
    id: 'startup',
    title: 'Two-phase startup',
    kind: ExampleKind.screen,
    section: ExampleSection.startup,
    teaches:
        'Bootstrap steps run before a container exists; async initializers run '
        'as a graph.',
    glyph: Glyphs.notes,
    points: const [
      'Phase 0 steps are adopted by the root scope and released with it',
      'A step that opened something is closed last, after everything built on it',
      'Phase 1 awaits @AlloyInit as a graph, so independent branches run together',
      'dependsOn decides the order — you never write the sequence yourself',
    ],
    transcriptLabel: 'Where it lives',
    transcript: 'examples/notes_app/lib/features/home/ui/home_screen.dart',
    open: (_) => notesGraph(const notes.HomeScreen()),
  ),
  ExampleEntry(
    id: 'environments',
    title: 'Environments',
    kind: ExampleKind.screen,
    section: ExampleSection.startup,
    teaches: 'One interface, a different implementation per build.',
    glyph: Glyphs.codegen,
    points: const [
      '@AlloyEnvironment repeats rather than taking a list — a registration '
          'belongs to a set, a start picks one',
      'Two registrations whose environments overlap fail the build, not the app',
      'Choosing nothing leaves the split types unregistered, so the miss is loud',
      'Manual Mode writes the same `if` the generator emits',
    ],
    transcriptLabel: 'Where it lives',
    transcript: 'examples/notes_app/lib/features/environments/ui/environments_screen.dart',
    open: (_) => notesGraph(const EnvironmentsScreen()),
  ),

  // ── Injection ─────────────────────────────────────────────────────────
  ExampleEntry(
    id: 'property',
    title: 'Property injection',
    kind: ExampleKind.screen,
    section: ExampleSection.injection,
    teaches: 'A controller with an empty constructor and fields filled from the graph.',
    glyph: Glyphs.flow,
    points: const [
      'The mixin is generated beside the class and fills the fields after '
          'construction',
      'Fields may be private — the part file is in the same library',
      'late final is enforced, so a second assignment throws instead of '
          'quietly swapping a dependency',
      'This is what removes five to fourteen constructor arguments',
    ],
    transcriptLabel: 'Where it lives',
    transcript: 'examples/notes_app/lib/features/notes/ui/notes_screen.dart',
    open: (_) => notesGraph(const NotesScreen()),
  ),
  ExampleEntry(
    id: 'named',
    title: 'Named and multi-injection',
    kind: ExampleKind.screen,
    section: ExampleSection.injection,
    teaches:
        'Several implementations behind one interface, told apart by name.',
    glyph: Glyphs.testing,
    points: const [
      '@Named picks one registration of a type that has several',
      'getAll returns every registration of a type, in registration order',
      'A duplicate of the same key in one scope is an error, not a silent '
          'last-one-wins',
    ],
    transcriptLabel: 'Where it lives',
    transcript:
        'examples/notes_app/lib/features/formatting/ui/formatters_screen.dart',
    open: (_) => notesGraph(const FormattersScreen()),
  ),

  // ── Scopes & lifetime ─────────────────────────────────────────────────
  ExampleEntry(
    id: 'widget-scope',
    title: 'Widget-owned scope',
    kind: ExampleKind.screen,
    section: ExampleSection.scopes,
    teaches: 'A graph that lives exactly as long as one screen.',
    glyph: Glyphs.manual,
    points: const [
      'AlloyScopedStatefulWidget registers into a scope it owns',
      'Leaving the screen disposes everything the screen built',
      'registerParamFactory passes a value into construction',
      'The parent graph stays untouched — this is a child, not a mutation',
    ],
    transcriptLabel: 'Where it lives',
    transcript: 'examples/notes_app/lib/features/note_detail/ui/note_detail_screen.dart',
    open: (_) => notesGraph(const NoteDetailScreen()),
  ),
  ExampleEntry(
    id: 'session',
    title: 'Session scope',
    kind: ExampleKind.screen,
    section: ExampleSection.scopes,
    teaches: 'Signing out is one dispose() and nothing else.',
    glyph: Glyphs.events,
    points: const [
      'Everything the session built goes with the session scope',
      'No repository implements reset(), and nothing listens to the session',
      'This is the argument for a tree of scopes rather than a flat stack',
    ],
    transcriptLabel: 'Where it lives',
    transcript:
        'examples/notes_app/lib/features/session/ui/session_screen.dart',
    open: (_) => notesGraph(const SessionScreen()),
  ),
  ExampleEntry(
    id: 'scope-tree',
    title: 'Scope tree',
    kind: ExampleKind.screen,
    section: ExampleSection.scopes,
    teaches: 'The live hierarchy, rendered from the scopes themselves.',
    glyph: Glyphs.notes,
    points: const [
      'AlloyScope.children is public, so the tree is inspectable at runtime',
      'Open two examples and their trees are unrelated — each has its own root',
      'Depth and parent are on the scope, which is what diagnostics read',
    ],
    transcriptLabel: 'Where it lives',
    transcript:
        'examples/notes_app/lib/features/diagnostics/ui/scope_tree_screen.dart',
    open: (_) => notesGraph(const ScopeTreeScreen()),
  ),
  ExampleEntry(
    id: 'flow',
    title: 'Navigation flows',
    kind: ExampleKind.screen,
    section: ExampleSection.scopes,
    teaches: 'A scope that lives exactly as long as a navigation flow is open.',
    glyph: Glyphs.flow,
    points: const [
      'AlloyShellRoute — enter the flow and the scope appears; leave and it is gone',
      'identity rebuilds the scope when the flow’s subject changes',
      'Tabs: a branch is kept alive, not visible, so switching disposes nothing',
      'No router listener anywhere — ownership belongs to the widget tree',
    ],
    transcriptLabel: 'Where it lives',
    transcript: 'examples/flow_scopes/lib/app/app_router.dart',
    open: (_) => const FlowScopesHost(),
  ),
  ExampleEntry(
    id: 'teardown',
    title: 'Teardown',
    kind: ExampleKind.terminal,
    section: ExampleSection.scopes,
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

  // ── Code generation ───────────────────────────────────────────────────
  ExampleEntry(
    id: 'codegen',
    title: 'Generated container',
    kind: ExampleKind.screen,
    section: ExampleSection.codegen,
    teaches: 'The smallest generated setup there is, and what it writes.',
    glyph: Glyphs.codegen,
    points: const [
      'Put @alloyInject on a class and lib/alloy.g.dart appears',
      'Named const factory classes in the output — never closures',
      'Registrations ordered by a compile-time topological sort',
      'A dependency cycle fails the build naming the cycle',
    ],
    transcriptLabel: 'Where it lives',
    transcript: 'examples/codegen_basics/lib/counter_screen.dart',
    open: (_) => const ExampleHost(
      root: codegen.$AlloyRootScope(),
      rootName: codegen.$alloyRootScopeName,
      seedColor: Colors.teal,
      child: CounterScreen(),
    ),
  ),
  ExampleEntry(
    id: 'manual',
    title: 'Manual mode',
    kind: ExampleKind.terminal,
    section: ExampleSection.codegen,
    teaches: 'The same graph with no generation and no Flutter.',
    glyph: Glyphs.manual,
    points: const [
      'The generator writes exactly this, using only the public API',
      'Pure Dart — runs in a CLI, on a server, in a plain test',
      'AlloyScopeBuilder composes; that is what replaces modules',
      'If generation ever needs something this cannot express, they are two '
          'frameworks sharing a name',
    ],
    transcriptLabel: 'Console output',
    transcript: 'cd examples/manual_mode\ndart run bin/main.dart',
  ),

  // ── Observability ─────────────────────────────────────────────────────
  ExampleEntry(
    id: 'events',
    title: 'Graph events',
    kind: ExampleKind.screen,
    section: ExampleSection.observability,
    teaches: 'The graph reporting on itself, streamed into a logger you already use.',
    glyph: Glyphs.events,
    points: const [
      'AlloyObserver events — scopes pushed, instances built, teardown failing',
      'One line to adapt talker, logging, logger, or any logger at all',
      'AlloyMultiSink fans a record out; a failing sink does not silence the rest',
      'Resolution is deliberately not reported — a cache hit is the hot path',
    ],
    transcriptLabel: 'Where it lives',
    transcript: 'examples/graph_events/lib/app/graph_events_app.dart',
    open: (_) {
      // Built per open, not shared: the observers hold this talker, and a
      // second visit should start with an empty log rather than the last one.
      final talker = Talker();
      final audit = AuditLog();
      return ExampleHost(
        root: const AppScope(),
        bootstrap: () => [WarmUp()],
        rootName: 'app',
        observers: [
          AlloyTalkerObserver(talker, verbose: true),
          AlloyLogObserver(
            AlloyMultiSink([
              const AlloyPrintLogSink(),
              AlloyLogSink.from(
                (record) =>
                    audit.write('${record.level.name} ${record.message}'),
              ),
            ]),
          ),
        ],
        seedColor: Colors.deepOrange,
        child: events.HomeScreen(talker: talker),
      );
    },
  ),

  // ── Testing ───────────────────────────────────────────────────────────
  ExampleEntry(
    id: 'testing',
    title: 'Testing patterns',
    kind: ExampleKind.terminal,
    section: ExampleSection.testing,
    teaches: 'Overriding dependencies in a test, and the traps.',
    glyph: Glyphs.testing,
    points: const [
      'Override by pushing a child scope and registering again — shadowing, '
          'not mutation',
      'Build the graph in setUp; testWidgets runs inside a fake-async zone',
      'No global container, so one test cannot leak into the next',
      'A duplicate in one scope is an error; shadowing from a child is the '
          'supported way',
    ],
    transcriptLabel: 'Test output',
    transcript: 'cd examples/testing_patterns\nflutter test',
  ),
];

/// The catalog grouped for display, in section order.
List<SectionedEntries<ExampleEntry>> buildSections() {
  final all = buildCatalog();
  return [
    for (final section in ExampleSection.values)
      if (all.where((e) => e.section == section).toList() case final entries
          when entries.isNotEmpty)
        SectionedEntries(section: section, entries: entries),
  ];
}
