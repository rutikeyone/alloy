import 'package:flutter_test/flutter_test.dart';
import 'package:gallery/catalog/catalog.dart';
import 'package:gallery/catalog/example_entry.dart';
import 'package:gallery/catalog/example_section.dart';

import 'support.dart';

void main() {
  final catalog = buildCatalog(englishStrings);

  test('a screen badge means there is a screen to open', () {
    final lying = catalog
        .where((e) => e.kind == ExampleKind.screen && !e.isOpenable)
        .map((e) => e.title);

    expect(
      lying,
      isEmpty,
      reason:
          'the badge is the promise the card makes; an entry that cannot be '
          'opened belongs in the terminal kind, with its output',
    );
  });

  test('a terminal entry offers its output, not a button', () {
    for (final entry in catalog.where((e) => e.kind == ExampleKind.terminal)) {
      expect(entry.isOpenable, isFalse, reason: entry.title);
    }
  });

  test('ids are unique, since routes and tests key on them', () {
    expect(catalog.map((e) => e.id).toSet(), hasLength(catalog.length));
  });

  test('every section has at least one entry', () {
    final used = catalog.map((e) => e.section).toSet();
    expect(used, containsAll(ExampleSection.values));
  });
}
