import 'dart:async';

import 'package:cobalt_flutter/cobalt_flutter.dart';
import 'package:flutter/foundation.dart';

/// Keeps the failures Cobalt reported, so the screen can show one.
///
/// Stands in for a crash reporter. The real one is a network call and a quota;
/// this one is a list, which is the point — a sink is one callback, and what
/// it does with the report is none of Cobalt's business.
class ReportLog extends ChangeNotifier {
  ReportLog();

  final _reports = <CobaltErrorReport>[];

  /// Everything reported so far, newest first.
  List<CobaltErrorReport> get reports => List.unmodifiable(_reports.reversed);

  /// Records [report] and tells listeners on the next microtask.
  ///
  /// Deferred for the same reason [AuditLog] defers: a teardown failure can
  /// arrive while the widget tree is building, and a synchronous
  /// `notifyListeners` there throws `setState() called during build`.
  void add(CobaltErrorReport report) {
    _reports.add(report);
    scheduleMicrotask(notifyListeners);
  }
}
