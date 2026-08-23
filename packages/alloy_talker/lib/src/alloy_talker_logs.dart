import 'package:talker/talker.dart';

/// Base for every log kind this adapter produces.
///
/// Each subclass gets its own [title], which is what talker filters and groups
/// by — in `TalkerScreen` the titles below become the toggles you can switch
/// off when the graph gets chatty.
abstract class AlloyTalkerLog extends TalkerLog {
  /// Creates a log entry titled [title].
  AlloyTalkerLog(
    super.message, {
    required String title,
    required AnsiPen pen,
    super.exception,
    super.error,
    super.stackTrace,
    super.logLevel,
  }) : super(title: title, pen: pen);
}

/// A scope appeared or went away.
class AlloyScopeLog extends AlloyTalkerLog {
  /// Creates the entry.
  AlloyScopeLog(super.message, {super.logLevel = LogLevel.debug})
    : super(title: 'alloy-scope', pen: _pen);

  static final _pen = AnsiPen()..xterm(51);
}

/// Startup: bootstrap steps and async initialization.
class AlloyStartupLog extends AlloyTalkerLog {
  /// Creates the entry.
  AlloyStartupLog(super.message, {super.logLevel = LogLevel.info})
    : super(title: 'alloy-startup', pen: _pen);

  static final _pen = AnsiPen()..xterm(46);
}

/// An instance was built or released.
class AlloyInstanceLog extends AlloyTalkerLog {
  /// Creates the entry.
  AlloyInstanceLog(super.message)
    : super(title: 'alloy-instance', pen: _pen, logLevel: LogLevel.verbose);

  static final _pen = AnsiPen()..xterm(245);
}

/// Something in the graph failed.
class AlloyFailureLog extends AlloyTalkerLog {
  /// Creates the entry.
  AlloyFailureLog(
    super.message, {
    super.exception,
    super.stackTrace,
    super.logLevel = LogLevel.error,
  }) : super(title: 'alloy-failure', pen: _pen);

  static final _pen = AnsiPen()..xterm(196);
}
