import 'dart:async';

import 'package:alloy/alloy.dart';
import 'package:teardown/src/trace.dart';

/// Opened first, closed last — the ordering claim this example exists to show.
class Database implements Disposable {
  Database(this._trace) {
    _trace.add('database opened');
  }

  final Trace _trace;

  @override
  void dispose() => _trace.add('database closed');
}

/// Built after [Database] and torn down before it, because teardown is LIFO by
/// *creation* order rather than by the order registrations were declared in.
class Cache implements Disposable {
  Cache(this._trace, Database _) {
    _trace.add('cache filled');
  }

  final Trace _trace;

  @override
  void dispose() => _trace.add('cache dropped');
}

/// Async disposal is awaited; the scope does not move on without it.
class Uploader implements AsyncDisposable {
  Uploader(this._trace) {
    _trace.add('uploader started');
  }

  final Trace _trace;

  @override
  Future<void> dispose() async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    _trace.add('uploader drained');
  }
}

/// Fails on the way out. Everything else still gets torn down.
class FlakySocket implements Disposable {
  FlakySocket(this._trace) {
    _trace.add('socket connected');
  }

  final Trace _trace;

  @override
  void dispose() {
    _trace.add('socket refused to close');
    throw StateError('socket close failed');
  }
}

/// Never finishes. The global deadline is what stops it from hanging teardown
/// forever — without one, a single stuck resource freezes the whole app exit.
class StuckWatcher implements AsyncDisposable {
  StuckWatcher(this._trace) {
    _trace.add('watcher armed');
  }

  final Trace _trace;

  @override
  Future<void> dispose() {
    _trace.add('watcher hung');
    return Completer<void>().future;
  }
}

/// Not a dependency: nobody resolves it. It is handed to the scope with
/// `adopt` so its lifetime is the scope's anyway.
class TempDirectory implements Disposable {
  TempDirectory(this._trace);

  final Trace _trace;

  @override
  void dispose() => _trace.add('temp directory removed');
}
