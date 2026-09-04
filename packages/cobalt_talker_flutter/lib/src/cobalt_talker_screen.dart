import 'package:cobalt_inspector/cobalt_inspector.dart';
import 'package:cobalt_talker_flutter/src/talker_screen_theme_of.dart';
import 'package:flutter/material.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// Talker's screen, already dressed in the inspector's palette.
///
/// Open it beside `CobaltInspectorScreen` and the two read as one tool: the
/// same background, the same four colours for the same four families.
///
/// ```dart
/// Navigator.of(context).push(
///   MaterialPageRoute<void>(builder: (_) => CobaltTalkerScreen(talker: talker)),
/// );
/// ```
///
/// [theme] overrides the palette inherited from `CobaltInspectorTheme`, which
/// in turn falls back to one derived from the host's own `Theme`.
class CobaltTalkerScreen extends StatelessWidget {
  /// Shows what [talker] has collected.
  const CobaltTalkerScreen({required this.talker, this.theme, super.key});

  /// The talker the observer was given.
  final Talker talker;

  /// The palette to draw with, overriding the inherited one.
  final CobaltInspectorThemeData? theme;

  @override
  Widget build(BuildContext context) => TalkerScreen(
    talker: talker,
    theme: talkerScreenThemeOf(theme ?? CobaltInspectorTheme.of(context)),
  );
}
