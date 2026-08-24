import 'package:alloy/alloy.dart';
import 'package:teardown/teardown.dart';
import 'package:test/test.dart';

void main() {
  late Trace trace;

  setUp(() => trace = Trace());

  group('order', () {
    test('is LIFO by creation, not by declaration', () async {
      final app = await AlloyApplication.start(root: CleanScope(trace));
      // Cache is registered before Database but built first, and building it
      // is what creates Database. Creation order therefore inverts the
      // declaration order — which is the case get_it gets wrong.
      app.get<Cache>();

      await app.dispose();

      expect(trace.entries, [
        'database opened',
        'cache filled',
        'cache dropped',
        'database closed',
      ]);
    });

    test('nothing is disposed for a lazy singleton nobody resolved', () async {
      final app = await AlloyApplication.start(root: CleanScope(trace));

      await app.dispose();

      expect(
        trace.entries,
        isEmpty,
        reason: 'never built, so nothing to close',
      );
    });

    test('async disposal is awaited before the scope is done', () async {
      final app = await AlloyApplication.start(root: CleanScope(trace));
      app.get<Uploader>();

      await app.dispose();

      expect(trace.entries, contains('uploader drained'));
    });
  });

  group('adoption', () {
    test('ties a non-dependency to the scope', () async {
      final app = await AlloyApplication.start(root: CleanScope(trace));
      app.adopt(TempDirectory(trace));

      await app.dispose();

      expect(trace.entries, ['temp directory removed']);
    });
  });

  group('best-effort teardown', () {
    test('a failing dispose does not stop the others', () async {
      final app = await AlloyApplication.start(root: BrokenScope(trace));

      await expectLater(
        app.dispose(timeout: const Duration(milliseconds: 100)),
        throwsA(isA<AlloyDisposeError>()),
      );

      expect(
        trace.entries,
        contains('database closed'),
        reason:
            'the database was registered first, so it is disposed last — '
            'after both broken services',
      );
    });

    test('the error names what failed and what timed out', () async {
      final app = await AlloyApplication.start(root: BrokenScope(trace));

      try {
        await app.dispose(timeout: const Duration(milliseconds: 100));
        fail('expected AlloyDisposeError');
      } on AlloyDisposeError catch (error) {
        expect(error.failures, hasLength(2));
        expect(error.hasTimeout, isTrue);
        expect(error.failures.where((f) => f.isTimeout), hasLength(1));
      }
    });

    test('the scope reaches disposed even so', () async {
      final app = await AlloyApplication.start(root: BrokenScope(trace));

      await app
          .dispose(timeout: const Duration(milliseconds: 100))
          .catchError((Object _) {});

      expect(app.state, AlloyScopeState.disposed);
    });
  });
}
