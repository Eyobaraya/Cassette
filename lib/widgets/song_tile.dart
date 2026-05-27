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
  });

  final Song song;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;
  final VoidCallback onAddToPlaylistTap;

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
          IconButton(
            tooltip: 'Add to playlist',
            onPressed: onAddToPlaylistTap,
            icon: const Icon(Icons.playlist_add),
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}
