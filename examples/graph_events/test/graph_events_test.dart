import 'package:cobalt_flutter/cobalt_flutter.dart';
import 'package:cobalt_test/cobalt_test.dart';
import 'package:cobalt_talker/cobalt_talker.dart';
import 'package:cobalt_test_flutter/cobalt_test_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graph_events/app/app_scope.dart';
import 'package:graph_events/l10n/graph_events_l10n.dart';
import 'package:graph_events/app/audit_log.dart';
import 'package:graph_events/app/observers.dart';
import 'package:graph_events/app/report_log.dart';
import 'package:graph_events/features/home/ui/home_screen.dart';
import 'package:talker/talker.dart';

void main() {
  late Talker talker;
  late AuditLog audit;
  late ReportLog reports;
  late CobaltScope app;

  setUp(() {
    talker = Talker();
    audit = AuditLog();
    reports = ReportLog();
  });

  Future<void> pumpApp(WidgetTester tester) async {
    // The app widget is gone — the gallery owns that now — so the test mounts
    // the same graph and screen the gallery does.
    await tester.pumpWidget(
      MaterialApp(
        // The example is a library the gallery mounts, so in the running app
        // the delegates are registered there; a test mounting the screen on
        // its own has to supply them itself.
        localizationsDelegates: const [
          GraphEventsL10n.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: GraphEventsL10n.supportedLocales,
        home: CobaltAppScope(
          root: const AppScope(),
          bootstrap: () => [WarmUp()],
          rootName: 'app',
          observers: graphEventsObservers(
            talker: talker,
            audit: audit,
            reports: reports,
          ),
          loading: const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          child: HomeScreen(talker: talker, reports: reports),
        ),
      ),
    );
    await settle(tester);
    await settle(tester);
    // Below MaterialApp now: CobaltAppScope.builder publishes the scope inside
    // it, so loading and error screens are rendered with the app's theme.
    // Below the Navigator now, not above it: the screen is mounted inside a
    // route, so the provider sits with the screen rather than with the app.
    app = CobaltScopeProvider.of(tester.element(find.byType(Scaffold).first));
  }

  List<String> titles() => [
    for (final data in talker.history) data.title ?? '',
  ];
  String messages() =>
      [for (final data in talker.history) data.message].join('\n');

  group('startup reports itself', () {
    test('the bootstrap step and the init graph are both in the log', () async {
      await cobaltTestScope(
        root: const AppScope(),
        bootstrap: [WarmUp()],
        rootName: 'app',
        observers: [CobaltTalkerObserver(talker, verbose: true)],
      );

      expect(titles(), contains('cobalt-startup'));
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

  group('one graph, several destinations', () {
    testWidgets('a sink with no adapter gets the same records', (tester) async {
      await pumpApp(tester);

      expect(
        audit.lines,
        contains(startsWith('info scope "app" ready')),
        reason: 'CobaltLogSink.from is the whole integration — no package',
      );
    });
  });

  group('opening a session', () {
    testWidgets('reports the push and what it built', (tester) async {
      await pumpApp(tester);

      await tester.tap(find.byKey(const Key('open-session')));
      await settle(tester);

      expect(messages(), contains('scope "app/session" pushed'));
      expect(titles(), contains('cobalt-instance'));
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

      expect(titles(), contains('cobalt-failure'));
      expect(
        messages(),
        contains('could not release StubbornResource.dispose'),
      );
    });
  });

  group('failures reach the reporter', () {
    testWidgets('a teardown that throws is reported with its breadcrumbs', (
      tester,
    ) async {
      await pumpApp(tester);

      expect(find.byKey(const Key('no-report')), findsOneWidget);

      await tester.tap(find.byKey(const Key('open-broken-session')));
      await settle(tester);
      await tester.tap(find.byKey(const Key('close-session')));
      await settle(tester);

      expect(reports.reports, hasLength(1));
      final report = reports.reports.single;
      expect(report.failure.kind, CobaltEventKind.scopeDisposeFailed);
      expect(report.error, isA<StateError>());
      expect(
        report.breadcrumbs.map((c) => c.kind),
        contains(CobaltEventKind.scopePushed),
        reason: 'the session being opened is what led to the failure',
      );
      expect(find.byKey(const Key('last-report')), findsOneWidget);
    });

    testWidgets('a session that closes cleanly reports nothing', (
      tester,
    ) async {
      await pumpApp(tester);

      await tester.tap(find.byKey(const Key('open-session')));
      await settle(tester);
      await tester.tap(find.byKey(const Key('close-session')));
      await settle(tester);

      expect(reports.reports, isEmpty);
    });
  });
}
