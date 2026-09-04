import 'package:talker/talker.dart';

/// Base for every log kind this adapter produces.
///
/// Each subclass gets its own [title], which is what talker filters and groups
/// by — in `TalkerScreen` the titles below become the toggles you can switch
/// off when the graph gets chatty.
abstract class CobaltTalkerLog extends TalkerLog {
  /// Creates a log entry titled [title].
  ///
  /// The key is set to the title as well, and that is not decoration:
  /// `talker_flutter` colours a row by its **key**, falling back to the log
  /// level when there is none. Without it a themed screen paints every startup
  /// entry the same blue as any other info line, whatever the theme says about
  /// titles.
  CobaltTalkerLog(
    super.message, {
    required String title,
    required AnsiPen pen,
    super.exception,
    super.error,
    super.stackTrace,
    super.logLevel,
  }) : super(title: title, key: title, pen: pen);
}

/// A scope appeared or went away.
class CobaltScopeLog extends CobaltTalkerLog {
  /// Creates the entry.
  CobaltScopeLog(super.message, {super.logLevel = LogLevel.debug})
    : super(title: 'cobalt-scope', pen: _pen);

  static final _pen = AnsiPen()..xterm(51);
}

/// Startup: bootstrap steps and async initialization.
class CobaltStartupLog extends CobaltTalkerLog {
  /// Creates the entry.
  CobaltStartupLog(super.message, {super.logLevel = LogLevel.info})
    : super(title: 'cobalt-startup', pen: _pen);

  static final _pen = AnsiPen()..xterm(46);
}

/// An instance was built or released.
class CobaltInstanceLog extends CobaltTalkerLog {
  /// Creates the entry.
  CobaltInstanceLog(super.message)
    : super(title: 'cobalt-instance', pen: _pen, logLevel: LogLevel.verbose);

  static final _pen = AnsiPen()..xterm(245);
}

/// Something in the graph failed.
class CobaltFailureLog extends CobaltTalkerLog {
  /// Creates the entry.
  CobaltFailureLog(
    super.message, {
    super.exception,
    super.stackTrace,
    super.logLevel = LogLevel.error,
  }) : super(title: 'cobalt-failure', pen: _pen);

  static final _pen = AnsiPen()..xterm(196);
}
