import 'dart:async';

import 'package:alloy_flutter/alloy_flutter.dart';
import 'package:flutter/foundation.dart';

/// Keeps the failures Alloy reported, so the screen can show one.
///
/// Stands in for a crash reporter. The real one is a network call and a quota;
/// this one is a list, which is the point — a sink is one callback, and what
/// it does with the report is none of Alloy's business.
class ReportLog extends ChangeNotifier {
  ReportLog();

  final _reports = <AlloyErrorReport>[];

  /// Everything reported so far, newest first.
  List<AlloyErrorReport> get reports => List.unmodifiable(_reports.reversed);

  /// Records [report] and tells listeners on the next microtask.
  ///
  /// Deferred for the same reason [AuditLog] defers: a teardown failure can
  /// arrive while the widget tree is building, and a synchronous
  /// `notifyListeners` there throws `setState() called during build`.
  void add(AlloyErrorReport report) {
    _reports.add(report);
    scheduleMicrotask(notifyListeners);
  }
}
