/// Talker's log screen, in the Cobalt inspector's palette.
///
/// `cobalt_talker` is pure Dart on purpose — it adapts events to `talker`, and
/// pulling `talker_flutter` in would push a UI dependency onto every consumer,
/// including tests that never draw. This package is where the Flutter half
/// lives, so only an app that wants the screen pays for it.
library;

export 'package:cobalt_talker_flutter/src/cobalt_talker_screen.dart';
export 'package:cobalt_talker_flutter/src/talker_screen_theme_of.dart';
