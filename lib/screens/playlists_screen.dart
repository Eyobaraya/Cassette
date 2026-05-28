import 'package:flutter/material.dart';

import '../services/music_service.dart';

class PlaylistsScreen extends StatelessWidget {
  const PlaylistsScreen({
    super.key,
    required this.musicService,
  });

  final MusicService musicService;

  @override
  Widget build(BuildContext context) {
    final likedSongs = musicService.songs
        .where((song) => musicService.favoriteSongIds.contains(song.id))
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            onPressed: () => _showCreatePlaylistDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Create playlist'),
          ),
        ),
        Expanded(
          child: ListView(
            children: [
              ExpansionTile(
                initiallyExpanded: true,
                leading: const Icon(Icons.favorite),
                title: const Text('Liked Songs'),
                subtitle: Text('${likedSongs.length} songs'),
                children: [
                  if (likedSongs.isEmpty)
                    const ListTile(title: Text('No liked songs yet'))
                  else
                    for (var i = 0; i < likedSongs.length; i++)
                      ListTile(
                        leading: const Icon(Icons.music_note),
                        title: Text(likedSongs[i].title),
                        subtitle: Text(likedSongs[i].artist),
                        onTap: () => musicService.playFromList(likedSongs, i),
                      ),
                ],
              ),
              if (musicService.playlists.isEmpty)
                const ListTile(title: Text('No playlists yet'))
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: musicService.playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = musicService.playlists[index];
                    final songs = musicService.songsInPlaylist(playlist);

                    return ExpansionTile(
                      leading: const Icon(Icons.queue_music),
                      title: Text(playlist.name),
                      subtitle: Text('${songs.length} songs'),
                      trailing: IconButton(
                        onPressed: () => musicService.deletePlaylist(playlist),
                        icon: const Icon(Icons.delete_outline),
                      ),
                      children: [
                        if (songs.isEmpty)
                          const ListTile(title: Text('No songs in this playlist'))
                        else
                          for (var i = 0; i < songs.length; i++)
                            ListTile(
                              leading: const Icon(Icons.music_note),
                              title: Text(songs[i].title),
                              subtitle: Text(songs[i].artist),
                              onTap: () => musicService.playFromList(songs, i),
                              trailing: IconButton(
                                onPressed: () {
                                  musicService.removeSongFromPlaylist(
                                    songs[i],
                                    playlist,
                                  );
                                },
                                icon: const Icon(Icons.remove_circle_outline),
                              ),
                            ),
                      ],
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showCreatePlaylistDialog(BuildContext context) async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => const _NewPlaylistDialog(),
    );

    if (name == null || name.trim().isEmpty) return;
    await WidgetsBinding.instance.endOfFrame;
    await musicService.createPlaylist(name);
  }
}

class _NewPlaylistDialog extends StatefulWidget {
  const _NewPlaylistDialog();

  @override
  State<_NewPlaylistDialog> createState() => _NewPlaylistDialogState();
}

class _NewPlaylistDialogState extends State<_NewPlaylistDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New playlist'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'Playlist name'),
        onSubmitted: (value) => Navigator.pop(context, value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Create'),
        ),
      ],
    );
  }
}
