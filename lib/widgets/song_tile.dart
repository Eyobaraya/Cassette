import 'package:flutter/material.dart';

import '../models/song.dart';

class SongTile extends StatelessWidget {
  const SongTile({
    super.key,
    required this.song,
    required this.isFavorite,
    required this.onTap,
    required this.onFavoriteTap,
    required this.onAddToPlaylistTap,
    required this.onRemoveTap,
  });

  final Song song;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;
  final VoidCallback onAddToPlaylistTap;
  final VoidCallback onRemoveTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const CircleAvatar(
        child: Icon(Icons.music_note),
      ),
      title: Text(
        song.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(song.artist),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Favorite',
            onPressed: onFavoriteTap,
            icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
          ),
          PopupMenuButton<String>(
            tooltip: 'More',
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'playlist') onAddToPlaylistTap();
              if (value == 'remove') onRemoveTap();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'playlist',
                child: ListTile(
                  leading: Icon(Icons.playlist_add),
                  title: Text('Add to playlist'),
                ),
              ),
              PopupMenuItem(
                value: 'remove',
                child: ListTile(
                  leading: Icon(Icons.delete_outline),
                  title: Text('Remove from library'),
                ),
              ),
            ],
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}
