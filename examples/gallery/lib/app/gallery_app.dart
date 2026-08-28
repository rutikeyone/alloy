import 'package:alloy_inspector/alloy_inspector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gallery/app/gallery_locale.dart';
import 'package:gallery/design/gallery_theme.dart';
import 'package:gallery/features/hub/hub_screen.dart';
import 'package:gallery/l10n/gallery_l10n.dart';

/// The gallery owns no graph of its own.
///
/// Every example brings its own, built when you open it and disposed when you
/// leave — which is the thing the gallery is really demonstrating, so putting
/// a container above them all would undercut it.
///
/// It does own the language. `AlloyInspectorL10n.delegate` is registered here
/// beside the gallery's own: the inspector renders in the host's language
/// without it, but installing it is the documented way, and a gallery that
/// showed the fallback rather than the intended path would be teaching the
/// wrong one.
class GalleryApp extends StatefulWidget {
  const GalleryApp({super.key});

  @override
  State<GalleryApp> createState() => _GalleryAppState();
}

class _GalleryAppState extends State<GalleryApp> {
  Locale? _locale;

  void _select(Locale locale) => setState(() => _locale = locale);

  @override
  Widget build(BuildContext context) => GalleryLocaleScope(
    select: _select,
    child: MaterialApp(
      onGenerateTitle: (context) => GalleryL10n.of(context).appTitle,
      theme: galleryTheme(),
      locale: _locale,
      localizationsDelegates: const [
        GalleryL10n.delegate,
        AlloyInspectorL10n.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: GalleryLocaleScope.supported,
      home: const HubScreen(),
    ),
  );
}
