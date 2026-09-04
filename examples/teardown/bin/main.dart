import 'package:cobalt/cobalt.dart';
import 'package:teardown/teardown.dart';

/// The output of this program is the lesson. Run it:
///
/// ```
/// dart run bin/main.dart
/// ```
Future<void> main() async {
  await _cleanTeardown();
  await _brokenTeardown();
}

Future<void> _cleanTeardown() async {
  final trace = Trace();
  final app = await CobaltApplication.start(
    root: CleanScope(trace),
    rootName: 'app',
  );

  // Resolve in an order that has nothing to do with how they were registered:
  // Cache is built first and pulls Database in behind it.
  app.get<Cache>();
  app.get<Uploader>();

  // Not a dependency — nobody will ever resolve it — but its life is the
  // scope's all the same.
  app.adopt(TempDirectory(trace));

  await app.dispose();

  print('clean teardown');
  print(trace);
  print(
    '\nNote the order: cache before database, though Database was registered\n'
    'last. Teardown is LIFO by *creation*, and Cache was created first — it is\n'
    'what pulled Database into existence.\n',
  );
}

Future<void> _brokenTeardown() async {
  final trace = Trace();
  final app = await CobaltApplication.start(
    root: BrokenScope(trace),
    rootName: 'app',
  );

  try {
    // The deadline is per-teardown, not per-service, and it is short here only
    // so the stuck watcher does not hold the program up.
    await app.dispose(timeout: const Duration(milliseconds: 100));
    print('broken teardown: no error — unexpected');
  } on CobaltDisposeError catch (error) {
    print('broken teardown');
    print(trace);
    final timeouts = error.failures.where((f) => f.isTimeout).length;
    print('\nfailures: ${error.failures.length}, of them timeouts: $timeouts');
    print('hasTimeout: ${error.hasTimeout}');
    print(
      '\nThe socket threw and the watcher hung, yet the database still closed.\n'
      'Teardown is best-effort under one deadline: a broken step is recorded,\n'
      'never allowed to abort the rest.',
    );
  }
}
