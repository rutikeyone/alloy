import 'dart:async';

import 'package:cobalt/cobalt.dart';
import 'package:cobalt_test/cobalt_test.dart';
import 'package:test/test.dart';

import 'support.dart';

/// A type Cobalt cannot recognise: it closes, but says so in its own vocabulary
/// rather than through [Disposable]. Every third-party client looks like this.
class Connection {
  Connection(this.label) : _recorder = recorder;

  final String label;

  final DisposeRecorder _recorder;
  var isOpen = true;

  void close() {
    isOpen = false;
    _recorder.record(label);
  }
}

class ConnectionFactory implements CobaltFactory<Connection> {
  const ConnectionFactory(this.label);

  final String label;

  @override
  Connection create(CobaltResolver resolver) => Connection(label);
}

class SlowConnectionFactory implements CobaltAsyncFactory<Connection> {
  const SlowConnectionFactory(this.label);

  final String label;

  @override
  Future<Connection> create(CobaltResolver resolver) async {
    await Future<void>.delayed(Duration.zero);
    return Connection(label);
  }
}

void main() {
  setUp(resetLogs);

  group('a registration that says how to close itself', () {
    test('is closed with the scope', () async {
      final scope = cobaltTestRoot()
        ..registerLazySingleton<Connection>(
          const ConnectionFactory('db'),
          dispose: (connection) => connection.close(),
        );

      final connection = scope.get<Connection>();
      expect(connection.isOpen, isTrue);

      await scope.dispose();

      expect(connection.isOpen, isFalse);
      expect(recorder.entries, ['db']);
    });

    test('receives the instance the scope built, not a copy', () async {
      Connection? closed;
      final scope = cobaltTestRoot()
        ..registerLazySingleton<Connection>(
          const ConnectionFactory('db'),
          dispose: (connection) => closed = connection,
        );

      final resolved = scope.get<Connection>();
      await scope.dispose();

      expect(identical(closed, resolved), isTrue);
    });

    test('is not called when nothing ever resolved it', () async {
      final scope = cobaltTestRoot()
        ..registerLazySingleton<Connection>(
          const ConnectionFactory('db'),
          dispose: (connection) => connection.close(),
        );

      await scope.dispose();

      expect(recorder.entries, isEmpty);
    });

    test('an eager singleton is closed too', () async {
      final connection = Connection('eager');
      final scope = cobaltTestRoot()
        ..registerSingleton<Connection>(
          connection,
          dispose: (it) => it.close(),
        );

      await scope.dispose();

      expect(connection.isOpen, isFalse);
    });

    test('an async singleton is closed too', () async {
      final scope = cobaltTestRoot()
        ..registerAsyncSingleton<Connection>(
          const SlowConnectionFactory('async'),
          dispose: (connection) => connection.close(),
        );
      await scope.init();

      await scope.dispose();

      expect(recorder.entries, ['async']);
    });

    test('an asynchronous close is awaited before teardown moves on', () async {
      final scope = cobaltTestRoot()
        ..registerLazySingleton<Connection>(
          const ConnectionFactory('slow'),
          dispose: (connection) async {
            await Future<void>.delayed(const Duration(milliseconds: 20));
            connection.close();
          },
        )
        ..registerLazySingleton<Logger>(const LoggerFactory());

      scope
        ..get<Logger>()
        ..get<Connection>();

      await scope.dispose();

      expect(recorder.entries, ['slow', 'Logger']);
    });
  });

  group('ordering and failure', () {
    test('closes in reverse creation order, mixed with Disposable', () async {
      final scope = cobaltTestRoot()
        ..registerLazySingleton<Logger>(const LoggerFactory())
        ..registerLazySingleton<Connection>(
          const ConnectionFactory('db'),
          dispose: (connection) => connection.close(),
        );

      // Resolution order, not registration order, is what teardown reverses.
      scope
        ..get<Connection>()
        ..get<Logger>();

      await scope.dispose();

      expect(recorder.entries, ['Logger', 'db']);
    });

    test('a close that throws is recorded and the rest still run', () async {
      final scope = cobaltTestRoot()
        ..registerLazySingleton<Logger>(const LoggerFactory())
        ..registerLazySingleton<Connection>(
          const ConnectionFactory('db'),
          dispose: (_) => throw StateError('db refused to close'),
        );

      scope
        ..get<Logger>()
        ..get<Connection>();

      await expectLater(
        scope.dispose(),
        throwsA(
          isA<CobaltDisposeError>().having(
            (e) => e.failures.single.label,
            'label',
            'Connection.dispose',
          ),
        ),
      );

      expect(recorder.entries, ['Logger']);
    });
  });

  group('adopt', () {
    test('retains an unrecognised object once told how to close it', () async {
      final connection = Connection('adopted');
      final scope = cobaltTestRoot()
        ..adopt(connection, dispose: (it) => it.close());

      await scope.dispose();

      expect(connection.isOpen, isFalse);
    });

    test('still ignores one it cannot close', () async {
      final connection = Connection('ignored');
      final scope = cobaltTestRoot()..adopt(connection);

      await scope.dispose();

      expect(connection.isOpen, isTrue);
      expect(recorder.entries, isEmpty);
    });
  });
}
