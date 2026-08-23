import 'package:alloy/alloy.dart';
import 'package:notes_app/alloy.g.dart';
import 'package:notes_app/features/session/session_manager.dart';

const _requestedEnvironment = String.fromEnvironment('NOTES_ENV');

/// The environment this build was compiled for.
///
/// `flutter run --dart-define=NOTES_ENV=prod` picks another one. It has to be
/// known before the graph is built, which is why it is a compile-time constant
/// and not something a bootstrap step loads.
///
/// The fallback is [AlloyEnvironment.dev] itself rather than the string `dev`:
/// a literal here would be a second place to keep the name right, and getting
/// it wrong would silently select an environment nothing claims.
const notesEnvironment = _requestedEnvironment == ''
    ? AlloyEnvironment.dev
    : AlloyEnvironment(_requestedEnvironment);

Future<AlloyScope> startNotesApp({
  AlloyEnvironment environment = notesEnvironment,
}) async {
  final app = await $startAlloy(environment: environment);
  app
    ..registerSingleton<AlloyEnvironment>(environment)
    ..registerSingleton<SessionManager>(SessionManager(app));
  return app;
}
