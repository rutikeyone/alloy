import 'package:meta/meta.dart';

/// Identifies a registration inside a scope.
///
/// A registration is keyed by type *and* optional name, so the same type can
/// be registered several times as long as the names differ. Keys compare by
/// value, which is what makes `dependsOn` sets and registration maps work.
@immutable
final class CobaltKey {
  /// Creates a key for [type], optionally distinguished by [name].
  const CobaltKey(this.type, {this.name});

  /// The type the registration is published under.
  ///
  /// For a registration using `exposeAs` this is the exposed type, not the
  /// concrete implementation.
  final Type type;

  /// Distinguishes this registration from others of the same [type].
  final String? name;

  @override
  bool operator ==(Object other) =>
      other is CobaltKey && other.type == type && other.name == name;

  @override
  int get hashCode => Object.hash(type, name);

  @override
  String toString() => name == null ? '$type' : '$type($name)';
}
