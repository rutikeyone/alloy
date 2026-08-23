/// How long an instance registered with [AlloyInject] lives.
enum AlloyLifetime {
  /// A new instance on every resolution. The scope does not retain it, so the
  /// caller owns its disposal.
  transient,

  /// One instance per scope, built on first resolution. The scope retains it
  /// and disposes it.
  lazySingleton,

  /// One instance per scope, built while the container is being assembled
  /// rather than on first use. Its dependencies must already be registered,
  /// which the generator guarantees by emitting registrations in dependency
  /// order.
  singleton,
}
