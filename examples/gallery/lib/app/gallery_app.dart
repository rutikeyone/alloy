import 'package:flutter/material.dart';
import 'package:gallery/design/gallery_theme.dart';
import 'package:gallery/features/hub/hub_screen.dart';

/// The gallery owns no graph of its own.
///
/// Every example brings its own, built when you open it and disposed when you
/// leave — which is the thing the gallery is really demonstrating, so putting
/// a container above them all would undercut it.
class GalleryApp extends StatelessWidget {
  const GalleryApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Alloy examples',
    theme: galleryTheme(),
    home: const HubScreen(),
  );
}
