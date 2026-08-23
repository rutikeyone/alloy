import 'package:alloy/alloy.dart';
import 'package:alloy_logging/alloy_logging.dart';
import 'package:logging/logging.dart' as logging;
import 'package:test/test.dart';

void main() {
  late List<logging.LogRecord> records;
  late AlloyLoggingSink sink;

  setUp(() {
    records = [];
    logging.hierarchicalLoggingEnabled = true;
    final logger = logging.Logger.detached('alloy-test')
      ..level = logging.Level.ALL;
    logger.onRecord.listen(records.add);
    sink = AlloyLoggingSink(logger: logger);
  });

  group('AlloyLoggingSink', () {
    test('every Alloy level maps onto a logging one', () {
      expect(
        AlloyLoggingSink.levelOf(AlloyLogLevel.trace),
        logging.Level.FINEST,
      );
      expect(AlloyLoggingSink.levelOf(AlloyLogLevel.debug), logging.Level.FINE);
      expect(AlloyLoggingSink.levelOf(AlloyLogLevel.info), logging.Level.INFO);
      expect(
        AlloyLoggingSink.levelOf(AlloyLogLevel.warning),
        logging.Level.WARNING,
      );
      expect(
        AlloyLoggingSink.levelOf(AlloyLogLevel.error),
        logging.Level.SEVERE,
      );
    });

    test('a record reaches the logger with its error attached', () {
      final boom = StateError('boom');
      sink.write(
        AlloyLogRecord(
          level: AlloyLogLevel.error,
          message: 'it broke',
          error: boom,
          stackTrace: StackTrace.empty,
        ),
      );

      expect(records.single.message, 'it broke');
      expect(records.single.level, logging.Level.SEVERE);
      expect(records.single.error, same(boom));
    });

    test('the graph drives it end to end', () async {
      final root = AlloyScope.root(
        name: 'app',
        observers: [AlloyLogObserver(sink)],
      );
      root.push('session');
      await root.dispose();

      expect(
        records.map((r) => r.message),
        containsAllInOrder(<String>[
          'scope "app/session" pushed',
          'scope "app/session" disposing',
        ]),
      );
    });

    test('minimumLevel keeps per-instance noise out by default', () {
      final root = AlloyScope.root(
        name: 'app',
        observers: [AlloyLogObserver(sink)],
      )..registerLazySingleton<Object>(const _MarkerFactory());
      addTearDown(root.dispose);

      root.get<Object>();

      expect(records.where((r) => r.message.startsWith('built')), isEmpty);
    });

    test('lowering minimumLevel lets them through', () {
      final root = AlloyScope.root(
        name: 'app',
        observers: [AlloyLogObserver(sink, minimumLevel: AlloyLogLevel.trace)],
      )..registerLazySingleton<Object>(const _MarkerFactory());
      addTearDown(root.dispose);

      root.get<Object>();

      expect(records.map((r) => r.message), contains(startsWith('built')));
    });
  });
}

final class _MarkerFactory implements AlloyFactory<Object> {
  const _MarkerFactory();

  @override
  Object create(AlloyResolver resolver) => Object();
}
