import 'dart:io';

import 'package:test/test.dart';

/// Adding a package means naming it in six places, and nothing checked five.
///
/// This is the sibling of `alloy_lint`'s `documented_rules_test`, which earned
/// itself on the very next rule anyone added. The ritual here is longer: the
/// workspace, two CI loops, three package tables and the release order — and
/// the failure modes differ. A package missing from a README is a package
/// nobody finds; missing from a CI loop is a package nobody tests or checks;
/// missing from the release order is a release that fails version solving
/// halfway through, having already published half of it.
///
/// It reads files above its own package, which is unusual for a test that
/// ships. The same trade as the rules guard, for the same reason: the check
/// belongs where the thing being checked lives, and there is no repository-wide
/// suite to put it in.
void main() {
  final root = Directory('../..');

  final shipped = Directory('${root.path}/packages')
      .listSync()
      .whereType<Directory>()
      .map((it) => it.uri.pathSegments[it.uri.pathSegments.length - 2])
      .where(
        (name) => File('${root.path}/packages/$name/pubspec.yaml').existsSync(),
      )
      .toSet();

  String read(String path) => File('${root.path}/$path').readAsStringSync();

  test('there are packages to check', () => expect(shipped, isNotEmpty));

  group('every package is named in', () {
    /// The first cell of every row of every table that lists a package.
    ///
    /// Found by contents rather than by heading, because these documents hold
    /// other tables keyed the same way — the twelve lint rules are one — and
    /// the heading above the right ones is in three languages. A table holding
    /// a real package is a package table; the rules table holds none.
    Set<String> packageTable(String path) {
      final rows = <String>{};
      var table = <String>{};

      for (final line in read(path).split('\n')) {
        final row = RegExp(r'^\| `(alloy[a-z_]*)` \|').firstMatch(line);
        if (row != null) {
          table.add(row.group(1)!);
          continue;
        }
        if (!line.startsWith('|')) {
          if (table.intersection(shipped).isNotEmpty) rows.addAll(table);
          table = {};
        }
      }
      if (table.intersection(shipped).isNotEmpty) rows.addAll(table);
      return rows;
    }

    for (final readme in ['README.md', 'README.ru.md', 'README.zh-CN.md']) {
      test(readme, () {
        final listed = packageTable(readme);
        expect(shipped.difference(listed), isEmpty);
        expect(listed.difference(shipped), isEmpty);
      });
    }

    test('the release order', () {
      final order = read('RELEASING.md');
      final block = order.substring(
        order.indexOf('## Order'),
        order.indexOf('Steps within a numbered group'),
      );
      final listed = RegExp(
        r'^\s*(?:\d+\.\s+)?(alloy[a-z_]*)\s',
        multiLine: true,
      ).allMatches(block).map((it) => it.group(1)!).toSet();

      expect(
        shipped.difference(listed),
        isEmpty,
        reason:
            'a package missing here is a release that stops halfway with half '
            'of it already published, because version solving cannot find '
            'what it depends on',
      );
      expect(listed.difference(shipped), isEmpty);
    });

    test('both CI loops', () {
      final ci = read('.github/workflows/ci.yml');
      final named = RegExp(r'packages/(alloy[a-z_]*)')
          .allMatches(ci)
          .map((it) => it.group(1)!)
          .toSet();

      expect(
        shipped.difference(named),
        isEmpty,
        reason:
            'a package no CI loop names is one nobody tests and nobody '
            'checks the archive of',
      );
    });
  });

  test('the release note counts the packages it lists', () {
    const words = {
      12: 'Twelve',
      13: 'Thirteen',
      14: 'Fourteen',
      15: 'Fifteen',
      16: 'Sixteen',
      17: 'Seventeen',
    };

    expect(
      read('RELEASING.md'),
      contains('${words[shipped.length]} packages depend on each other'),
      reason:
          'the count is prose beside a list, and prose beside a list is what '
          'goes stale — this one at least can be derived',
    );
  });
}
