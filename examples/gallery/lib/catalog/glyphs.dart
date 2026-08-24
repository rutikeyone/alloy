import 'package:flutter/widgets.dart';
import 'package:gallery/design/node_glyph.dart';

/// The icon set, one family: nodes and the edges between them.
///
/// Coordinates are the 24×24 grid from the design canvas, kept as literals so
/// the drawing here and the drawing there can be compared line by line.
abstract final class Glyphs {
  /// A tree — the whole graph, which is what the full tour shows.
  static NodeGlyph get notes =>
      (GlyphBuilder()
            ..node(12, 4)
            ..node(5, 12)
            ..node(19, 12)
            ..node(19, 20)
            ..edge(10.6, 5.6, 6.4, 10.4)
            ..edge(13.4, 5.6, 17.6, 10.4)
            ..edge(19, 14.1, 19, 17.9))
          .build();

  /// A path through nodes, with an arrow: you move along it and out.
  static NodeGlyph get flow =>
      (GlyphBuilder()
            ..node(4.5, 12)
            ..node(12, 12)
            ..node(19.5, 12)
            ..edge(6.6, 12, 9.9, 12)
            ..edge(14.1, 12, 17.4, 12)
            ..polyline(const [
              Offset(17.4, 9.6),
              Offset(19.9, 12),
              Offset(17.4, 14.4),
            ]))
          .build();

  /// One node, broadcasting.
  static NodeGlyph get events =>
      (GlyphBuilder()
            ..node(8.5, 12)
            ..edge(4.2, 12, 6.4, 12)
            ..arc(8.5, 12, 5, -42, 84)
            ..arc(8.5, 12, 9, -42, 84))
          .build();

  /// A hand-written node, and a generated one beside it.
  static NodeGlyph get codegen =>
      (GlyphBuilder()
            ..node(7, 7)
            ..edge(9.1, 9.1, 12, 12)
            ..polyline(const [
              Offset(4.4, 14.6),
              Offset(4.4, 18.6),
              Offset(8.4, 18.6),
            ])
            ..box(12.5, 12.5, 8, 8, dashed: true))
          .build();

  /// Edges coming apart, and the floor everything settles onto.
  static NodeGlyph get teardown =>
      (GlyphBuilder()
            ..node(12, 5)
            ..node(6, 14)
            ..node(18, 14)
            ..edge(3.6, 19.4, 20.4, 19.4)
            ..edge(10.7, 6.7, 7.3, 11.9, dashed: true)
            ..edge(13.3, 6.7, 16.7, 11.9, dashed: true))
          .build();

  /// Two nodes joined by hand, over written lines.
  static NodeGlyph get manual =>
      (GlyphBuilder()
            ..node(7, 8)
            ..node(17, 16)
            ..curve(
              const Offset(8.7, 9.5),
              const Offset(12.2, 11.2),
              const Offset(15.3, 14.6),
            )
            ..edge(4, 17.6, 8.6, 17.6)
            ..edge(4, 20.4, 11.4, 20.4))
          .build();

  /// A real node and the stand-in that replaces it.
  static NodeGlyph get testing =>
      (GlyphBuilder()
            ..node(7.5, 7.5)
            ..edge(9.2, 9.2, 14.8, 14.8)
            ..polyline(const [
              Offset(14.6, 5.4),
              Offset(18.8, 5.4),
              Offset(18.8, 9.6),
            ])
            ..polyline(const [
              Offset(9.4, 18.6),
              Offset(5.2, 18.6),
              Offset(5.2, 14.4),
            ])
            ..node(16.5, 16.5, dashed: true))
          .build();

  /// The wordmark: the smallest possible graph.
  static NodeGlyph get mark =>
      (GlyphBuilder()
            ..node(12, 4.5, r: 2.4)
            ..node(5, 18, r: 2.4)
            ..node(19, 18, r: 2.4)
            ..edge(10.6, 6.6, 6.4, 15.9)
            ..edge(13.4, 6.6, 17.6, 15.9)
            ..edge(7.4, 18, 16.6, 18))
          .build();
}
