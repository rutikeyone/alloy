import 'package:flutter/widgets.dart';

/// What an example is about, which is how the gallery is organised.
///
/// Sections are framework capabilities rather than projects: a reader arrives
/// wanting to know how scopes end, not wanting to see `notes_app`. That is
/// why one package can supply entries to several sections, and why one
/// section can draw on several packages.
enum ExampleSection {
  startup('Startup', 'Getting a graph up, and choosing which graph'),
  injection('Injection', 'Getting dependencies into the things that need them'),
  scopes('Scopes & lifetime', 'When a graph appears, and when it goes away'),
  codegen('Code generation', 'What the generator writes, and the same by hand'),
  observability('Observability', 'Watching what the graph does'),
  testing('Testing', 'Swapping dependencies out, and the traps');

  const ExampleSection(this.title, this.blurb);

  final String title;
  final String blurb;
}

@immutable
class SectionedEntries<T> {
  const SectionedEntries({required this.section, required this.entries});

  final ExampleSection section;
  final List<T> entries;
}
