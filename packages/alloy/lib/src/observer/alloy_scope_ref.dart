import 'package:meta/meta.dart';

/// Identifies a scope in an [AlloyObserver] callback.
///
/// A description, not the scope itself. Handing an observer the live
/// [AlloyScope] would let it resolve from a scope that is halfway through
/// teardown, or dispose it a second time — an observer watches, it does not
/// participate.
@immutable
final class AlloyScopeRef {
  /// Describes a scope by [name] at [depth] under [parentName].
  const AlloyScopeRef({
    required this.name,
    required this.depth,
    this.parentName,
  });

  /// The scope's name.
  final String name;

  /// How far below the root this scope sits. `0` for a root.
  final int depth;

  /// The parent's name, or `null` for a root.
  final String? parentName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlloyScopeRef &&
          other.name == name &&
          other.depth == depth &&
          other.parentName == parentName;

  @override
  int get hashCode => Object.hash(name, depth, parentName);

  @override
  String toString() => parentName == null ? name : '$parentName/$name';
}
