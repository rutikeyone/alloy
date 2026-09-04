@Tags(['repo'])
library;

import 'dart:io';

import 'package:test/test.dart';

/// Adding a package means naming it in six places, and nothing checked five.
///
/// This is the sibling of `cobalt_lint`'s `documented_rules_test`, which earned
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
        final row = RegExp(r'^\| `(cobalt[a-z_]*)` \|').firstMatch(line);
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
        r'^\s*(?:\d+\.\s+)?(cobalt[a-z_]*)\s',
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
      final named = RegExp(
        r'packages/(cobalt[a-z_]*)',
      ).allMatches(ci).map((it) => it.group(1)!).toSet();

      expect(
        shipped.difference(named),
        isEmpty,
        reason:
            'a package no CI loop names is one nobody tests and nobody '
            'checks the archive of',
      );
    });
  });

  group('versions move in lockstep', () {
    /// The version a package declares, and the one its changelog heads with.
    ///
    /// Read by line rather than parsed: a pubspec's `version:` is always at
    /// the top level, and a changelog's first `## ` heading is the release
    /// being described. Neither needs a parser to be read correctly, and a
    /// parser here would be a dependency this package does not otherwise have.
    (String?, String?) versionsOf(String package) {
      final pubspec = File('${root.path}/packages/$package/pubspec.yaml')
          .readAsLinesSync()
          .firstWhere((line) => line.startsWith('version:'), orElse: () => '');
      final changelog = File('${root.path}/packages/$package/CHANGELOG.md')
          .readAsLinesSync()
          .firstWhere((line) => line.startsWith('## '), orElse: () => '');

      return (
        pubspec.isEmpty ? null : pubspec.substring('version:'.length).trim(),
        changelog.isEmpty ? null : changelog.substring('## '.length).trim(),
      );
    }

    test('every package declares the same version', () {
      final declared = {
        for (final package in shipped) package: versionsOf(package).$1,
      };

      expect(
        declared.values.toSet(),
        hasLength(1),
        reason:
            'lockstep is the whole versioning policy, and RELEASING says why: '
            'a DI framework whose runtime and generator drift apart produces '
            'generation errors nobody can decipher. A release that bumps '
            'fourteen of fifteen is how the drift starts.\n'
            'Declared: $declared',
      );
    });

    for (final package in shipped) {
      test('$package changelogs the version it declares', () {
        final (pubspec, changelog) = versionsOf(package);

        expect(pubspec, isNotNull, reason: '$package declares no version');
        expect(
          changelog,
          pubspec,
          reason:
              'pub.dev shows the changelog beside the version, so a heading '
              'that names a different one is the first thing a reader sees '
              'and the last thing anyone re-reads before publishing',
        );
      });
    }
  });

  group('there is one floor, and it is one floor', () {
    /// One floor for all fifteen, measured rather than rounded.
    ///
    /// It was two until 2026-09-04, when the binding constraint turned out not
    /// to be the SDK at all: Flutter 3.38 pins `meta 1.17.0` and analyzer
    /// 10.0.2 wants `^1.18.0`, so a Flutter application there tops out at
    /// analyzer 10.0.1 whatever anyone's SDK constraint says. The toolchain
    /// three now declare `>=10.0.1 <13.0.0` and land on 10.0.1 or 12.1.0
    /// depending on the consumer.
    ///
    /// That range has exactly two usable rows, because every package reading
    /// the analyzer — `analysis_server_plugin`, `analyzer_plugin`,
    /// `analyzer_testing`, `dart_style` — pins it exactly. Which is why the
    /// third test here exists: the three have to agree on the range, or they
    /// stop agreeing about what a declaration means.
    const toolchain = {'cobalt_analyzer', 'cobalt_generator', 'cobalt_lint'};

    /// The constraint a package declares, by key.
    String? constraintOf(String package, String key) {
      for (final line in File(
        '${root.path}/packages/$package/pubspec.yaml',
      ).readAsLinesSync()) {
        if (line.startsWith('  $key:')) {
          return line.substring('  $key:'.length).trim();
        }
      }
      return null;
    }

    Map<String, String?> declaredBy(Iterable<String> packages, String key) => {
      for (final package in packages) package: constraintOf(package, key),
    };

    test('every package agrees on one Dart floor', () {
      final declared = declaredBy(shipped, 'sdk');

      expect(
        declared.values.toSet(),
        hasLength(1),
        reason:
            'the floor is a promise, and packages that disagree about it make '
            'the promise unreadable — a consumer gets the highest floor among '
            'whatever subset they happen to depend on.\n'
            'Declared: $declared',
      );
    });

    test('every Flutter package agrees on one Flutter floor', () {
      final declared = {
        for (final package in shipped)
          package: ?constraintOf(package, 'flutter'),
      };

      expect(
        declared,
        isNotEmpty,
        reason: 'no package names Flutter, which cannot be right',
      );
      expect(
        declared.values.toSet(),
        hasLength(1),
        reason:
            'the Dart floor and the Flutter floor have to mean the same '
            'release, and only one of them is checked by pub\n'
            'Declared: $declared',
      );
    });

    test('the toolchain packages agree on one analyzer', () {
      final declared = declaredBy(toolchain, 'analyzer');

      expect(
        declared.values.toSet(),
        hasLength(1),
        reason:
            'these three share an IR and a plugin protocol, and every package '
            'that reads the analyzer pins it exactly — so a constraint that '
            'drifts here does not widen what resolves, it picks a different '
            'analyzer for one of them and the three stop agreeing about what '
            'a declaration means.\n'
            'Declared: $declared',
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
