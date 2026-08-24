import 'package:flutter/material.dart';
import 'package:gallery/catalog/catalog.dart';
import 'package:gallery/catalog/example_section.dart';
import 'package:gallery/catalog/glyphs.dart';
import 'package:gallery/design/gallery_theme.dart';
import 'package:gallery/design/node_glyph.dart';
import 'package:gallery/features/detail/detail_screen.dart';
import 'package:gallery/features/hub/example_card.dart';

class HubScreen extends StatefulWidget {
  const HubScreen({super.key});

  @override
  State<HubScreen> createState() => _HubScreenState();
}

class _HubScreenState extends State<HubScreen> {
  final _sections = buildSections();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Stack(
      children: [
        const _CornerGlow(),
        SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(24, 24, 24, 8),
                sliver: SliverToBoxAdapter(child: _Masthead()),
              ),
              for (final group in _sections) ...[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
                  sliver: SliverToBoxAdapter(
                    child: _SectionHeader(section: group.section),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList.separated(
                    itemCount: group.entries.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) => ExampleCard(
                      entry: group.entries[i],
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => DetailScreen(entry: group.entries[i]),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ],
    ),
  );
}

/// A section heading: what this group is about, in one line.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.section});

  final ExampleSection section;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(section.title.toUpperCase(), style: GalleryText.monoCaps),
      const SizedBox(height: 4),
      Text(section.blurb, style: GalleryText.cardBody),
    ],
  );
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
        'One example per capability. Most open right here; the ones that only '
        'print show you their output instead.',
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
