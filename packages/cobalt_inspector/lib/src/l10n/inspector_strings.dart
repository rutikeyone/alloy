import 'package:cobalt_inspector/src/l10n/cobalt_inspector_l10n.dart';
import 'package:cobalt_inspector/src/theme/cobalt_inspector_family.dart';
import 'package:flutter/widgets.dart';

/// The inspector's own strings, whether or not the host installed them.
///
/// Reading them through [CobaltInspectorL10n.of] alone would make the delegate
/// mandatory, and the inspector is something you drop into an app to look at a
/// graph — asking for a `localizationsDelegates` edit before it renders at all
/// would be the wrong trade. So the delegate wins when it is there, the
/// ambient locale decides when it is not, and English is the floor.
CobaltInspectorL10n inspectorStringsOf(BuildContext context) =>
    CobaltInspectorL10n.of(context) ??
    lookupCobaltInspectorL10n(_nearest(Localizations.maybeLocaleOf(context)));

Locale _nearest(Locale? locale) {
  if (locale == null) return _fallback;
  for (final supported in CobaltInspectorL10n.supportedLocales) {
    if (supported.languageCode == locale.languageCode) return supported;
  }
  return _fallback;
}

const _fallback = Locale('en');

/// What a family is called on screen.
///
/// Separate from [CobaltInspectorFamily.talkerTitle], which is a key talker
/// colours rows by and must not move when the language does.
extension CobaltInspectorFamilyLabel on CobaltInspectorFamily {
  /// This family's name in [strings]' language.
  String label(CobaltInspectorL10n strings) => switch (this) {
    CobaltInspectorFamily.scope => strings.familyScope,
    CobaltInspectorFamily.startup => strings.familyStartup,
    CobaltInspectorFamily.instance => strings.familyInstance,
    CobaltInspectorFamily.failure => strings.familyFailure,
  };
}
