import 'dart:io';

import 'package:package_config/package_config.dart';

/// Every `lib/**.dart` of [package], keyed the way `testBuilder` wants them.
///
/// A package config alone is not enough. It tells the resolver where a package
/// lives, and the in-memory reader still has nothing to read: the import
/// resolves to no library, the annotation is left with no element, every
/// matcher answers "not annotated", and the build finishes empty — with no
/// warning and no error. That trap has cost time twice in this repository, so
/// it is written down rather than worked around, and every test here asserts
/// on content so an empty build cannot read as a pass.
Map<String, Object> sourcesOf(PackageConfig packages, String package) {
  final root = packages[package]!.packageUriRoot.toFilePath();
  final sources = <String, Object>{};
  for (final file in Directory(root).listSync(recursive: true)) {
    if (file is! File || !file.path.endsWith('.dart')) continue;
    sources['$package|lib/${file.path.substring(root.length)}'] = file
        .readAsStringSync();
  }
  return sources;
}
