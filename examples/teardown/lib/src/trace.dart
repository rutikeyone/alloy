/// Records what happened, in the order it happened.
///
/// Disposal order is the whole subject here, so every service writes into one
/// list rather than printing — a test can then assert on the sequence.
class Trace {
  final entries = <String>[];

  void add(String entry) => entries.add(entry);

  void clear() => entries.clear();

  @override
  String toString() => entries.map((e) => '  $e').join('\n');
}
