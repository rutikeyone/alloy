# alloy_talker_flutter

Talker's log screen, in the same palette as the [Alloy inspector](https://pub.dev/packages/alloy_inspector).

`alloy_talker` is pure Dart on purpose: it adapts Alloy's events to `talker`, and pulling
`talker_flutter` in would push a UI dependency onto every consumer, including tests that never draw.
This package is where the Flutter half lives, so only an app that wants the screen pays for it.

```dart
Navigator.of(context).push(
  MaterialPageRoute<void>(builder: (_) => AlloyTalkerScreen(talker: talker)),
);
```

The palette is inherited from `AlloyInspectorTheme` where one is in force, and derived from the
host's own `Theme` where none is — so the log screen and the inspector match without configuration,
and both follow the app when it is configured.

## Why the bridge is four lines

`TalkerScreenTheme` colours entries by their **title**, and `AlloyTalkerObserver` writes exactly
four: `alloy-scope`, `alloy-startup`, `alloy-instance`, `alloy-failure`. Those are the same four
families the inspector colours by, which is what makes one palette dress both screens.

```dart
final theme = talkerScreenThemeOf(AlloyInspectorTheme.of(context));
```

Only Alloy's own entries are recoloured. Your logs, and talker's built-in kinds, keep talker's
colours.
