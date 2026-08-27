import 'package:alloy/alloy.dart';
import 'package:test/test.dart';

final class _Collecting implements AlloyLogSink {
  final records = <AlloyLogRecord>[];

  @override
  void write(AlloyLogRecord record) => records.add(record);
}

class Marker {}

final class _Fn implements AlloyFactory<Marker> {
  const _Fn();

  @override
  Marker create(AlloyResolver resolver) => Marker();
}

void main() {
  /// `minimumLevel` is a documented parameter of the observer people are told
  /// to reach for first, and a mutation that ignored it passed every test in
  /// this package. These pin it.
  group('the level a log observer keeps', () {
    test('drops anything quieter than the minimum', () {
      final sink = _Collecting();
      final scope = AlloyScope.root(
        name: 'app',
        observers: [
          AlloyLogObserver(sink, minimumLevel: AlloyLogLevel.warning),
        ],
      )..registerLazySingleton<Marker>(const _Fn());
      addTearDown(scope.dispose);

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
      final scope = AlloyScope.root(
        name: 'app',
        observers: [AlloyLogObserver(sink, minimumLevel: AlloyLogLevel.debug)],
      );
      addTearDown(scope.dispose);

      scope.push('session');

      expect(sink.records.map((record) => record.kind), [
        AlloyEventKind.scopePushed,
      ]);
    });

    test('the default keeps per-instance records out', () {
      final sink = _Collecting();
      final scope = AlloyScope.root(
        name: 'app',
        observers: [AlloyLogObserver(sink)],
      )..registerLazySingleton<Marker>(const _Fn());
      addTearDown(scope.dispose);

      scope.get<Marker>();

      expect(
        sink.records.where(
          (record) => record.kind == AlloyEventKind.instanceCreated,
        ),
        isEmpty,
        reason:
            'the documented reason for the default: a large graph builds '
            'a great many of them',
      );
    });

    test('trace lets everything through', () {
      final sink = _Collecting();
      final scope = AlloyScope.root(
        name: 'app',
        observers: [AlloyLogObserver(sink, minimumLevel: AlloyLogLevel.trace)],
      )..registerLazySingleton<Marker>(const _Fn());
      addTearDown(scope.dispose);

      scope.get<Marker>();

      expect(
        sink.records.map((record) => record.kind),
        contains(AlloyEventKind.instanceCreated),
      );
    });
  });
}
