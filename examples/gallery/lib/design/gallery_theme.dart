import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The palette from the design canvas, transcribed.
///
/// The two accents carry one distinction and only that one: [screen] marks an
/// example you can open on a device, [terminal] one that prints. They share
/// chroma and lightness and differ only in hue, so neither reads as more
/// important than the other.
abstract final class GalleryColors {
  static const canvas = Color(0xFF1B1E24);
  static const card = Color(0xFF262A31);
  static const terminalSurface = Color(0xFF13161B);
  static const hairline = Color(0xFF383D46);

  static const text = Color(0xFFEDEFF2);
  static const textMuted = Color(0xFFA3A9B4);
  static const textFaint = Color(0xFF7C838F);

  static const screen = Color(0xFF5FD4C8);
  static const terminal = Color(0xFFE0A85F);
}

/// Type scale from the canvas. Grotesk for the interface, mono for anything
/// the machine said.
abstract final class GalleryText {
  static TextStyle get wordmark => GoogleFonts.spaceGrotesk(
    fontSize: 25,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    height: 1.05,
    color: GalleryColors.text,
  );

  static TextStyle get title => GoogleFonts.spaceGrotesk(
    fontSize: 27,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: GalleryColors.text,
  );

  static TextStyle get cardTitle => GoogleFonts.spaceGrotesk(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.1,
    color: GalleryColors.text,
  );

  static TextStyle get body => GoogleFonts.spaceGrotesk(
    fontSize: 14,
    height: 1.5,
    color: const Color(0xFFD2D6DC),
  );

  static TextStyle get cardBody => GoogleFonts.spaceGrotesk(
    fontSize: 13,
    height: 1.45,
    color: GalleryColors.textMuted,
  );

  static TextStyle get lede => GoogleFonts.spaceGrotesk(
    fontSize: 15,
    height: 1.5,
    color: GalleryColors.textMuted,
  );

  static TextStyle get mono => GoogleFonts.jetBrainsMono(
    fontSize: 11.5,
    height: 1.7,
    color: const Color(0xFFC8CCD3),
  );

  static TextStyle get monoCaps => GoogleFonts.jetBrainsMono(
    fontSize: 10.5,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.1,
    color: GalleryColors.textFaint,
  );

  static TextStyle get badge =>
      GoogleFonts.jetBrainsMono(fontSize: 9.5, letterSpacing: 0.7, height: 1.4);

  static TextStyle get subtitle => GoogleFonts.jetBrainsMono(
    fontSize: 11,
    letterSpacing: 0.2,
    color: GalleryColors.textFaint,
  );
}

ThemeData galleryTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: GalleryColors.canvas,
    colorScheme: base.colorScheme.copyWith(
      surface: GalleryColors.canvas,
      primary: GalleryColors.screen,
      onPrimary: GalleryColors.canvas,
    ),
    textTheme: GoogleFonts.spaceGroteskTextTheme(base.textTheme),
  );
}
