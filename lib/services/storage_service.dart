import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/playlist.dart';
import '../models/song.dart';

class StorageService {
  static const songsKey = 'songs';
  static const favoritesKey = 'favorites';
  static const playlistsKey = 'playlists';
  static const darkModeKey = 'dark_mode';
  static const autoScannedKey = 'auto_scanned';

  Future<List<Song>> loadSongs() async {
    final prefs = await SharedPreferences.getInstance();
    final savedSongs = prefs.getStringList(songsKey) ?? [];

    return savedSongs
        .map((song) => Song.fromJson(jsonDecode(song) as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveSongs(List<Song> songs) async {
    final prefs = await SharedPreferences.getInstance();
    final savedSongs = songs.map((song) => jsonEncode(song.toJson())).toList();

    await prefs.setStringList(songsKey, savedSongs);
  }

  Future<Set<String>> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(favoritesKey) ?? []).toSet();
  }

  Future<void> saveFavorites(Set<String> favorites) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(favoritesKey, favorites.toList());
  }

  Future<List<Playlist>> loadPlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPlaylists = prefs.getStringList(playlistsKey) ?? [];

    return savedPlaylists
        .map((playlist) {
          return Playlist.fromJson(jsonDecode(playlist) as Map<String, dynamic>);
        })
        .toList();
  }

  Future<void> savePlaylists(List<Playlist> playlists) async {
    final prefs = await SharedPreferences.getInstance();
    final savedPlaylists = playlists
        .map((playlist) => jsonEncode(playlist.toJson()))
        .toList();

    await prefs.setStringList(playlistsKey, savedPlaylists);
  }

  Future<bool> loadDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(darkModeKey) ?? true;
  }

  Future<void> saveDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(darkModeKey, value);
  }

  Future<bool> loadAutoScanned() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(autoScannedKey) ?? false;
  }

  Future<void> saveAutoScanned(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(autoScannedKey, value);
  }
}
