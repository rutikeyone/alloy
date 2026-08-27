import 'package:alloy_flutter/alloy_flutter.dart';
import 'package:alloy_inspector/alloy_inspector.dart';
import 'package:alloy_test/alloy_test.dart';
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
AlloyScope buildGraph(AlloyInspectorLog log) =>
    alloyTestRoot(name: 'app', observers: [log])
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

Widget inspectorUnderTest(AlloyScope scope, AlloyInspectorLog log) =>
    MaterialApp(
      home: AlloyInspectorScreen(log: log, scope: scope),
    );

/// Mounts the inspector the way an app does: behind a button that pushes it.
///
/// A pushed route is built by the navigator, which sits *above* the
/// `AlloyScopeProvider` — so a screen that looked the scope up from its own
/// context would find nothing here, and a test that mounted it directly under
/// the provider would never notice.
Widget inspectorBehindAButton(AlloyScope scope, AlloyInspectorLog log) =>
    MaterialApp(
      home: AlloyScopeProvider(
        scope: scope,
        child: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              key: const Key('open-inspector'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      AlloyInspectorScreen(log: log, scope: context.alloyScope),
                ),
              ),
              child: const Text('inspect'),
            ),
          ),
        ),
      ),
    );
