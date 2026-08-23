import 'package:alloy/alloy.dart';
import 'package:test/test.dart';

import 'support.dart';

AlloyLogRecord record(AlloyLogLevel level, String message, {Object? error}) =>
    AlloyLogRecord(level: level, message: message, error: error);

final class BrokenSink implements AlloyLogSink {
  const BrokenSink();

  @override
  void write(AlloyLogRecord record) => throw StateError('sink is down');
}

void main() {
  setUp(resetLogs);

  group('AlloyLogSink.from', () {
    test('reaches any logger without a class or a package', () {
      final seen = <String>[];
      final sink = AlloyLogSink.from((r) => seen.add(r.message));

      sink.write(record(AlloyLogLevel.info, 'hello'));

      expect(seen, ['hello']);
    });

    test('drives a real graph', () async {
      final seen = <String>[];
      final root = AlloyScope.root(
        name: 'app',
        observers: [
          AlloyLogObserver(AlloyLogSink.from((r) => seen.add(r.message))),
        ],
      );
      root.push('session');
      await root.dispose();

      expect(
        seen,
        containsAllInOrder(<String>[
          'scope "app/session" pushed',
          'scope "app/session" disposing',
        ]),
      );
    });

    test('the record keeps its structure, not just a string', () {
      AlloyLogRecord? captured;
      final root = AlloyScope.root(
        name: 'app',
        observers: [
          AlloyLogObserver(
            AlloyLogSink.from((r) => captured = r),
            minimumLevel: AlloyLogLevel.trace,
          ),
        ],
      )..registerLazySingleton<Logger>(const LoggerFactory());
      addTearDown(root.dispose);

      root.get<Logger>();

      expect(captured!.key, const AlloyKey(Logger));
      expect(captured!.scope!.name, 'app');
      expect(captured!.level, AlloyLogLevel.trace);
    });
  });

  group('AlloyMultiSink', () {
    test('every sink gets every record', () {
      final first = <String>[];
      final second = <String>[];
      final sink = AlloyMultiSink([
        AlloyLogSink.from((r) => first.add(r.message)),
        AlloyLogSink.from((r) => second.add(r.message)),
      ]);

      sink.write(record(AlloyLogLevel.info, 'hello'));

      expect(first, ['hello']);
      expect(second, ['hello']);
    });

    test('one broken sink does not silence the rest', () {
      final survived = <String>[];
      final sink = AlloyMultiSink([
        const BrokenSink(),
        AlloyLogSink.from((r) => survived.add(r.message)),
        const BrokenSink(),
      ]);

      expect(
        () => sink.write(record(AlloyLogLevel.error, 'still here')),
        returnsNormally,
      );
      expect(survived, ['still here']);
    });

    test('an empty fan-out is harmless', () {
      expect(
        () => const AlloyMultiSink([]).write(record(AlloyLogLevel.info, 'x')),
        returnsNormally,
      );
    });
  });

  group('AlloyPrintLogSink', () {
    test('writes the level and the message', () {
      final lines = <String>[];
      runZonedPrint(lines, () {
        const AlloyPrintLogSink().write(
          record(AlloyLogLevel.warning, 'careful'),
        );
      });

      expect(lines.single, '[alloy] WARNING careful');
    });

    test('an error is appended and its stack trace follows', () {
      final lines = <String>[];
      runZonedPrint(lines, () {
        const AlloyPrintLogSink(prefix: 'di').write(
          AlloyLogRecord(
            level: AlloyLogLevel.error,
            message: 'it broke',
            error: StateError('boom'),
            stackTrace: StackTrace.empty,
          ),
        );
      });

      expect(lines.first, startsWith('[di] ERROR it broke: Bad state: boom'));
      expect(lines, hasLength(2));
    });
  });
}
