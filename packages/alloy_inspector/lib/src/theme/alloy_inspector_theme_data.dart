import 'package:alloy_flutter/alloy_flutter.dart';
import 'package:alloy_inspector/src/theme/alloy_inspector_family.dart';
import 'package:flutter/material.dart';

/// The palette and type the inspector screens are drawn with.
///
/// The default is derived from the host application's own theme, so an
/// inspector dropped into an app already matches it without a line of
/// configuration. Pass one of these only where the derived answer is not the
/// one you want:
///
/// ```dart
/// AlloyInspectorTheme(
///   data: AlloyInspectorThemeData.of(Theme.of(context)).copyWith(
///     failure: brand.danger,
///     accent: brand.primary,
///   ),
///   child: child,
/// )
/// ```
@immutable
class AlloyInspectorThemeData {
  /// Creates a palette outright. Prefer [AlloyInspectorThemeData.of].
  const AlloyInspectorThemeData({
    required this.background,
    required this.surface,
    required this.onSurface,
    required this.muted,
    required this.outline,
    required this.accent,
    required this.scope,
    required this.startup,
    required this.instance,
    required this.failure,
    this.monospace,
    this.dense = true,
  });

  /// Derives a palette from the application's own theme.
  ///
  /// Everything comes from [ThemeData.colorScheme], so the inspector follows
  /// the host into light mode, dark mode and any brand seed. The four family
  /// colours are the one place this leans on more than the scheme: an event
  /// stream needs them far enough apart to scan, which `primary`, `secondary`
  /// and `tertiary` do not guarantee on a narrow seed.
  factory AlloyInspectorThemeData.of(ThemeData theme) {
    final scheme = theme.colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    return AlloyInspectorThemeData(
      background: scheme.surface,
      surface: scheme.surfaceContainerHighest,
      onSurface: scheme.onSurface,
      muted: scheme.onSurfaceVariant,
      outline: scheme.outlineVariant,
      accent: scheme.primary,
      scope: dark ? const Color(0xFF6FD3E8) : const Color(0xFF00728C),
      startup: dark ? const Color(0xFF74D99F) : const Color(0xFF117A48),
      instance: scheme.onSurfaceVariant,
      failure: scheme.error,
      monospace: theme.textTheme.bodySmall?.copyWith(
        fontFamily: 'monospace',
        fontFamilyFallback: const ['Menlo', 'Consolas', 'Roboto Mono'],
      ),
    );
  }

  /// Behind everything.
  final Color background;

  /// Cards, sheets and grouped rows.
  final Color surface;

  /// Ordinary text.
  final Color onSurface;

  /// Secondary text: timestamps, counts, the line under a title.
  final Color muted;

  /// Hairlines and dividers.
  final Color outline;

  /// Selection, focus and the active filter.
  final Color accent;

  /// A scope appeared or went away.
  final Color scope;

  /// Startup: bootstrap steps and async initialization.
  final Color startup;

  /// An instance was built or released.
  final Color instance;

  /// Something failed.
  final Color failure;

  /// For keys, timestamps and structured output. Falls back to the host's
  /// `bodySmall` where null.
  final TextStyle? monospace;

  /// Whether rows are packed tightly. A log is read in bulk, so they are.
  final bool dense;

  /// The colour of one family.
  Color colorOfFamily(AlloyInspectorFamily family) => switch (family) {
    AlloyInspectorFamily.scope => scope,
    AlloyInspectorFamily.startup => startup,
    AlloyInspectorFamily.instance => instance,
    AlloyInspectorFamily.failure => failure,
  };

  /// The colour of one event, through its family.
  Color colorOfKind(AlloyEventKind kind) =>
      colorOfFamily(AlloyInspectorFamily.of(kind));

  /// The colour of one severity.
  ///
  /// Only the two loud levels get one of their own; the quiet three read as
  /// ordinary text, which is what keeps a busy log scannable.
  Color colorOfLevel(AlloyLogLevel level) => switch (level) {
    AlloyLogLevel.error => failure,
    AlloyLogLevel.warning => startup,
    AlloyLogLevel.info || AlloyLogLevel.debug || AlloyLogLevel.trace => muted,
  };

  /// The colour of one lifetime.
  Color colorOfLifetime(AlloyRegistrationKind kind) => switch (kind) {
    AlloyRegistrationKind.singleton ||
    AlloyRegistrationKind.lazySingleton => scope,
    AlloyRegistrationKind.asyncSingleton => startup,
    AlloyRegistrationKind.transient ||
    AlloyRegistrationKind.parameterized => instance,
  };

  /// The icon one family is marked with.
  IconData iconOfFamily(AlloyInspectorFamily family) => switch (family) {
    AlloyInspectorFamily.scope => Icons.account_tree_outlined,
    AlloyInspectorFamily.startup => Icons.play_circle_outline,
    AlloyInspectorFamily.instance => Icons.widgets_outlined,
    AlloyInspectorFamily.failure => Icons.error_outline,
  };

  @override
  bool operator ==(Object other) =>
      other is AlloyInspectorThemeData &&
      other.background == background &&
      other.surface == surface &&
      other.onSurface == onSurface &&
      other.muted == muted &&
      other.outline == outline &&
      other.accent == accent &&
      other.scope == scope &&
      other.startup == startup &&
      other.instance == instance &&
      other.failure == failure &&
      other.monospace == monospace &&
      other.dense == dense;

  @override
  int get hashCode => Object.hash(
    background,
    surface,
    onSurface,
    muted,
    outline,
    accent,
    scope,
    startup,
    instance,
    failure,
    monospace,
    dense,
  );

  /// A copy with some colours replaced.
  AlloyInspectorThemeData copyWith({
    Color? background,
    Color? surface,
    Color? onSurface,
    Color? muted,
    Color? outline,
    Color? accent,
    Color? scope,
    Color? startup,
    Color? instance,
    Color? failure,
    TextStyle? monospace,
    bool? dense,
  }) => AlloyInspectorThemeData(
    background: background ?? this.background,
    surface: surface ?? this.surface,
    onSurface: onSurface ?? this.onSurface,
    muted: muted ?? this.muted,
    outline: outline ?? this.outline,
    accent: accent ?? this.accent,
    scope: scope ?? this.scope,
    startup: startup ?? this.startup,
    instance: instance ?? this.instance,
    failure: failure ?? this.failure,
    monospace: monospace ?? this.monospace,
    dense: dense ?? this.dense,
  );
}
