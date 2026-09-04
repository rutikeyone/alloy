import 'package:cobalt/cobalt.dart';
import 'package:cobalt_test/cobalt_test.dart';
import 'package:test/test.dart';

final class _Collecting implements CobaltLogSink {
  final records = <CobaltLogRecord>[];

  @override
  void write(CobaltLogRecord record) => records.add(record);
}

class Marker {}

final class _Fn implements CobaltFactory<Marker> {
  const _Fn();

  @override
  Marker create(CobaltResolver resolver) => Marker();
}

void main() {
  /// `minimumLevel` is a documented parameter of the observer people are told
  /// to reach for first, and a mutation that ignored it passed every test in
  /// this package. These pin it.
  group('the level a log observer keeps', () {
    test('drops anything quieter than the minimum', () {
      final sink = _Collecting();
      final scope = cobaltTestRoot(
        name: 'app',
        observers: [
          CobaltLogObserver(sink, minimumLevel: CobaltLogLevel.warning),
        ],
      )..registerLazySingleton<Marker>(const _Fn());

      scope
        ..push('session')
        ..get<Marker>();

      expect(
        sink.records,
        isEmpty,
        reason: 'a push is debug and an instance is trace; both are quieter',
      );
    });

    test('keeps what sits at the minimum', () {
      final sink = _Collecting();
      final scope = cobaltTestRoot(
        name: 'app',
        observers: [
          CobaltLogObserver(sink, minimumLevel: CobaltLogLevel.debug),
        ],
      );

      scope.push('session');

      expect(sink.records.map((record) => record.kind), [
        CobaltEventKind.scopePushed,
      ]);
    });

    test('the default keeps per-instance records out', () {
      final sink = _Collecting();
      final scope = cobaltTestRoot(
        name: 'app',
        observers: [CobaltLogObserver(sink)],
      )..registerLazySingleton<Marker>(const _Fn());

      scope.get<Marker>();

      expect(
        sink.records.where(
          (record) => record.kind == CobaltEventKind.instanceCreated,
        ),
        isEmpty,
        reason:
            'the documented reason for the default: a large graph builds '
            'a great many of them',
      );
    });

    test('trace lets everything through', () {
      final sink = _Collecting();
      final scope = cobaltTestRoot(
        name: 'app',
        observers: [
          CobaltLogObserver(sink, minimumLevel: CobaltLogLevel.trace),
        ],
      )..registerLazySingleton<Marker>(const _Fn());

      scope.get<Marker>();

      expect(
        sink.records.map((record) => record.kind),
        contains(CobaltEventKind.instanceCreated),
      );
    });
  });
}
