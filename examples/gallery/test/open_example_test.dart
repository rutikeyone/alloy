import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gallery/catalog/catalog.dart';
import 'package:gallery/catalog/example_host.dart';
import 'package:gallery/design/gallery_theme.dart';

void main() {
  testWidgets('every openable entry mounts with a graph of its own', (
    tester,
  ) async {
    final openable = buildCatalog().where((e) => e.isOpenable).toList();
    expect(openable, isNotEmpty, reason: 'nothing is wired in yet');

    for (final entry in openable) {
      await tester.pumpWidget(
        MaterialApp(
          theme: galleryTheme(),
          // Keyed per entry, so each iteration builds a fresh element rather
          // than updating the previous one. AlloyAppScope has no
          // didUpdateWidget — handed a new root in the same slot it keeps the
          // graph it already owns, and the next resolve looks in the wrong one.
          home: Builder(key: ValueKey(entry.id), builder: entry.open!),
        ),
      );
      // Two settles: the host shows its loading frame before the scope is
      // published, exactly as AlloyAppScope does anywhere else.
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      expect(
        find.byType(ExampleHost),
        findsOneWidget,
        reason: '${entry.title} did not mount',
      );
      expect(
        find.byType(CircularProgressIndicator),
        findsNothing,
        reason: '${entry.title} never finished starting its graph',
      );
      expect(tester.takeException(), isNull, reason: entry.title);

      // One palette, examples included. Read from inside the example rather
      // than above it: a theme an example brought with it would sit between
      // the gallery's and its own scaffolds, and only this side of it sees
      // the difference.
      final scaffolds = tester.elementList(find.byType(Scaffold));
      expect(
        scaffolds,
        isNotEmpty,
        reason: '${entry.title} rendered no scaffold',
      );
      for (final scaffold in scaffolds) {
        expect(
          Theme.of(scaffold).scaffoldBackgroundColor,
          GalleryColors.canvas,
          reason:
              '${entry.title} paints on a background of its own; the gallery '
              'has one palette and every example is painted by it',
        );
      }
    }
  });
}
