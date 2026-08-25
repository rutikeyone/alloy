/// A value the generator cannot register, because it is not known until the
/// program starts.
///
/// Nothing annotates it: it is registered by hand in `ConsumerScope`, which is
/// why `@AlloyScopeRoot` has to promise it through `provides`.
class DeviceInfo {
  const DeviceInfo(this.model);

  final String model;
}
