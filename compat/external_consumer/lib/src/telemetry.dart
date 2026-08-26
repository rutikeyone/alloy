/// Something no environment of this package registers.
///
/// It exists to prove the shape of an optional dependency: `Reporter` asks for
/// it as `Telemetry?`, the build accepts a graph that supplies nothing, and the
/// field arrives null.
class Telemetry {
  const Telemetry();

  String get endpoint => 'https://telemetry.example';
}
