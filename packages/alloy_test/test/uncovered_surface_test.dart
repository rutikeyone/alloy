import 'package:alloy/alloy.dart';
import 'package:alloy_test/alloy_test.dart';
import 'package:test/test.dart';

class Ticket {
  const Ticket(this.id);

  final String id;
}

class Closes implements AsyncDisposable {
  Closes(this._record);

  final void Function() _record;

  @override
  Future<void> dispose() async {
    await Future<void>.delayed(Duration.zero);
    _record();
  }
}

final class _AngryParam implements AlloyParamFactory<Ticket, String> {
  const _AngryParam();

  @override
  Ticket create(AlloyResolver resolver, String param) =>
      throw StateError('no ticket for $param');
}

final class _ClosingTransient implements AlloyFactory<Closes> {
  const _ClosingTransient(this.record);

  final void Function() record;

  @override
  Closes create(AlloyResolver resolver) => Closes(record);
}

void main() {
  /// Everything here was reachable public API of the package people call, with
  /// no test running it — found by measuring rather than by reading.
  group('checkGraph', () {
    test('a sample value whose factory throws is a failure, named', () async {
      final scope = alloyTestRoot(name: 'app')
        ..registerParamFactory<Ticket, String>(const _AngryParam());

      final report = await checkGraph(
        scope,
        params: {const AlloyKey(Ticket): 'A7'},
      );

      expect(report.isComplete, isFalse);
      expect(report.failures.single.key.type, Ticket);
      expect('${report.failures.single}', contains('no ticket for A7'));
    });

    test(
      'awaits an async disposable it built rather than dropping it',
      () async {
        var closed = 0;
        final scope = alloyTestRoot(name: 'app')
          ..registerFactory<Closes>(_ClosingTransient(() => closed++));

        final report = await checkGraph(scope);

        expect(report.isComplete, isTrue);
        expect(
          closed,
          1,
          reason:
              'the check builds transients the scope does not retain, so it '
              'has to release them itself — and wait for an async one',
        );
      },
    );

    test('names a parameterized registration it could not try', () async {
      final scope = alloyTestRoot(name: 'app')
        ..registerParamFactory<Ticket, String>(const _AngryParam());

      final report = await checkGraph(scope);

      expect(report.unchecked.single.key.type, Ticket);
      expect(
        '${report.unchecked.single}',
        allOf(contains('Ticket'), contains('not checked')),
        reason: 'listed by name rather than skipped in silence',
      );
    });
  });

  group('the fixtures', () {
    test('an async recorded value reports after its await', () async {
      final recorder = DisposeRecorder();
      final scope = alloyTestRoot(name: 'app')
        ..registerSingleton<AsyncDisposable>(recorder.asyncValue('slow'))
        ..registerSingleton<Disposable>(recorder.value('quick'));

      await scope.dispose();

      expect(
        recorder.entries,
        ['quick', 'slow'],
        reason: 'newest first, and the async one is awaited rather than raced',
      );
    });

    test('a recorder forgets on clear', () async {
      final recorder = DisposeRecorder();
      final scope = alloyTestRoot(name: 'app')
        ..registerSingleton<Disposable>(recorder.value('one'));
      await scope.dispose();
      expect(recorder.entries, ['one']);

      recorder.clear();

      expect(recorder.entries, isEmpty);
    });

    test('an observer hands back its records, and forgets on clear', () {
      final observer = CapturingObserver();
      alloyTestRoot(name: 'app', observers: [observer]).push('session');

      expect(observer.records.single.kind, AlloyEventKind.scopePushed);
      expect(
        () => observer.records.add(observer.records.single),
        throwsUnsupportedError,
        reason: 'the list handed out is a view, not the log itself',
      );

      observer.clear();

      expect(observer.records, isEmpty);
      expect(observer.saw(AlloyEventKind.scopePushed), isFalse);
    });
  });
}
