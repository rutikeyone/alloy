import 'package:flutter/material.dart';
import 'package:gallery/catalog/catalog.dart';
import 'package:gallery/catalog/example_entry.dart';
import 'package:gallery/catalog/glyphs.dart';
import 'package:gallery/design/gallery_theme.dart';
import 'package:gallery/design/node_glyph.dart';
import 'package:gallery/features/detail/detail_screen.dart';
import 'package:gallery/features/hub/example_card.dart';

enum _Filter {
  all('All 7'),
  screen('Screens'),
  terminal('Terminal');

  const _Filter(this.label);

  final String label;

  bool matches(ExampleEntry e) => switch (this) {
    _Filter.all => true,
    _Filter.screen => e.kind == ExampleKind.screen,
    _Filter.terminal => e.kind == ExampleKind.terminal,
  };
}

class HubScreen extends StatefulWidget {
  const HubScreen({super.key});

  @override
  State<HubScreen> createState() => _HubScreenState();
}

class _HubScreenState extends State<HubScreen> {
  final _catalog = buildCatalog();
  var _filter = _Filter.all;

  @override
  Widget build(BuildContext context) {
    final visible = _catalog.where(_filter.matches).toList();

    return Scaffold(
      body: Stack(
        children: [
          const _CornerGlow(),
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: _Masthead(),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
                  child: Row(
                    children: [
                      for (final f in _Filter.values) ...[
                        _FilterChip(
                          label: f.label,
                          selected: _filter == f,
                          onTap: () => setState(() => _filter = f),
                        ),
                        if (f != _Filter.values.last) const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                    itemCount: visible.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) => ExampleCard(
                      entry: visible[i],
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => DetailScreen(entry: visible[i]),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Masthead extends StatelessWidget {
  const _Masthead();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          NodeGlyphIcon(
            glyph: Glyphs.mark,
            color: GalleryColors.screen,
            size: 30,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Alloy', style: GalleryText.wordmark),
              Text(
                'dependency injection · examples',
                style: GalleryText.subtitle,
              ),
            ],
          ),
        ],
      ),
      const SizedBox(height: 18),
      Text(
        'Seven graphs, each built to show one thing. Four you can open; three '
        'run in a terminal.',
        style: GalleryText.lede,
      ),
    ],
  );
}

/// The soft light behind the masthead, so the top of the screen is not a flat
/// rectangle of one colour.
class _CornerGlow extends StatelessWidget {
  const _CornerGlow();

  @override
  Widget build(BuildContext context) => Positioned(
    top: -170,
    left: -90,
    child: IgnorePointer(
      child: Container(
        width: 440,
        height: 350,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              GalleryColors.screen.withValues(alpha: 0.15),
              GalleryColors.screen.withValues(alpha: 0),
            ],
            stops: const [0, 0.68],
          ),
        ),
      ),
    ),
  );
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? GalleryColors.screen : Colors.transparent,
    borderRadius: BorderRadius.circular(999),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? GalleryColors.screen : GalleryColors.hairline,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: SizedBox(
            height: 34,
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
                  color: selected
                      ? GalleryColors.canvas
                      : GalleryColors.textMuted,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
