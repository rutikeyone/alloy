import 'package:flutter_test/flutter_test.dart';

/// Pumps twice, which is what a starting graph needs.
///
/// `pumpAndSettle` is the obvious call and the wrong one: it pumps until no
/// frame is scheduled, so an indefinite animation — a `CircularProgressIndicator`
/// in a `loading` builder, for one — hangs the test until it times out.
///
/// Two pumps rather than one because `AlloyScopeWidget` and `AlloyAppScope`
/// publish the scope only after `init()` completes: the first frame is the
/// loading one, the graph is published during it, and the second frame is the
/// first that has anything to find. Nesting scopes costs a call each — an outer
/// flow publishes, and only then does the inner one mount.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}
