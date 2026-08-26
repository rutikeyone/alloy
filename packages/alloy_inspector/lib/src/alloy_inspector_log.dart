import 'dart:async';

import 'package:alloy_flutter/alloy_flutter.dart';
import 'package:flutter/foundation.dart';

/// Collects what the graph reports, for the inspector screens to read.
///
/// Pass it where the graph is built — observers are fixed when a scope is
/// constructed and handed down to its children, so this cannot be attached
/// later, when a screen opens:
///
/// ```dart
/// final log = AlloyInspectorLog();
/// final scope = await AlloyApplication.start(
///   root: const AppScope(),
///   observers: [log],
/// );
/// ```
///
/// It is also the only change signal the tree screen has. A scope is not a
/// [Listenable] and pushing a child notifies nothing, so a view over the live
/// tree repaints when this says something moved.
final class AlloyInspectorLog extends AlloyRecordingObserver
    with ChangeNotifier {
  /// Keeps the last [capacity] records.
  ///
  /// A graph of any size builds a lot of instances, and a screen only ever
  /// shows the recent past. The default is generous enough to cover a whole
  /// startup.
  AlloyInspectorLog({this.capacity = 500})
    : assert(capacity > 0, 'a log of no records watches nothing');

  /// How many records are kept before the oldest is dropped.
  final int capacity;

  final _records = <AlloyLogRecord>[];
  var _disposed = false;

  /// Everything seen, oldest first.
  List<AlloyLogRecord> get records => List.unmodifiable(_records);

  /// Only what was built, oldest first.
  ///
  /// Comes from events rather than from a scope's registrations, because those
  /// answer a different question: `keys` is what was *declared*, and a lazy
  /// singleton nobody resolved looks there exactly like one that is built.
  List<AlloyLogRecord> get created => [
    for (final record in _records)
      if (record.kind == AlloyEventKind.instanceCreated) record,
  ];

  /// The records of one kind, oldest first.
  List<AlloyLogRecord> ofKind(AlloyEventKind kind) => [
    for (final record in _records)
      if (record.kind == kind) record,
  ];

  /// Forgets everything seen so far.
  void clear() {
    _records.clear();
    _notify();
  }

  @override
  void onRecord(AlloyLogRecord record) {
    if (_records.length == capacity) _records.removeAt(0);
    _records.add(record);
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// Notifies after the current turn, never during it.
  ///
  /// Observer callbacks are synchronous and arrive in the middle of the work
  /// they describe — including a teardown that runs while the tree is
  /// building, where a synchronous notification throws
  /// `setState() called during build`.
  ///
  /// Deferring buys that at the cost of a notification outliving its listener:
  /// tearing a scope down emits events, and whoever owns this log usually
  /// disposes it in the same turn. The guard is for exactly that gap.
  void _notify() => scheduleMicrotask(() {
    if (_disposed) return;
    notifyListeners();
  });
}
