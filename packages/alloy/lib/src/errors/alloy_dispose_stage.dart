/// Which part of teardown a failure came from.
enum AlloyDisposeStage {
  /// Waiting for an `init()` that was still running when [AlloyScope.dispose]
  /// was called.
  ///
  /// A failure here is the initialization failing, not teardown failing.
  /// Teardown still runs afterwards, because a half-built scope has more to
  /// release than a fully built one, not less.
  awaitingInit,

  /// Releasing a child scope or an instance this scope owned.
  releasing,
}
