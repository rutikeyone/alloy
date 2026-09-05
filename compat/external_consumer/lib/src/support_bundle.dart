import 'package:cobalt/cobalt.dart';
import 'package:cobalt_external_consumer/src/diagnostics.dart';

/// Built by hand from something the generator built.
///
/// The other half of the composition `ConsumerScope` already shows. There a
/// generated class takes a hand-registered value; here a hand-registered class
/// takes a generated one, which is the direction a migration actually moves
/// in: the graph is annotated leaf by leaf, and what is still hand-written
/// sits above it.
///
/// Nothing annotates it, and nothing needs to: `provides` promises it the same
/// way it promises `DeviceInfo`.
class SupportBundle {
  const SupportBundle(this.summary);

  /// Whatever `Diagnostics` — a generated registration — had to say.
  final String summary;
}

/// Builds a [SupportBundle] out of a registration the generator wrote.
class SupportBundleFactory implements CobaltFactory<SupportBundle> {
  const SupportBundleFactory();

  @override
  SupportBundle create(CobaltResolver resolver) =>
      SupportBundle(resolver.get<Diagnostics>().describe());
}
