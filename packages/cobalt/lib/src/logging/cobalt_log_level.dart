/// How much a log record matters.
///
/// Five levels rather than a logger's own set, because every logger names them
/// differently — an adapter maps these onto whatever it uses.
enum CobaltLogLevel {
  /// Per-instance detail: something was built or released.
  trace,

  /// Structure: a scope appeared or went away.
  debug,

  /// Milestones: startup phases finished.
  info,

  /// Something did not go to plan but the graph carried on.
  warning,

  /// Something failed.
  error,
}
