import 'package:alloy/alloy.dart';

/// Collects every event a graph emits, for tests that assert on them.
///
/// Built on `AlloyRecordingObserver`, so the wording of each event comes from
/// the runtime rather than from a copy that drifts.
final class CapturingObserver extends AlloyRecordingObserver {
  /// Creates an observer with an empty log.
  CapturingObserver();

  final _records = <AlloyLogRecord>[];

  /// Everything seen so far, in order.
  List<AlloyLogRecord> get records => List.unmodifiable(_records);

  /// The kind of each event, in order.
  List<AlloyEventKind> get kinds => [
    for (final record in _records) record.kind,
  ];

  /// The events of one kind.
  List<AlloyLogRecord> ofKind(AlloyEventKind kind) => [
    for (final record in _records)
      if (record.kind == kind) record,
  ];

  /// Whether any event of [kind] was seen.
  bool saw(AlloyEventKind kind) => kinds.contains(kind);

  /// Forgets everything seen so far.
  void clear() => _records.clear();

  @override
  void onRecord(AlloyLogRecord record) => _records.add(record);
}
