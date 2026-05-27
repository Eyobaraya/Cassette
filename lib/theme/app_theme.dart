import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralised theme for Cassette.
///
/// Two typefaces, used deliberately:
/// - [brand] (Righteous): the app name and other branding moments. Bold,
///   geometric, retro-modern — it nods to the cassette aesthetic.
/// - Plus Jakarta Sans: every other piece of UI text (song titles, menus,
///   body copy). Clean and highly legible on small screens.
class AppTheme {
  const AppTheme._();

  static const Color _seed = Color(0xFFE8743B); // warm tape orange

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorSchemeSeed: _seed,
    );

    return base.copyWith(
      textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme),
    );
  }

  /// Branding typeface (Righteous). Use for the app name / display moments.
  static TextStyle brand(
    BuildContext context, {
    double? fontSize,
    Color? color,
  }) {
    final theme = Theme.of(context);
    return GoogleFonts.righteous(
      fontSize: fontSize ?? 28,
      color: color ?? theme.colorScheme.primary,
      letterSpacing: 0.5,
    );
  }
}
