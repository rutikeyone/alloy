import 'package:flutter/material.dart';
import 'package:gallery/catalog/example_entry.dart';
import 'package:gallery/design/gallery_theme.dart';
import 'package:gallery/design/node_glyph.dart';

class ExampleCard extends StatelessWidget {
  const ExampleCard({required this.entry, required this.onTap, super.key});

  final ExampleEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tint = entry.kind.tint;

    return Material(
      color: GalleryColors.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: GalleryColors.hairline),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GlyphTile(glyph: entry.glyph, tint: tint),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              entry.title,
                              style: GalleryText.cardTitle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          KindBadge(kind: entry.kind),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(entry.teaches, style: GalleryText.cardBody),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: GalleryColors.textFaint,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The rounded square an icon sits in, tinted by kind.
class GlyphTile extends StatelessWidget {
  const GlyphTile({
    required this.glyph,
    required this.tint,
    this.size = 42,
    super.key,
  });

  final NodeGlyph glyph;
  final Color tint;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(size * 0.28),
      color: tint.withValues(alpha: 0.13),
      border: Border.all(color: tint.withValues(alpha: 0.32)),
    ),
    alignment: Alignment.center,
    child: NodeGlyphIcon(glyph: glyph, color: tint, size: size * 0.56),
  );
}

class KindBadge extends StatelessWidget {
  const KindBadge({required this.kind, super.key});

  final ExampleKind kind;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(5),
      border: Border.all(color: kind.tint.withValues(alpha: 0.32)),
    ),
    child: Text(
      kind.label.toUpperCase(),
      style: GalleryText.badge.copyWith(color: kind.tint),
    ),
  );
}
