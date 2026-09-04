import 'package:cobalt/src/logging/cobalt_log_record.dart';
import 'package:meta/meta.dart';

/// One failure, and what the graph was doing before it.
///
/// A crash reporter given only the exception can say *what* broke. The
/// breadcrumbs say *when* — which scope had just been pushed, which instance
/// was built last, whether a bootstrap step had already run. That is the part
/// nobody but the framework can supply, and it is usually the part that makes
/// the report actionable.
@immutable
final class CobaltErrorReport {
  /// Creates a report.
  const CobaltErrorReport({required this.failure, required this.breadcrumbs});

  /// The record that went wrong.
  final CobaltLogRecord failure;

  /// What happened before it, oldest first.
  ///
  /// Bounded — see `CobaltErrorObserver.breadcrumbs`. The failure itself is not
  /// repeated here.
  final List<CobaltLogRecord> breadcrumbs;

  /// The failure, for the common case of handing it to a reporter.
  Object? get error => failure.error;

  /// Where [error] came from.
  StackTrace? get stackTrace => failure.stackTrace;

  /// The report as data, for a destination that takes structured input.
  Map<String, Object?> toStructured() => {
    ...failure.toStructured(),
    'breadcrumbs': [for (final crumb in breadcrumbs) crumb.toStructured()],
  };

  @override
  String toString() =>
      '${failure.message} (${breadcrumbs.length} breadcrumb(s))';
}
