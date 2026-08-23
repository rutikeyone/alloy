import 'package:alloy_flutter/alloy_flutter.dart';
import 'package:alloy_talker/alloy_talker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging_example/app/app_scope.dart';
import 'package:logging_example/app/logging_app.dart';
import 'package:talker/talker.dart';

void main() {
  late Talker talker;
  late AlloyScope app;

  setUp(() => talker = Talker());

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(LoggingApp(talker: talker));
    await settle(tester);
    await settle(tester);
    // Below MaterialApp now: AlloyAppScope.builder publishes the scope inside
    // it, so loading and error screens are rendered with the app's theme.
    app = AlloyScopeProvider.of(tester.element(find.byType(Navigator).first));
  }

  List<String> titles() => [
    for (final data in talker.history) data.title ?? '',
  ];
  String messages() =>
      [for (final data in talker.history) data.message].join('\n');

  group('startup reports itself', () {
    test('the bootstrap step and the init graph are both in the log', () async {
      final scope = await AlloyApplication.start(
        root: const AppScope(),
        bootstrap: [WarmUp()],
        rootName: 'app',
        observers: [AlloyTalkerObserver(talker, verbose: true)],
      );
      addTearDown(scope.dispose);

      expect(titles(), contains('alloy-startup'));
      expect(
        messages(),
        allOf(
          contains('bootstrap "warm-up" started'),
          contains('bootstrap "warm-up" done'),
          contains('scope "app" ready'),
        ),
      );
    });
  });

  group('opening a session', () {
    testWidgets('reports the push and what it built', (tester) async {
      await pumpApp(tester);

      await tester.tap(find.byKey(const Key('open-session')));
      await settle(tester);

      expect(messages(), contains('scope "app/session" pushed'));
      expect(titles(), contains('alloy-instance'));
      expect(app.children.single.name, 'session');
    });

    testWidgets('closing it reports the teardown', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.byKey(const Key('open-session')));
      await settle(tester);

      await tester.tap(find.byKey(const Key('close-session')));
      await settle(tester);

      expect(messages(), contains('scope "app/session" disposing'));
      expect(app.children, isEmpty);
    });
  });

  group('a teardown that fails', () {
    testWidgets('shows up as a failure entry, not as silence', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.byKey(const Key('open-broken-session')));
      await settle(tester);

      await tester.tap(find.byKey(const Key('close-session')));
      await settle(tester);

      expect(titles(), contains('alloy-failure'));
      expect(
        messages(),
        contains('could not release StubbornResource.dispose'),
      );
    });
  });
}
