import 'dart:developer' as developer;

import 'package:alloy/src/logging/alloy_log_record.dart';
import 'package:alloy/src/logging/alloy_recording_observer.dart';

/// Posts every Alloy event to the VM service, where DevTools shows it.
///
/// Events arrive under `alloy.<kind>` and appear in DevTools' Logging view
/// with no extension installed, which is most of the value for no cost.
///
/// The whole adapter is this short because the record already carries a
/// machine-readable [AlloyLogRecord.kind] and `toStructured()` already returns
/// the map `postEvent` wants — both added when failure reporting needed the
/// same thing.
///
/// Pass it like any other observer, guarded so release builds are untouched:
///
/// ```dart
/// AlloyApplication.start(
///   root: const AppScope(),
///   observers: [if (!kReleaseMode) const AlloyDevToolsObserver()],
/// );
/// ```
final class AlloyDevToolsObserver extends AlloyRecordingObserver {
  /// Creates the observer.
  const AlloyDevToolsObserver();

  @override
  void onRecord(AlloyLogRecord record) =>
      developer.postEvent('alloy.${record.kind.name}', record.toStructured());
}
