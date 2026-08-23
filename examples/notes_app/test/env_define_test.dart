import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/app/app_startup.dart';
import 'package:notes_app/bootstrap/boot_log.dart';
import 'package:notes_app/features/environments/data/live_api_client.dart';
import 'package:notes_app/features/environments/domain/api_client.dart';

void main() {
  setUp(BootLog.reset);

  test(
    '--dart-define picks the environment at compile time',
    () async {
      expect(notesEnvironment.name, 'prod');

      final app = await startNotesApp();
      addTearDown(app.dispose);

      expect(app.get<ApiClient>(), isA<LiveApiClient>());
      expect(BootLog.steps, contains('report-crashes'));
    },
    skip: notesEnvironment.name == 'prod'
        ? null
        : 'compile-time only: flutter test --dart-define=NOTES_ENV=prod',
  );
}
