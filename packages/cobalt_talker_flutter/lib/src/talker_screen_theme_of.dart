import 'package:cobalt_inspector/cobalt_inspector.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// Translates an inspector palette into talker's screen theme.
///
/// `TalkerScreenTheme` colours entries by their **title**, and the titles
/// `CobaltTalkerObserver` writes are exactly the four families the inspector
/// colours by — which is why the whole bridge is four entries. Anything else
/// in the talker (your own logs, its built-in kinds) keeps talker's colours;
/// only Cobalt's own entries are recoloured.
TalkerScreenTheme talkerScreenThemeOf(CobaltInspectorThemeData theme) =>
    TalkerScreenTheme(
      backgroundColor: theme.background,
      textColor: theme.onSurface,
      cardColor: theme.surface,
      logColors: {
        for (final family in CobaltInspectorFamily.values)
          family.talkerTitle: theme.colorOfFamily(family),
      },
    );
