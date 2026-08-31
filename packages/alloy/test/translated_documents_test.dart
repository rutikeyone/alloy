import 'dart:io';

import 'package:test/test.dart';

/// The root documents come in threes, and every one of them links to the rest.
///
/// Splitting the README into a description and a [GUIDE.md] doubled the number
/// of files that have to exist in three languages and the number of links
/// between them. Neither half is checkable for meaning — that stays a line in
/// the RELEASING checklist — but both are checkable for existence, and a
/// translation that was never written or a link to a document that moved are
/// the two ways this actually goes wrong.
///
/// Like the package and rule guards, it reads files above its own package,
/// because the check belongs where the thing being checked lives and there is
/// no repository-wide suite to put it in.
void main() {
  final root = Directory('../..');

  const families = {
    'README': 'README',
    'GUIDE': 'GUIDE',
    'MIGRATION': 'MIGRATION',
  };

  String path(String stem) => '${root.path}/$stem';

  List<String> translationsOf(String family) => [
    '$family.md',
    '$family.ru.md',
    '$family.zh-CN.md',
  ];

  group('every root document exists in three languages', () {
    for (final family in families.values) {
      for (final name in translationsOf(family)) {
        test(name, () {
          final file = File(path(name));
          expect(file.existsSync(), isTrue, reason: '$name is missing');
          expect(
            file.readAsStringSync().trim(),
            isNotEmpty,
            reason: 'an empty $name passes CI and helps nobody',
          );
        });
      }
    }
  });

  group('every translation offers the other two', () {
    for (final family in families.values) {
      final switcher =
          '[English]($family.md) · '
          '[Русский]($family.ru.md) · '
          '[中文]($family.zh-CN.md)';

      for (final name in translationsOf(family)) {
        test(name, () {
          expect(
            File(path(name)).readAsLinesSync().first,
            switcher,
            reason:
                'the switcher is the only way a reader moves between '
                'languages, and it has to be identical in all three or one '
                'of them becomes a dead end',
          );
        });
      }
    }
  });

  group('every relative link resolves', () {
    /// Markdown links that point at a path in this repository.
    ///
    /// External URLs are somebody else's to keep alive; an anchor is dropped
    /// because headings are checked by reading, not by regex.
    Iterable<String> linksIn(String name) => RegExp(r'\]\(([^)\s]+)\)')
        .allMatches(File(path(name)).readAsStringSync())
        .map((it) => it.group(1)!)
        .where(
          (target) => !target.startsWith('http') && !target.startsWith('#'),
        )
        .map((target) => target.split('#').first)
        .where((target) => target.isNotEmpty);

    for (final family in families.values) {
      for (final name in translationsOf(family)) {
        test(name, () {
          final broken = linksIn(name)
              .where(
                (target) =>
                    !File(path(target)).existsSync() &&
                    !Directory(path(target)).existsSync(),
              )
              .toSet();

          expect(
            broken,
            isEmpty,
            reason:
                'a link to a document that moved sends the reader nowhere, '
                'and these documents link to each other constantly',
          );
        });
      }
    }
  });
}
