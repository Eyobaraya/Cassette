import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static const Color _seed = Color(0xFFE8743B);
  static const String _bodyFamily = 'PlusJakartaSans';
  static const String _brandFamily = 'Righteous';

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorSchemeSeed: _seed,
      fontFamily: _bodyFamily,
    );
  }

  static TextStyle brand(
    BuildContext context, {
    double? fontSize,
    Color? color,
  }) {
    final theme = Theme.of(context);
    return TextStyle(
      fontFamily: _brandFamily,
      fontSize: fontSize ?? 28,
      color: color ?? theme.colorScheme.primary,
      letterSpacing: 0.5,
    );
  }
}
