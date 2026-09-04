import 'package:cobalt/cobalt.dart';

/// Collects every event a graph emits, for tests that assert on them.
///
/// Built on `CobaltRecordingObserver`, so the wording of each event comes from
/// the runtime rather than from a copy that drifts.
final class CapturingObserver extends CobaltRecordingObserver {
  /// Creates an observer with an empty log.
  CapturingObserver();

  final _records = <CobaltLogRecord>[];

  /// Everything seen so far, in order.
  List<CobaltLogRecord> get records => List.unmodifiable(_records);

  /// The kind of each event, in order.
  List<CobaltEventKind> get kinds => [
    for (final record in _records) record.kind,
  ];

  /// The events of one kind.
  List<CobaltLogRecord> ofKind(CobaltEventKind kind) => [
    for (final record in _records)
      if (record.kind == kind) record,
  ];

  /// Whether any event of [kind] was seen.
  bool saw(CobaltEventKind kind) => kinds.contains(kind);

  /// Forgets everything seen so far.
  void clear() => _records.clear();

  @override
  void onRecord(CobaltLogRecord record) => _records.add(record);
}
