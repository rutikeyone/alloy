import 'package:alloy_flutter/alloy_flutter.dart';
import 'package:flutter/material.dart';

/// What one registration looks like to the inspector.
///
/// Built from a live scope rather than from events: the scope knows what it
/// registers and, through `debugKindOf`, how long each one lives. Reading it
/// costs nothing and builds nothing.
@immutable
class RegistrationView {
  /// Describes [key] as seen from a scope.
  const RegistrationView({
    required this.key,
    required this.kind,
    required this.owner,
    required this.isInherited,
  });

  /// Everything [scope] can resolve, its own registrations first.
  ///
  /// Inherited entries carry the scope that owns them, which is the fact that
  /// decides what an override actually affects: a factory runs on the scope
  /// that owns *its* registration, not the one you asked from.
  static List<RegistrationView> of(AlloyScope scope) {
    final own = scope.keys;
    return [
      for (final entry in scope.visibleKeys.entries)
        RegistrationView(
          key: entry.key,
          kind: scope.debugKindOf(entry.key),
          owner: entry.value,
          isInherited: !own.contains(entry.key),
        ),
    ]..sort((a, b) {
      if (a.isInherited != b.isInherited) return a.isInherited ? 1 : -1;
      return a.key.toString().compareTo(b.key.toString());
    });
  }

  /// The type, and the name when it has one.
  final AlloyKey key;

  /// How long it lives, or null when the scope no longer holds it.
  final AlloyRegistrationKind? kind;

  /// The scope that will build it.
  final AlloyScope owner;

  /// Whether it comes from an ancestor rather than from the scope asked.
  final bool isInherited;

  /// Whether it can be built without a value from the caller.
  bool get isBuildable =>
      kind != null && kind != AlloyRegistrationKind.parameterized;
}
