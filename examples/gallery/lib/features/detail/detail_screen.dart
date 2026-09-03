import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gallery/catalog/example_entry.dart';
import 'package:gallery/design/gallery_theme.dart';
import 'package:gallery/features/hub/example_card.dart';
import 'package:gallery/l10n/gallery_l10n.dart';

class DetailScreen extends StatelessWidget {
  const DetailScreen({required this.entry, super.key});

  final ExampleEntry entry;

  @override
  Widget build(BuildContext context) {
    final tint = entry.kind.tint;
    final l10n = GalleryL10n.of(context);
    final text = GalleryText.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: Text(
          l10n.allExamples,
          style: text.body.copyWith(color: GalleryColors.textMuted),
        ),
        titleSpacing: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          // Aligned, not bare: a direct child of ListView is stretched to the
          // full width, which would turn the 60px tile into a band.
          Align(
            alignment: Alignment.centerLeft,
            child: GlyphTile(glyph: entry.glyph, tint: tint, size: 60),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Flexible(child: Text(entry.title, style: text.title)),
              const SizedBox(width: 9),
              KindBadge(kind: entry.kind),
            ],
          ),
          const SizedBox(height: 8),
          Text(entry.teaches, style: text.lede),
          const SizedBox(height: 24),
          _Label(l10n.whatItShows),
          const SizedBox(height: 11),
          for (final point in entry.points) _Point(text: point, tint: tint),
          const SizedBox(height: 13),
          _Label(entry.transcriptLabel),
          const SizedBox(height: 11),
          _Transcript(text: entry.transcript),
          const SizedBox(height: 24),
          _Action(entry: entry),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text.toUpperCase(), style: GalleryText.of(context).monoCaps);
}

class _Point extends StatelessWidget {
  const _Point({required this.text, required this.tint});

  final String text;
  final Color tint;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 11),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(top: 7),
          decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
        ),
        const SizedBox(width: 11),
        Expanded(child: Text(text, style: GalleryText.of(context).body)),
      ],
    ),
  );
}

class _Transcript extends StatelessWidget {
  const _Transcript({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: GalleryColors.terminalSurface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: GalleryColors.hairline),
    ),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Text(text, style: GalleryText.of(context).mono),
    ),
  );
}

/// Opens the example where there is one to open, and otherwise copies the
/// command — the honest action for the three that only print.
class _Action extends StatelessWidget {
  const _Action({required this.entry});

  final ExampleEntry entry;

  @override
  Widget build(BuildContext context) {
    final tint = entry.kind.tint;
    final l10n = GalleryL10n.of(context);
    final open = entry.open;

    return SizedBox(
      height: 50,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: tint,
          foregroundColor: GalleryColors.canvas,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: open != null
            ? () => Navigator.of(
                context,
              ).push(MaterialPageRoute<void>(builder: open))
            : () => _copy(context, l10n),
        child: Text(
          open != null ? l10n.openExample : l10n.copyCommand,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Future<void> _copy(BuildContext context, GalleryL10n l10n) async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: entry.transcript));
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(l10n.commandCopied),
      ),
    );
  }
}
