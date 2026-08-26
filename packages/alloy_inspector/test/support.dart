import 'package:alloy_flutter/alloy_flutter.dart';
import 'package:alloy_inspector/alloy_inspector.dart';
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

final class ClockFactory implements AlloyFactory<Clock> {
  const ClockFactory();

  @override
  Clock create(AlloyResolver resolver) {
    clocksBuilt++;
    return const Clock();
  }
}

final class ApiFactory implements AlloyFactory<Api> {
  const ApiFactory();

  @override
  Api create(AlloyResolver resolver) => Api(resolver.get<Clock>());
}

final class TicketFactory implements AlloyParamFactory<Ticket, String> {
  const TicketFactory();

  @override
  Ticket create(AlloyResolver resolver, String param) => Ticket(param);
}

/// A root with one of every shape the inspector has to render.
AlloyScope buildGraph(AlloyInspectorLog log) =>
    AlloyScope.root(name: 'app', observers: [log])
      ..registerLazySingleton<Clock>(const ClockFactory())
      ..registerFactory<Api>(const ApiFactory())
      ..registerParamFactory<Ticket, String>(const TicketFactory());

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
