/// Stands in for a logger Alloy ships no adapter for — a crash reporter, an
/// in-house wrapper, whatever the project already has.
///
/// The point is that it needs no adapter: a sink is one callback.
class AuditLog {
  final lines = <String>[];

  void write(String line) => lines.add(line);
}
