import 'package:flutter/material.dart';

import '../services/music_service.dart';
import '../theme/app_theme.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({
    super.key,
    required this.musicService,
  });

  final MusicService musicService;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
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
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final song = widget.musicService.currentSong;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Now Playing'),
      ),
      body: song == null
          ? const Center(child: Text('No song selected'))
          : LayoutBuilder(
              builder: (context, constraints) {
                final size = constraints.maxWidth < 420
                    ? constraints.maxWidth * 0.62
                    : 260.0;
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _SpinningDisc(
                          size: size,
                          spinning: widget.musicService.isPlaying,
                          label: song.title,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          song.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(song.artist),
                        const SizedBox(height: 16),
                        _ProgressBar(musicService: widget.musicService),
                        const SizedBox(height: 16),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  iconSize: 40,
                                  onPressed: widget.musicService.previousSong,
                                  icon: const Icon(Icons.skip_previous),
                                ),
                                const SizedBox(width: 8),
                                IconButton.filled(
                                  iconSize: 44,
                                  onPressed: widget.musicService.togglePlayPause,
                                  icon: Icon(
                                    widget.musicService.isPlaying
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  iconSize: 40,
                                  onPressed: widget.musicService.nextSong,
                                  icon: const Icon(Icons.skip_next),
                                ),
                              ],
                            ),
                            Positioned(
                              left: 0,
                              child: IconButton(
                                onPressed: widget.musicService.toggleLoop,
                                color: widget.musicService.loopOne
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                                icon: const Icon(Icons.repeat_one),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              child: IconButton(
                                onPressed: widget.musicService.toggleShuffle,
                                color: widget.musicService.shuffle
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                                icon: const Icon(Icons.shuffle),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(Icons.volume_down),
                            Expanded(
                              child: Slider(
                                value: widget.musicService.volume,
                                onChanged: widget.musicService.changeVolume,
                              ),
                            ),
                            const Icon(Icons.volume_up),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _QueuePanel(musicService: widget.musicService),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.musicService});

  final MusicService musicService;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: musicService.positionStream,
      builder: (context, positionSnapshot) {
        final position = positionSnapshot.data ?? Duration.zero;
        return StreamBuilder<Duration?>(
          stream: musicService.durationStream,
          builder: (context, durationSnapshot) {
            final duration = durationSnapshot.data ?? Duration.zero;
            final max = duration.inMilliseconds.toDouble().clamp(1, double.infinity);
            final value = position.inMilliseconds.toDouble().clamp(0, max);
            return Column(
              children: [
                Slider(
                  value: value.toDouble(),
                  max: max.toDouble(),
                  onChanged: (newValue) {
                    musicService.seekTo(Duration(milliseconds: newValue.round()));
                  },
                ),
                Row(
                  children: [
                    Text(_formatTime(position)),
                    const Spacer(),
                    Text(_formatTime(duration)),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatTime(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = duration.inHours;
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }
}

class _SpinningDisc extends StatefulWidget {
  const _SpinningDisc({
    required this.size,
    required this.spinning,
    required this.label,
  });

  final double size;
  final bool spinning;
  final String label;

  @override
  State<_SpinningDisc> createState() => _SpinningDiscState();
}

class _SpinningDiscState extends State<_SpinningDisc>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );
    if (widget.spinning) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant _SpinningDisc oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.spinning && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.spinning && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: RotationTransition(
        turns: _controller,
        child: CustomPaint(
          painter: _VinylPainter(accent: color),
          child: Center(
            child: SizedBox(
              width: widget.size * 0.36,
              height: widget.size * 0.36,
              child: ClipOval(
                child: ColoredBox(
                  color: color,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        widget.label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.brand(
                          context,
                          fontSize: widget.size * 0.055,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VinylPainter extends CustomPainter {
  _VinylPainter({required this.accent});

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Outer disc
    final disc = Paint()..color = const Color(0xFF111111);
    canvas.drawCircle(center, radius, disc);

    // Subtle highlight ring
    final highlight = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.08),
          Colors.transparent,
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, highlight);

    // Concentric grooves
    final groove = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    for (var r = radius * 0.45; r < radius - 2; r += radius * 0.025) {
      canvas.drawCircle(center, r, groove);
    }

    // Accent ring around the label
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..color = accent.withValues(alpha: 0.6)
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius * 0.2, ring);

    // Spindle hole
    final hole = Paint()..color = const Color(0xFF222222);
    canvas.drawCircle(center, radius * 0.025, hole);
  }

  @override
  bool shouldRepaint(covariant _VinylPainter oldDelegate) =>
      oldDelegate.accent != accent;
}

class _QueuePanel extends StatelessWidget {
  const _QueuePanel({required this.musicService});

  final MusicService musicService;

  @override
  Widget build(BuildContext context) {
    final queue = musicService.queueSongs;
    final current = musicService.queueIndex;
    final theme = Theme.of(context);

    if (queue.isEmpty) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.queue_music),
          title: Text('Queue is empty'),
        ),
      );
    }

    final previous = current > 0 ? queue[current - 1] : null;
    final next = current >= 0 && current < queue.length - 1
        ? queue[current + 1]
        : null;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                const Icon(Icons.queue_music),
                const SizedBox(width: 8),
                Text(
                  'Queue',
                  style: theme.textTheme.titleMedium,
                ),
                const Spacer(),
                Text(
                  '${current + 1} of ${queue.length}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (previous != null)
            _QueueRow(
              label: 'Previous',
              icon: Icons.skip_previous,
              title: previous.title,
              subtitle: previous.artist,
              onTap: musicService.previousSong,
            ),
          _QueueRow(
            label: 'Now playing',
            icon: Icons.equalizer,
            title: queue[current].title,
            subtitle: queue[current].artist,
            highlight: true,
          ),
          if (next != null)
            _QueueRow(
              label: 'Up next',
              icon: Icons.skip_next,
              title: next.title,
              subtitle: next.artist,
              onTap: musicService.nextSong,
            ),
          if (queue.length > 1) const Divider(height: 1),
          if (queue.length > 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                'Full queue',
                style: theme.textTheme.labelMedium,
              ),
            ),
          for (var i = 0; i < queue.length; i++)
            ListTile(
              dense: true,
              selected: i == current,
              leading: SizedBox(
                width: 28,
                child: Center(
                  child: i == current
                      ? Icon(Icons.play_arrow,
                          color: theme.colorScheme.primary)
                      : Text(
                          '${i + 1}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: i < current
                                ? theme.disabledColor
                                : theme.textTheme.bodySmall?.color,
                          ),
                        ),
                ),
              ),
              title: Text(
                queue[i].title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: i < current ? theme.disabledColor : null,
                  fontWeight: i == current ? FontWeight.bold : null,
                ),
              ),
              subtitle: Text(
                queue[i].artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: i == current
                  ? null
                  : () => musicService.playFromList(queue, i),
            ),
        ],
      ),
    );
  }
}

class _QueueRow extends StatelessWidget {
  const _QueueRow({
    required this.label,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.highlight = false,
  });

  final String label;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      tileColor: highlight
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4)
          : null,
      leading: Icon(
        icon,
        color: highlight ? theme.colorScheme.primary : null,
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: highlight ? FontWeight.bold : null,
        ),
      ),
      subtitle: Text('$label  ·  $subtitle'),
    );
  }
}
