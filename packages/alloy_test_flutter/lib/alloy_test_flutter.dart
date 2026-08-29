/// Widget-test helpers for Alloy.
///
/// Separate from [`alloy_test`](https://pub.dev/packages/alloy_test), which is
/// pure Dart on `test_api` and `matcher` so that graph helpers work under
/// `dart test` too. Anything that takes a `WidgetTester` needs `flutter_test`,
/// and Dart has no optional dependencies — so it lives here rather than
/// putting `flutter_test` into every package that only builds a graph.
library;

export 'package:alloy_test_flutter/src/mounted_scope.dart';
export 'package:alloy_test_flutter/src/settle.dart';
