import 'package:cobalt_flutter/cobalt_flutter.dart';
import 'package:cobalt_inspector/cobalt_inspector.dart';
import 'package:cobalt_test/cobalt_test.dart';
import 'package:flutter/material.dart';

class Clock {
  const Clock();
}

class Api {
  Api(this.clock);

  final Clock clock;
}

class Ticket {
  Ticket(this.id);

  final String id;
}

var clocksBuilt = 0;

/// A root with one of every shape the inspector has to render, disposed with
/// the test.
///
/// [clocksBuilt] stays a plain global on purpose: unlike a teardown log it is
/// written synchronously while the test runs, never after it, so resetting it
/// in `setUp` really does isolate.
CobaltScope buildGraph(CobaltInspectorLog log) =>
    cobaltTestRoot(name: 'app', observers: [log])
      ..registerLazySingleton<Clock>(
        FnFactory((_) {
          clocksBuilt++;
          return const Clock();
        }),
      )
      ..registerFactory<Api>(FnFactory((r) => Api(r.get<Clock>())))
      ..registerParamFactory<Ticket, String>(
        FnParamFactory((_, id) => Ticket(id)),
      );

Widget inspectorUnderTest(CobaltScope scope, CobaltInspectorLog log) =>
    MaterialApp(
      home: CobaltInspectorScreen(log: log, scope: scope),
    );

/// Mounts the inspector the way an app does: behind a button that pushes it.
///
/// A pushed route is built by the navigator, which sits *above* the
/// `CobaltScopeProvider` — so a screen that looked the scope up from its own
/// context would find nothing here, and a test that mounted it directly under
/// the provider would never notice.
Widget inspectorBehindAButton(CobaltScope scope, CobaltInspectorLog log) =>
    MaterialApp(
      home: CobaltScopeProvider(
        scope: scope,
        child: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              key: const Key('open-inspector'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => CobaltInspectorScreen(
                    log: log,
                    scope: context.cobaltScope,
                  ),
                ),
              ),
              child: const Text('inspect'),
            ),
          ),
        ),
      ),
    );
