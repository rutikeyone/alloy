import 'package:alloy_inspector/alloy_inspector.dart';
import 'package:codegen_basics/l10n/codegen_basics_l10n.dart';
import 'package:flow_scopes/l10n/flow_scopes_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gallery/app/gallery_locale.dart';
import 'package:gallery/design/gallery_theme.dart';
import 'package:gallery/l10n/gallery_l10n.dart';
import 'package:graph_events/l10n/graph_events_l10n.dart';
import 'package:notes_app/l10n/notes_app_l10n.dart';

/// The gallery's own strings, for a test that has no widget tree.
GalleryL10n get englishStrings => lookupGalleryL10n(const Locale('en'));

/// [home] mounted the way `GalleryApp` mounts things.
///
/// The delegates are part of that: an example screen reads its prose from
/// `GalleryL10n.of`, so a bare `MaterialApp` would fail on the first entry
/// that says anything.
Widget galleryHarness({
  required Widget home,
  Locale locale = const Locale('en'),
  ValueChanged<Locale>? onSelect,
}) => GalleryLocaleScope(
  select: onSelect ?? (_) {},
  child: MaterialApp(
    theme: galleryTheme(GalleryFace.spaceGrotesk),
    builder: (context, child) => Theme(
      data: galleryTheme(GalleryFace.of(Localizations.localeOf(context))),
      child: child!,
    ),
    locale: locale,
    localizationsDelegates: const [
      GalleryL10n.delegate,
      // Every package whose screens the gallery mounts brings its own, which
      // is what a multi-package app looks like: the strings belong to the
      // package that shows them, and the app collects the delegates.
      NotesL10n.delegate,
      FlowScopesL10n.delegate,
      GraphEventsL10n.delegate,
      CodegenBasicsL10n.delegate,
      AlloyInspectorL10n.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: GalleryLocaleScope.supported,
    home: home,
  ),
);
