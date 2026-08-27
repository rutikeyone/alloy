import 'package:alloy_inspector/alloy_inspector.dart';
import 'package:alloy_talker_flutter/src/talker_screen_theme_of.dart';
import 'package:flutter/material.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// Talker's screen, already dressed in the inspector's palette.
///
/// Open it beside `AlloyInspectorScreen` and the two read as one tool: the
/// same background, the same four colours for the same four families.
///
/// ```dart
/// Navigator.of(context).push(
///   MaterialPageRoute<void>(builder: (_) => AlloyTalkerScreen(talker: talker)),
/// );
/// ```
///
/// [theme] overrides the palette inherited from `AlloyInspectorTheme`, which
/// in turn falls back to one derived from the host's own `Theme`.
class AlloyTalkerScreen extends StatelessWidget {
  /// Shows what [talker] has collected.
  const AlloyTalkerScreen({required this.talker, this.theme, super.key});

  /// The talker the observer was given.
  final Talker talker;

  /// The palette to draw with, overriding the inherited one.
  final AlloyInspectorThemeData? theme;

  @override
  Widget build(BuildContext context) => TalkerScreen(
    talker: talker,
    theme: talkerScreenThemeOf(theme ?? AlloyInspectorTheme.of(context)),
  );
}
