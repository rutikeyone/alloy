import 'package:cobalt/cobalt.dart';

/// What one key did when a graph was checked.
enum CobaltGraphOutcome {
  /// It resolved.
  resolved,

  /// Its factory threw.
  failed,

  /// Nothing tried: a parameterized registration with no sample value.
  unchecked,
}

/// One key's result.
class CobaltGraphEntry {
  /// Creates an entry.
  CobaltGraphEntry(this.key, this.outcome, {this.error, this.reason});

  /// The key that was checked.
  final CobaltKey key;

  /// What happened.
  final CobaltGraphOutcome outcome;

  /// What the factory threw, when it did.
  final Object? error;

  /// Why nothing was tried, when nothing was.
  final String? reason;

  @override
  String toString() => switch (outcome) {
    CobaltGraphOutcome.resolved => '$key — resolved',
    CobaltGraphOutcome.failed => '$key — $error',
    CobaltGraphOutcome.unchecked => '$key — not checked: $reason',
  };
}

/// The result of walking a graph and resolving everything in it.
///
/// [unchecked] matters as much as [failures]. A parameterized registration
/// cannot be resolved without a value, so it is listed by name rather than
/// skipped in silence — otherwise the check quietly grows the blind spot it
/// exists to close.
class CobaltGraphReport {
  /// Creates a report.
  CobaltGraphReport(this.entries);

  /// Every key that was looked at.
  final List<CobaltGraphEntry> entries;

  /// Keys whose factory threw.
  List<CobaltGraphEntry> get failures => [
    for (final entry in entries)
      if (entry.outcome == CobaltGraphOutcome.failed) entry,
  ];

  /// Keys nothing was tried on.
  List<CobaltGraphEntry> get unchecked => [
    for (final entry in entries)
      if (entry.outcome == CobaltGraphOutcome.unchecked) entry,
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
