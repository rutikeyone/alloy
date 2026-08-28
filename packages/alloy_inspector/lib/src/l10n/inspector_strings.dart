import 'package:alloy_inspector/src/l10n/alloy_inspector_l10n.dart';
import 'package:alloy_inspector/src/theme/alloy_inspector_family.dart';
import 'package:flutter/widgets.dart';

/// The inspector's own strings, whether or not the host installed them.
///
/// Reading them through [AlloyInspectorL10n.of] alone would make the delegate
/// mandatory, and the inspector is something you drop into an app to look at a
/// graph — asking for a `localizationsDelegates` edit before it renders at all
/// would be the wrong trade. So the delegate wins when it is there, the
/// ambient locale decides when it is not, and English is the floor.
AlloyInspectorL10n inspectorStringsOf(BuildContext context) =>
    AlloyInspectorL10n.of(context) ??
    lookupAlloyInspectorL10n(_nearest(Localizations.maybeLocaleOf(context)));

Locale _nearest(Locale? locale) {
  if (locale == null) return _fallback;
  for (final supported in AlloyInspectorL10n.supportedLocales) {
    if (supported.languageCode == locale.languageCode) return supported;
  }
  return _fallback;
}

const _fallback = Locale('en');

/// What a family is called on screen.
///
/// Separate from [AlloyInspectorFamily.talkerTitle], which is a key talker
/// colours rows by and must not move when the language does.
extension AlloyInspectorFamilyLabel on AlloyInspectorFamily {
  /// This family's name in [strings]' language.
  String label(AlloyInspectorL10n strings) => switch (this) {
    AlloyInspectorFamily.scope => strings.familyScope,
    AlloyInspectorFamily.startup => strings.familyStartup,
    AlloyInspectorFamily.instance => strings.familyInstance,
    AlloyInspectorFamily.failure => strings.familyFailure,
  };
}
