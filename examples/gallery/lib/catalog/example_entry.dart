import 'package:flutter/widgets.dart';
import 'package:gallery/catalog/example_section.dart';
import 'package:gallery/design/gallery_theme.dart';
import 'package:gallery/design/node_glyph.dart';

/// Whether an example is something you open or something that prints.
///
/// The distinction is not cosmetic: three of the seven have no UI at all, and
/// a gallery that offered to "open" them would be lying. Each kind gets its
/// own accent and its own kind of detail screen.
enum ExampleKind {
  screen('screen', GalleryColors.screen),
  terminal('terminal', GalleryColors.terminal);

  const ExampleKind(this.label, this.tint);

  final String label;
  final Color tint;
}

@immutable
class ExampleEntry {
  const ExampleEntry({
    required this.id,
    required this.title,
    required this.kind,
    required this.section,
    required this.teaches,
    required this.glyph,
    required this.points,
    required this.transcriptLabel,
    required this.transcript,
    this.open,
  });

  final String id;
  final String title;
  final ExampleKind kind;
  final ExampleSection section;

  /// One line: what this example exists to show.
  final String teaches;

  final NodeGlyph glyph;

  /// The four things worth knowing, as they appear on the detail screen.
  final List<String> points;

  final String transcriptLabel;
  final String transcript;

  /// Builds the example, graph and all. Null for the ones with no UI — that is
  /// what makes the detail screen show a transcript instead of a button.
  final WidgetBuilder? open;

  bool get isOpenable => open != null;
}
