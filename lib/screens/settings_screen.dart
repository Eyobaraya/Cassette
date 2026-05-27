import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.darkMode,
    required this.onThemeChanged,
  });

  final bool darkMode;
  final ValueChanged<bool> onThemeChanged;

  static const String _aboutCopy =
      "Cassette was born out of a simple need: a music player that just plays "
      "your music. No algorithms telling you what to listen to, no hidden "
      "tracking, and no subscriptions. It simply hooks into your local device "
      "storage, gathers your tracks, and stays out of your way. It's a modern "
      "tribute to the physical tapes we used to carry around—focused, "
      "intentional, and entirely yours.";

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        SwitchListTile(
          value: darkMode,
          onChanged: onThemeChanged,
          secondary: const Icon(Icons.brightness_6),
          title: const Text('Dark mode'),
        ),
        const Divider(height: 32),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: Text(
            'About',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Text(
            'Cassette',
            style: AppTheme.brand(context, fontSize: 36),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Text(
            _aboutCopy,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.55),
          ),
        ),
      ],
    );
  }
}
