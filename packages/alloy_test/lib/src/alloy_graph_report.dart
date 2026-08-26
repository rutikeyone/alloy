import 'package:alloy/alloy.dart';

/// What one key did when a graph was checked.
enum AlloyGraphOutcome {
  /// It resolved.
  resolved,

  /// Its factory threw.
  failed,

  /// Nothing tried: a parameterized registration with no sample value.
  unchecked,
}

/// One key's result.
class AlloyGraphEntry {
  /// Creates an entry.
  AlloyGraphEntry(this.key, this.outcome, {this.error, this.reason});

  /// The key that was checked.
  final AlloyKey key;

  /// What happened.
  final AlloyGraphOutcome outcome;

  /// What the factory threw, when it did.
  final Object? error;

  /// Why nothing was tried, when nothing was.
  final String? reason;

  @override
  String toString() => switch (outcome) {
    AlloyGraphOutcome.resolved => '$key — resolved',
    AlloyGraphOutcome.failed => '$key — $error',
    AlloyGraphOutcome.unchecked => '$key — not checked: $reason',
  };
}

/// The result of walking a graph and resolving everything in it.
///
/// [unchecked] matters as much as [failures]. A parameterized registration
/// cannot be resolved without a value, so it is listed by name rather than
/// skipped in silence — otherwise the check quietly grows the blind spot it
/// exists to close.
class AlloyGraphReport {
  /// Creates a report.
  AlloyGraphReport(this.entries);

  /// Every key that was looked at.
  final List<AlloyGraphEntry> entries;

  /// Keys whose factory threw.
  List<AlloyGraphEntry> get failures => [
    for (final entry in entries)
      if (entry.outcome == AlloyGraphOutcome.failed) entry,
  ];

  /// Keys nothing was tried on.
  List<AlloyGraphEntry> get unchecked => [
    for (final entry in entries)
      if (entry.outcome == AlloyGraphOutcome.unchecked) entry,
  ];

  /// Whether every key that could be resolved did.
  bool get isComplete => failures.isEmpty;

  @override
  String toString() {
    final lines = [for (final entry in entries) '  $entry'].join('\n');
    return 'Checked ${entries.length} registration(s), '
        '${failures.length} failed, ${unchecked.length} not checked.\n$lines';
  }
}
