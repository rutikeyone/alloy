import 'dart:io';

import 'package:test/test.dart';

/// Every root document comes in three languages, and links to its siblings.
///
/// Splitting the README into a description and a guide, and then splitting the
/// guide by mode, took the root documents from three files to twelve and
/// multiplied the links between them by more than that. Whether a translation
/// still says what the English says is not checkable by machine — that stays a
/// line in the RELEASING checklist. What is checkable is that it exists and
/// that its links land somewhere, which are the two ways this actually goes
/// wrong.
///
/// Like the package and rule guards, it reads files above its own package,
/// because the check belongs where the thing being checked lives and there is
/// no repository-wide suite to put it in.
void main() {
  final root = Directory('../..');

  const families = {'README', 'GUIDE_MANUAL', 'GUIDE_CODEGEN', 'MIGRATION'};

  String path(String stem) => '${root.path}/$stem';

  List<String> translationsOf(String family) => [
    '$family.md',
    '$family.ru.md',
    '$family.zh-CN.md',
  ];

  group('every root document exists in three languages', () {
    for (final family in families) {
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
    for (final family in families) {
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

    for (final family in families) {
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
