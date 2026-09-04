import 'package:cobalt/cobalt.dart';
import 'package:cobalt_test/cobalt_test.dart';
import 'package:test/test.dart';

import 'support.dart';

CobaltLogRecord record(
  CobaltLogLevel level,
  String message, {
  Object? error,
  CobaltEventKind kind = CobaltEventKind.scopePushed,
}) => CobaltLogRecord(kind: kind, level: level, message: message, error: error);

final class BrokenSink implements CobaltLogSink {
  const BrokenSink();

  @override
  void write(CobaltLogRecord record) => throw StateError('sink is down');
}

void main() {
  setUp(resetLogs);

  group('CobaltLogSink.from', () {
    test('reaches any logger without a class or a package', () {
      final seen = <String>[];
      final sink = CobaltLogSink.from((r) => seen.add(r.message));

      sink.write(record(CobaltLogLevel.info, 'hello'));

      expect(seen, ['hello']);
    });

    test('drives a real graph', () async {
      final seen = <String>[];
      final root = cobaltTestRoot(
        name: 'app',
        observers: [
          CobaltLogObserver(CobaltLogSink.from((r) => seen.add(r.message))),
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
      CobaltLogRecord? captured;
      final root = cobaltTestRoot(
        name: 'app',
        observers: [
          CobaltLogObserver(
            CobaltLogSink.from((r) => captured = r),
            minimumLevel: CobaltLogLevel.trace,
          ),
        ],
      )..registerLazySingleton<Logger>(const LoggerFactory());

      root.get<Logger>();

      expect(captured!.key, const CobaltKey(Logger));
      expect(captured!.scope!.name, 'app');
      expect(captured!.level, CobaltLogLevel.trace);
    });
  });

  group('CobaltMultiSink', () {
    test('every sink gets every record', () {
      final first = <String>[];
      final second = <String>[];
      final sink = CobaltMultiSink([
        CobaltLogSink.from((r) => first.add(r.message)),
        CobaltLogSink.from((r) => second.add(r.message)),
      ]);

      sink.write(record(CobaltLogLevel.info, 'hello'));

      expect(first, ['hello']);
      expect(second, ['hello']);
    });

    test('one broken sink does not silence the rest', () {
      final survived = <String>[];
      final sink = CobaltMultiSink([
        const BrokenSink(),
        CobaltLogSink.from((r) => survived.add(r.message)),
        const BrokenSink(),
      ]);

      expect(
        () => sink.write(record(CobaltLogLevel.error, 'still here')),
        returnsNormally,
      );
      expect(survived, ['still here']);
    });

    test('an empty fan-out is harmless', () {
      expect(
        () => const CobaltMultiSink([]).write(record(CobaltLogLevel.info, 'x')),
        returnsNormally,
      );
    });
  });

  group('CobaltPrintLogSink', () {
    test('writes the level and the message', () {
      final lines = <String>[];
      runZonedPrint(lines, () {
        const CobaltPrintLogSink().write(
          record(CobaltLogLevel.warning, 'careful'),
        );
      });

      expect(lines.single, '[cobalt] WARNING careful');
    });

    test('an error is appended and its stack trace follows', () {
      final lines = <String>[];
      runZonedPrint(lines, () {
        const CobaltPrintLogSink(prefix: 'di').write(
          CobaltLogRecord(
            kind: CobaltEventKind.scopeInitFailed,
            level: CobaltLogLevel.error,
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
