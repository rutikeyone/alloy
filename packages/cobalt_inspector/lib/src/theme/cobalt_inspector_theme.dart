import 'package:cobalt_inspector/src/theme/cobalt_inspector_theme_data.dart';
import 'package:flutter/material.dart';

/// Supplies a palette to every inspector screen below it.
///
/// Put it once, above the part of the app a debug menu opens from, and pushed
/// routes and bottom sheets get it too. Where nothing is put, [of] derives one
/// from the ambient [Theme], so the screens are dressed either way.
class CobaltInspectorTheme extends InheritedWidget {
  /// Dresses [child] and everything under it in [data].
  const CobaltInspectorTheme({
    required this.data,
    required super.child,
    super.key,
  });

  /// The palette in force.
  final CobaltInspectorThemeData data;

  /// The palette above [context], or one derived from the ambient theme.
  ///
  /// Never null and never throws: an inspector is a debugging screen, and
  /// failing to open because nobody set a colour would be the wrong trade.
  static CobaltInspectorThemeData of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<CobaltInspectorTheme>()
          ?.data ??
      CobaltInspectorThemeData.of(Theme.of(context));

  @override
  bool updateShouldNotify(CobaltInspectorTheme oldWidget) =>
      data != oldWidget.data;
}
