import 'dart:async';

import 'package:alloy/alloy.dart';

/// Records the order things were torn down in.
///
/// **The log belongs to the recorder, not to the library.** Teardown is not
/// awaited by the widget layer, so a scope from one test can finish releasing
/// while the next one runs — a global list turns that into a failure in the
/// wrong test, and the four hand-written copies of this in this repository got
/// it wrong three times.
class DisposeRecorder {
  /// Creates a recorder with an empty log.
  DisposeRecorder();

  final _entries = <String>[];

  /// What has been disposed so far, in order.
  List<String> get entries => List.unmodifiable(_entries);

  /// A disposable that records [label] when it is closed.
  Disposable value(String label) => _Recorded(label, _entries.add);

  /// A disposable that records [label] after an await, like real I/O.
  AsyncDisposable asyncValue(String label) =>
      _RecordedAsync(label, _entries.add);

  /// A factory registering a [value] under [label].
  AlloyFactory<Disposable> factory(String label) =>
      _RecordedFactory(label, _entries.add);

  /// Forgets everything recorded so far.
  void clear() => _entries.clear();
}

class _Recorded implements Disposable {
  _Recorded(this.label, this.record);

  final String label;
  final void Function(String) record;

  @override
  void dispose() => record(label);
}

class _RecordedAsync implements AsyncDisposable {
  _RecordedAsync(this.label, this.record);

  final String label;
  final void Function(String) record;

  @override
  Future<void> dispose() async {
    await Future<void>.delayed(Duration.zero);
    record(label);
  }
}

class _RecordedFactory implements AlloyFactory<Disposable> {
  const _RecordedFactory(this.label, this.record);

  final String label;
  final void Function(String) record;

  @override
  Disposable create(AlloyResolver resolver) => _Recorded(label, record);
}
