import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'screens/home_screen.dart';
import 'services/music_service.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.example.cassette.channel.audio',
    androidNotificationChannelName: 'Cassette playback',
    androidNotificationOngoing: true,
  );
  runApp(const CassetteApp());
}

class CassetteApp extends StatefulWidget {
  const CassetteApp({super.key});

  @override
  State<CassetteApp> createState() => _CassetteAppState();
}

class _CassetteAppState extends State<CassetteApp> {
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
