import 'package:alloy/alloy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/app/app_startup.dart';
import 'package:notes_app/bootstrap/boot_log.dart';
import 'package:notes_app/core/event_log.dart';
import 'package:notes_app/features/environments/data/fake_api_client.dart';
import 'package:notes_app/features/environments/data/live_api_client.dart';
import 'package:notes_app/features/environments/domain/api_client.dart';

import 'support.dart';

void main() {
  setUp(BootLog.reset);

  Future<AlloyScope> start(AlloyEnvironment environment) async {
    final app = await startNotesGraph(environment: environment);
    return app;
  }

  group('the environment this build was compiled for', () {
    test('defaults to dev when no --dart-define was given', () {
      expect(notesEnvironment, AlloyEnvironment.dev);
    });
  });

  group('one interface, a different class per environment', () {
    test('dev gets the fake', () async {
      final app = await start(AlloyEnvironment.dev);

      expect(app.get<ApiClient>(), isA<FakeApiClient>());
    });

    test('test gets the fake too — both names are on the same class', () async {
      final app = await start(AlloyEnvironment.test);

      expect(app.get<ApiClient>(), isA<FakeApiClient>());
    });

    test('prod and stage get the live one', () async {
      expect(
        (await start(AlloyEnvironment.prod)).get<ApiClient>(),
        isA<LiveApiClient>(),
      );
      expect(
        (await start(AlloyEnvironment.stage)).get<ApiClient>(),
        isA<LiveApiClient>(),
      );
    });

    test('the choice is invisible downstream', () async {
      final fake = await start(AlloyEnvironment.dev);
      final live = await start(AlloyEnvironment.prod);

      expect(await fake.get<ApiClient>().fetchHeadlines(), isNotEmpty);
      expect(await live.get<ApiClient>().fetchHeadlines(), isNotEmpty);
    });

    test('starting without a choice leaves the split types out', () async {
      final app = await start(AlloyEnvironment.defaultEnvironment);

      expect(app.get<EventLog>().entries, isNotEmpty);
      expect(
        () => app.get<ApiClient>(),
        throwsA(isA<AlloyError>()),
        reason: 'forgetting to choose fails loudly, not with the wrong class',
      );
    });

    test('an environment nobody claims leaves the type unregistered', () async {
      final app = await start(const AlloyEnvironment('canary'));

      expect(() => app.get<ApiClient>(), throwsA(isA<AlloyError>()));
    });

    test('unrestricted registrations survive every environment', () async {
      for (final environment in const [
        AlloyEnvironment.dev,
        AlloyEnvironment.prod,
        AlloyEnvironment('canary'),
      ]) {
        final app = await start(environment);
        expect(app.get<EventLog>().entries, isNotEmpty);
      }
    });
  });

  group('bootstrap steps take environments too', () {
    test('the prod-only step runs in prod', () async {
      await start(AlloyEnvironment.prod);

      expect(BootLog.steps, contains('report-crashes'));
    });

    test('and is skipped in dev', () async {
      await start(AlloyEnvironment.dev);

      expect(BootLog.steps, isNot(contains('report-crashes')));
      expect(BootLog.steps, contains('bind-platform'));
    });

    test('order still decides when it runs', () async {
      await start(AlloyEnvironment.stage);

      expect(BootLog.steps.last, 'report-crashes');
    });
  });
}
