import 'package:flutter/material.dart';

import '../services/music_service.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({
    super.key,
    required this.musicService,
    required this.onTap,
  });

  final MusicService musicService;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final song = musicService.currentSong;

    if (song == null) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      child: ListTile(
        tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        leading: const Icon(Icons.album),
        title: Text(
          song.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(song.artist),
        trailing: IconButton(
          onPressed: musicService.togglePlayPause,
          icon: Icon(
            musicService.isPlaying ? Icons.pause : Icons.play_arrow,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
