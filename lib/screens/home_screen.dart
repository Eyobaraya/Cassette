import 'package:flutter/material.dart';

import '../models/song.dart';
import '../services/music_service.dart';
import '../theme/app_theme.dart';
import '../widgets/mini_player.dart';
import '../widgets/song_tile.dart';
import 'player_screen.dart';
import 'playlists_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.musicService,
    required this.darkMode,
    required this.onThemeChanged,
  });

  final MusicService musicService;
  final bool darkMode;
  final ValueChanged<bool> onThemeChanged;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;
  SongSortOption sortOption = SongSortOption.recentlyAdded;
  String? _shownError;

  @override
  void initState() {
    super.initState();
    widget.musicService.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.musicService.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {});
    final error = widget.musicService.lastError;
    if (error != null && error != _shownError) {
      _shownError = error;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _songsPage(),
      PlaylistsScreen(musicService: widget.musicService),
      SettingsScreen(
        darkMode: widget.darkMode,
        onThemeChanged: widget.onThemeChanged,
      ),
    ];

    final canScan = widget.musicService.supportsLibraryScan;
    final busy = widget.musicService.isPickingSongs ||
        widget.musicService.isScanningLibrary;

    return Scaffold(
      appBar: AppBar(
        title: Text('Cassette', style: AppTheme.brand(context, fontSize: 24)),
        actions: [
          if (canScan)
            IconButton(
              tooltip: 'Scan device',
              onPressed: widget.musicService.isScanningLibrary
                  ? null
                  : _scanDevice,
              icon: const Icon(Icons.sync),
            ),
          IconButton(
            tooltip: 'Pick songs',
            onPressed: widget.musicService.pickSongsFromComputer,
            icon: const Icon(Icons.library_music),
          ),
        ],
      ),
      body: Column(
        children: [
          if (busy) const LinearProgressIndicator(minHeight: 3),
          if (widget.musicService.isScanningLibrary)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                'Scanning device... ${widget.musicService.lastScanAddedCount} songs found',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          Expanded(child: pages[selectedIndex]),
          MiniPlayer(
            musicService: widget.musicService,
            onTap: _openPlayer,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() => selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.music_note),
            label: 'Songs',
          ),
          NavigationDestination(
            icon: Icon(Icons.queue_music),
            label: 'Playlists',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _songsPage() {
    final visibleSongs = [...widget.musicService.songs];
    _sortSongs(visibleSongs);

    if (widget.musicService.songs.isEmpty) {
      if (widget.musicService.isScanningLibrary) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Scanning your device for music...',
              textAlign: TextAlign.center,
            ),
          ),
        );
      }
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.audio_file, size: 64),
              const SizedBox(height: 16),
              const Text(
                'No songs yet',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Pick songs from your computer to try the player.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: widget.musicService.isPickingSongs
                    ? null
                    : widget.musicService.pickSongsFromComputer,
                icon: const Icon(Icons.folder_open),
                label: Text(
                  widget.musicService.isPickingSongs ? 'Loading...' : 'Pick songs',
                ),
              ),
              if (widget.musicService.supportsLibraryScan) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: widget.musicService.isScanningLibrary
                      ? null
                      : _scanDevice,
                  icon: const Icon(Icons.sync),
                  label: Text(
                    widget.musicService.isScanningLibrary
                        ? 'Scanning...'
                        : 'Scan device',
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              const Text('Sort by:'),
              const SizedBox(width: 12),
              DropdownButton<SongSortOption>(
                value: sortOption,
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => sortOption = value);
                },
                items: const [
                  DropdownMenuItem(
                    value: SongSortOption.recentlyAdded,
                    child: Text('Recently added'),
                  ),
                  DropdownMenuItem(
                    value: SongSortOption.titleAZ,
                    child: Text('Title A-Z'),
                  ),
                  DropdownMenuItem(
                    value: SongSortOption.titleZA,
                    child: Text('Title Z-A'),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: visibleSongs.length,
            itemBuilder: (context, index) {
              final song = visibleSongs[index];

              return SongTile(
                song: song,
                isFavorite: widget.musicService.isFavorite(song),
                onTap: () => widget.musicService.playFromList(visibleSongs, index),
                onFavoriteTap: () => widget.musicService.toggleFavorite(song),
                onAddToPlaylistTap: () => _showPlaylistPicker(song),
              );
            },
          ),
        ),
      ],
    );
  }

  void _sortSongs(List<Song> songs) {
    if (sortOption == SongSortOption.recentlyAdded) {
      songs.sort((a, b) => b.id.compareTo(a.id));
      return;
    }

    songs.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    if (sortOption == SongSortOption.titleZA) {
      songs.setAll(0, songs.reversed);
    }
  }

  Future<void> _scanDevice() async {
    final messenger = ScaffoldMessenger.of(context);
    await widget.musicService.scanDeviceLibrary();
    if (!mounted) return;
    final error = widget.musicService.lastError;
    final added = widget.musicService.lastScanAddedCount;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          error ?? (added == 0 ? 'No new songs found.' : 'Added $added songs.'),
        ),
      ),
    );
  }

  void _openPlayer() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlayerScreen(musicService: widget.musicService),
      ),
    );
  }

  Future<void> _showPlaylistPicker(Song song) async {
    await showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const ListTile(
                title: Text('Add to playlist'),
              ),
              for (final playlist in widget.musicService.playlists)
                ListTile(
                  leading: const Icon(Icons.queue_music),
                  title: Text(playlist.name),
                  onTap: () {
                    widget.musicService.addSongToPlaylist(song, playlist);
                    Navigator.pop(context);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('Create new playlist'),
                onTap: () {
                  Navigator.pop(context);
                  _showCreatePlaylistDialog(song);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showCreatePlaylistDialog(Song song) async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New playlist'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Playlist name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                await widget.musicService.createPlaylist(controller.text);
                final playlist = widget.musicService.playlists.lastOrNull;
                if (playlist != null) {
                  await widget.musicService.addSongToPlaylist(song, playlist);
                }
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    controller.dispose();
  }
}

enum SongSortOption {
  recentlyAdded,
  titleAZ,
  titleZA,
}
