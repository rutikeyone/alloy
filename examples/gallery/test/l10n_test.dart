import 'dart:convert';
import 'dart:io';

import 'package:alloy_inspector/alloy_inspector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gallery/app/gallery_app.dart';
import 'package:gallery/catalog/catalog.dart';
import 'package:gallery/features/hub/hub_screen.dart';
import 'package:gallery/l10n/gallery_l10n.dart';

import 'support.dart';

void main() {
  testWidgets('the hub is written in the language in force', (tester) async {
    await tester.pumpWidget(
      galleryHarness(home: const HubScreen(), locale: const Locale('ru')),
    );
    await tester.pump();

    // The first section and its first card: a sliver list builds lazily, so
    // anything below the fold is not in the tree to be found.
    expect(find.text('СТАРТ'), findsOneWidget);
    expect(find.text('Двухфазный старт'), findsOneWidget);
    expect(find.text('ЭКРАН'), findsWidgets);
  });

  testWidgets('and in Chinese, where nothing is upper-cased', (tester) async {
    await tester.pumpWidget(
      galleryHarness(home: const HubScreen(), locale: const Locale('zh')),
    );
    await tester.pump();

    expect(find.text('启动'), findsOneWidget);
    expect(find.text('两阶段启动'), findsOneWidget);
  });

  testWidgets('choosing a language switches the whole app', (tester) async {
    await tester.pumpWidget(const GalleryApp());
    await tester.pumpAndSettle();

    expect(find.text('Two-phase startup'), findsOneWidget);

    await tester.tap(find.byKey(const Key('language-ru')));
    await tester.pumpAndSettle();

    expect(find.text('Двухфазный старт'), findsOneWidget);
    expect(find.text('Two-phase startup'), findsNothing);

    await tester.tap(find.byKey(const Key('language-zh')));
    await tester.pumpAndSettle();

    expect(find.text('两阶段启动'), findsOneWidget);
  });

  testWidgets('the gallery installs the inspector delegate rather than '
      'leaning on its fallback', (tester) async {
    await tester.pumpWidget(const GalleryApp());
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(
      app.localizationsDelegates,
      contains(AlloyInspectorL10n.delegate),
      reason:
          'the inspector reads the ambient locale with no delegate at all, so '
          'the screens would look right either way — only this says which of '
          'the two the gallery is actually demonstrating',
    );
  });

  testWidgets('the inspector inside the gallery follows the switch too', (
    tester,
  ) async {
    final entry = buildCatalog(lookupGalleryL10n(const Locale('ru')))
        .firstWhere((e) => e.id == 'inspector');

    await tester.pumpWidget(
      galleryHarness(
        home: Builder(builder: entry.open!),
        locale: const Locale('ru'),
      ),
    );
    // Two settles: the host shows its loading frame before the scope is
    // published, exactly as AlloyAppScope does anywhere else.
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();

    expect(find.text('Открыть сессионный скоуп'), findsOneWidget);

    await tester.tap(find.byKey(const Key('open-inspector')));
    await tester.pumpAndSettle();

    expect(
      find.text('Alloy · инспектор'),
      findsOneWidget,
      reason:
          'what a reader sees, by whichever of the two routes got them there '
          '— the delegate is checked separately, because this cannot tell '
          'them apart',
    );
    expect(find.text('Дерево'), findsOneWidget);
  });

  testWidgets('a language Space Grotesk cannot write is set in one that can', (
    tester,
  ) async {
    Set<String> familiesOn(Finder finder) => {
      for (final text in tester.widgetList<Text>(finder))
        ?text.style?.fontFamily,
    };

    await tester.pumpWidget(
      galleryHarness(home: const HubScreen(), locale: const Locale('en')),
    );
    await tester.pump();

    expect(
      familiesOn(find.byType(Text)),
      contains('SpaceGrotesk_regular'),
      reason: 'English is what the gallery was drawn in',
    );

    await tester.pumpWidget(
      galleryHarness(home: const HubScreen(), locale: const Locale('ru')),
    );
    await tester.pump();

    final russian = familiesOn(find.byType(Text));
    expect(russian, contains('Manrope_regular'));
    expect(
      russian,
      isNot(contains('SpaceGrotesk_regular')),
      reason:
          'Space Grotesk has no Cyrillic, so a style still naming it is a call '
          'site that never learned about the language — and the symptom is a '
          'change of typeface in the middle of a word, not a crash',
    );
    expect(
      russian,
      contains('JetBrainsMono_regular'),
      reason: 'the mono face does cover Cyrillic and must not have moved',
    );
  });

  test('the catalog carries no prose of its own', () {
    final english = buildCatalog(englishStrings);
    final russian = buildCatalog(lookupGalleryL10n(const Locale('ru')));

    expect(
      russian.map((e) => e.id),
      english.map((e) => e.id),
      reason:
          'an id is identity — routes and tests key on it, so it is the '
          'one thing that must not move with the language',
    );
    for (var i = 0; i < english.length; i++) {
      expect(
        russian[i].title,
        isNot(english[i].title),
        reason:
            '${english[i].id} reads the same in both languages, which means '
            'it is still a literal in catalog.dart rather than a string',
      );
      for (var p = 0; p < english[i].points.length; p++) {
        expect(russian[i].points[p], isNot(english[i].points[p]));
      }
    }
  });

  test('every translation covers the template, key for key', () {
    Set<String> keysOf(String name) {
      final decoded = jsonDecode(
        File('l10n/$name.arb').readAsStringSync(),
      ) as Map<String, dynamic>;
      return decoded.keys.where((key) => !key.startsWith('@')).toSet();
    }

    final template = keysOf('gallery_en');
    expect(template, isNotEmpty);

    for (final locale in ['ru', 'zh']) {
      expect(
        keysOf('gallery_$locale'),
        template,
        reason:
            'a missing translation is only a warning from gen-l10n, and then '
            'that one line silently comes back in English — in a catalog of '
            'prose that reads as a typo rather than as a gap',
      );
    }
  });
}
