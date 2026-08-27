/// Talker's log screen, in the Alloy inspector's palette.
///
/// `alloy_talker` is pure Dart on purpose — it adapts events to `talker`, and
/// pulling `talker_flutter` in would push a UI dependency onto every consumer,
/// including tests that never draw. This package is where the Flutter half
/// lives, so only an app that wants the screen pays for it.
library;

export 'package:alloy_talker_flutter/src/alloy_talker_screen.dart';
export 'package:alloy_talker_flutter/src/talker_screen_theme_of.dart';
