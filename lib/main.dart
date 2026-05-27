import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'screens/home_screen.dart';
import 'services/music_service.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.example.simple_trial.channel.audio',
    androidNotificationChannelName: 'Simple Trial playback',
    androidNotificationOngoing: true,
  );
  runApp(const SimpleTrialApp());
}

class SimpleTrialApp extends StatefulWidget {
  const SimpleTrialApp({super.key});

  @override
  State<SimpleTrialApp> createState() => _SimpleTrialAppState();
}

class _SimpleTrialAppState extends State<SimpleTrialApp> {
  final storageService = StorageService();
  late final musicService = MusicService(storageService);
  bool darkMode = true;

  @override
  void initState() {
    super.initState();
    musicService.loadSavedData();
    _loadTheme();
  }

  @override
  void dispose() {
    musicService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cassette',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
      home: HomeScreen(
        musicService: musicService,
        darkMode: darkMode,
        onThemeChanged: setTheme,
      ),
    );
  }

  Future<void> _loadTheme() async {
    final value = await storageService.loadDarkMode();
    if (!mounted) return;
    setState(() => darkMode = value);
  }

  Future<void> setTheme(bool value) async {
    setState(() => darkMode = value);
    await storageService.saveDarkMode(value);
  }
}
