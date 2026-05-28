import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/playlist.dart';
import '../models/song.dart';
import 'storage_service.dart';

class MusicService extends ChangeNotifier {
  MusicService(this.storageService) {
    player.playerStateStream.listen((state) {
      notifyListeners();
      if (state.processingState == ProcessingState.completed && !loopOne) {
        nextSong();
      }
    });
  }

  final StorageService storageService;
  final AudioPlayer player = AudioPlayer();

  List<Song> songs = [];
  List<Playlist> playlists = [];
  Set<String> favoriteSongIds = {};
  List<Song> queueSongs = [];
  int queueIndex = -1;
  bool loopOne = false;
  bool shuffle = false;
  double volume = 1;
  bool isPickingSongs = false;
  bool isScanningLibrary = false;
  int lastScanAddedCount = 0;
  int _idCounter = 0;
  static const _mediaStoreChannel = MethodChannel('cassette/media_store');

  Song? get currentSong {
    if (queueIndex < 0 || queueIndex >= queueSongs.length) return null;
    return queueSongs[queueIndex];
  }

  bool get isPlaying => player.playing;
  Stream<Duration> get positionStream => player.positionStream;
  Stream<Duration?> get durationStream => player.durationStream;

  Future<void> loadSavedData() async {
    songs = await storageService.loadSongs();
    favoriteSongIds = await storageService.loadFavorites();
    playlists = await storageService.loadPlaylists();
    _idCounter = songs.length;
    notifyListeners();

    if (supportsLibraryScan) {
      final alreadyScanned = await storageService.loadAutoScanned();
      if (!alreadyScanned) {
        await scanDeviceLibrary();
        await storageService.saveAutoScanned(true);
      }
    }
  }

  Future<void> pickSongsFromComputer() async {
    isPickingSongs = true;
    notifyListeners();
    try {
      final result = await FilePicker.pickFiles(
        allowMultiple: true,
        type: FileType.audio,
      );

      if (result == null) return;

      for (final file in result.files) {
        final url = file.path;
        if (url == null) continue;

        final title = file.name.replaceAll(RegExp(r'\.[^.]+$'), '');

        songs.add(
          Song(
            id: _newSongId(url, title),
            title: title,
            artist: 'Unknown artist',
            duration: Duration.zero,
            url: url,
          ),
        );
      }

      await storageService.saveSongs(songs);
    } finally {
      isPickingSongs = false;
      notifyListeners();
    }
  }

  bool get supportsLibraryScan =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> scanDeviceLibrary() async {
    debugPrint('scanDeviceLibrary: called (supports=$supportsLibraryScan, busy=$isScanningLibrary)');
    if (!supportsLibraryScan || isScanningLibrary) return;

    isScanningLibrary = true;
    lastScanAddedCount = 0;
    lastError = null;
    notifyListeners();

    try {
      debugPrint('scanDeviceLibrary: checking audio permission');
      var status = await Permission.audio.status;
      debugPrint('scanDeviceLibrary: audio status=$status');
      if (!status.isGranted) {
        status = await Permission.audio.request();
        debugPrint('scanDeviceLibrary: requested -> $status');
      }
      if (!status.isGranted) {
        lastError = 'Audio library permission was denied.';
        return;
      }

      debugPrint('scanDeviceLibrary: calling native queryAudio');
      final raw = await _mediaStoreChannel.invokeMethod<List<dynamic>>('queryAudio');
      final results = (raw ?? const <dynamic>[]).cast<Map<dynamic, dynamic>>();
      debugPrint('queryAudio returned ${results.length} entries');

      results.sort((a, b) {
        final pa = _folderPriority((a['data'] as String?) ?? '');
        final pb = _folderPriority((b['data'] as String?) ?? '');
        return pa.compareTo(pb);
      });

      final existingUrls = songs.map((s) => s.url).toSet();
      var added = 0;
      var skippedTooShort = 0;
      var skippedDuplicate = 0;
      const minDurationMs = 10000;
      for (final entry in results) {
        final duration = (entry['duration'] as num?)?.toInt() ?? 0;
        if (duration < minDurationMs) {
          skippedTooShort++;
          continue;
        }
        final url = (entry['uri'] as String?) ?? (entry['data'] as String?) ?? '';
        if (url.isEmpty || existingUrls.contains(url)) {
          skippedDuplicate++;
          continue;
        }
        existingUrls.add(url);
        songs.add(
          Song(
            id: 'mediastore_${entry['id']}',
            title: (entry['title'] as String?) ?? 'Unknown',
            artist: (entry['artist'] as String?) ?? 'Unknown artist',
            duration: Duration(milliseconds: duration),
            url: url,
          ),
        );
        added++;

        if (added % 10 == 0) {
          lastScanAddedCount = added;
          notifyListeners();
          await Future<void>.delayed(Duration.zero);
        }
      }
      debugPrint('scan filter: added=$added, tooShort=$skippedTooShort, dup=$skippedDuplicate');

      lastScanAddedCount = added;
      if (added > 0) {
        await storageService.saveSongs(songs);
      }
    } catch (e, st) {
      lastError = 'Library scan failed: $e';
      debugPrint('scanDeviceLibrary error: $e\n$st');
    } finally {
      isScanningLibrary = false;
      notifyListeners();
    }
  }

  Future<void> playSong(Song song) async {
    final index = songs.indexWhere((item) => item.id == song.id);
    if (index == -1) return;
    await playFromList(songs, index);
  }

  String? lastError;

  Future<void> playFromList(List<Song> list, int index) async {
    if (list.isEmpty || index < 0 || index >= list.length) return;

    queueSongs = [...list];
    queueIndex = index;
    lastError = null;
    notifyListeners();

    final song = queueSongs[queueIndex];
    if (_isLocalFileMissing(song)) {
      await _removeMissingSong(song, 'File not found on disk.');
      return;
    }

    try {
      await player.stop();
      await _setSource(song);
      await player.setVolume(volume);
      await player.play();
    } catch (e, st) {
      debugPrint('Failed to play "${song.title}" (${song.url}): $e\n$st');
      if (_isLocalFileMissing(song)) {
        await _removeMissingSong(song, 'File not found on disk.');
      } else {
        lastError = 'Could not play "${song.title}": $e';
        notifyListeners();
      }
    }
  }

  bool _isLocalFileMissing(Song song) {
    if (kIsWeb) return false;
    final uri = Uri.tryParse(song.url);
    final scheme = uri?.scheme.toLowerCase() ?? '';
    if (scheme == 'http' ||
        scheme == 'https' ||
        scheme == 'content' ||
        scheme == 'blob') {
      return false;
    }
    final path = scheme == 'file' ? uri!.toFilePath() : song.url;
    return !File(path).existsSync();
  }

  Future<void> _removeMissingSong(Song song, String reason) async {
    songs.removeWhere((s) => s.id == song.id);
    queueSongs.removeWhere((s) => s.id == song.id);
    if (queueIndex >= queueSongs.length) {
      queueIndex = queueSongs.isEmpty ? -1 : queueSongs.length - 1;
    }
    favoriteSongIds.remove(song.id);
    for (var i = 0; i < playlists.length; i++) {
      final filtered =
          playlists[i].songIds.where((id) => id != song.id).toList();
      if (filtered.length != playlists[i].songIds.length) {
        playlists[i] = playlists[i].copyWith(songIds: filtered);
      }
    }
    await storageService.saveSongs(songs);
    await storageService.saveFavorites(favoriteSongIds);
    await storageService.savePlaylists(playlists);
    lastError = '${song.title}: $reason Removed from library.';
    notifyListeners();
  }

  Future<void> _setSource(Song song) async {
    final tag = MediaItem(
      id: song.id,
      title: song.title,
      artist: song.artist,
      duration: song.duration > Duration.zero ? song.duration : null,
    );
    final uri = Uri.tryParse(song.url);
    final scheme = uri?.scheme.toLowerCase() ?? '';
    final AudioSource source;
    if (kIsWeb ||
        scheme == 'http' ||
        scheme == 'https' ||
        scheme == 'blob' ||
        scheme == 'content') {
      source = AudioSource.uri(Uri.parse(song.url), tag: tag);
    } else if (scheme == 'file') {
      source = AudioSource.uri(uri!, tag: tag);
    } else {
      source = AudioSource.file(song.url, tag: tag);
    }
    await player.setAudioSource(source);
  }

  Future<void> togglePlayPause() async {
    if (currentSong == null) return;

    if (player.playing) {
      await player.pause();
    } else {
      await player.play();
    }

    notifyListeners();
  }

  Future<void> nextSong() async {
    if (queueSongs.isEmpty) return;

    if (shuffle && queueSongs.length > 1) {
      var next = queueIndex;
      while (next == queueIndex) {
        next = (queueSongs.length * (DateTime.now().microsecondsSinceEpoch % 1000) / 1000).floor();
      }
      queueIndex = next;
      await playFromList(queueSongs, queueIndex);
      return;
    }

    final nextIndex = queueIndex + 1;
    queueIndex = nextIndex >= queueSongs.length ? 0 : nextIndex;
    await playFromList(queueSongs, queueIndex);
  }

  Future<void> previousSong() async {
    if (queueSongs.isEmpty) return;

    final previousIndex = queueIndex - 1;
    queueIndex = previousIndex < 0 ? queueSongs.length - 1 : previousIndex;
    await playFromList(queueSongs, queueIndex);
  }

  Future<void> toggleLoop() async {
    loopOne = !loopOne;
    await player.setLoopMode(loopOne ? LoopMode.one : LoopMode.off);
    notifyListeners();
  }

  void toggleShuffle() {
    shuffle = !shuffle;
    notifyListeners();
  }

  Future<void> changeVolume(double newVolume) async {
    volume = newVolume;
    await player.setVolume(volume);
    notifyListeners();
  }

  Future<void> seekTo(Duration position) async {
    await player.seek(position);
  }

  Future<void> toggleFavorite(Song song) async {
    if (favoriteSongIds.contains(song.id)) {
      favoriteSongIds.remove(song.id);
    } else {
      favoriteSongIds.add(song.id);
    }

    await storageService.saveFavorites(favoriteSongIds);
    notifyListeners();
  }

  bool isFavorite(Song song) {
    return favoriteSongIds.contains(song.id);
  }

  Future<void> createPlaylist(String name) async {
    if (name.trim().isEmpty) return;

    playlists.add(
      Playlist(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: name.trim(),
        songIds: [],
      ),
    );

    await storageService.savePlaylists(playlists);
    notifyListeners();
  }

  Future<void> deletePlaylist(Playlist playlist) async {
    playlists.removeWhere((item) => item.id == playlist.id);
    await storageService.savePlaylists(playlists);
    notifyListeners();
  }

  Future<void> addSongToPlaylist(Song song, Playlist playlist) async {
    final index = playlists.indexWhere((item) => item.id == playlist.id);
    if (index == -1) return;

    final songIds = [...playlists[index].songIds];
    if (!songIds.contains(song.id)) {
      songIds.add(song.id);
    }

    playlists[index] = playlists[index].copyWith(songIds: songIds);
    await storageService.savePlaylists(playlists);
    notifyListeners();
  }

  Future<void> removeSongFromPlaylist(Song song, Playlist playlist) async {
    final index = playlists.indexWhere((item) => item.id == playlist.id);
    if (index == -1) return;

    final songIds = playlists[index].songIds.where((id) => id != song.id).toList();
    playlists[index] = playlists[index].copyWith(songIds: songIds);

    await storageService.savePlaylists(playlists);
    notifyListeners();
  }

  List<Song> songsInPlaylist(Playlist playlist) {
    return songs.where((song) => playlist.songIds.contains(song.id)).toList();
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  String _newSongId(String url, String title) {
    _idCounter++;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${timestamp}_${_idCounter}_${url.hashCode}_${title.hashCode}';
  }

  static const _priorityFolders = [
    '/music/',
    '/download/',
    '/downloads/',
  ];

  int _folderPriority(String path) {
    final lower = path.toLowerCase();
    for (final folder in _priorityFolders) {
      if (lower.contains(folder)) return 0;
    }
    return 1;
  }
}
