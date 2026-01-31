import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/album_cover.dart';
import '../screens/player_screen.dart' show createPlayerRoute;
import '../providers/player_provider.dart';
import '../models/song.dart';
import '../l10n/app_localizations.dart';

class MiniPlayerBar extends StatefulWidget {
  const MiniPlayerBar({super.key});

  @override
  State<MiniPlayerBar> createState() => _MiniPlayerBarState();
}

class _MiniPlayerBarState extends State<MiniPlayerBar>
    with SingleTickerProviderStateMixin {
  double _dragOffset = 0;
  late AnimationController _snapController;
  Animation<double> _snapAnimation = const AlwaysStoppedAnimation(0);

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    )..addListener(() {
        setState(() => _dragOffset = _snapAnimation.value);
      });
  }

  @override
  void dispose() {
    _snapController.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details, PlayerProvider player) {
    final dx = details.delta.dx;
    // Resistance when no next/prev song
    if (dx < 0 && !player.hasNext) {
      setState(() => _dragOffset += dx * 0.25);
    } else if (dx > 0 && !player.hasPrevious) {
      setState(() => _dragOffset += dx * 0.25);
    } else {
      setState(() => _dragOffset += dx);
    }
  }

  void _onDragEnd(
      DragEndDetails details, PlayerProvider player, double slideWidth) {
    final velocity = details.velocity.pixelsPerSecond.dx;
    final threshold = slideWidth * 0.3;

    if ((velocity < -300 || _dragOffset < -threshold) && player.hasNext) {
      _snapTo(-slideWidth, () => player.next());
    } else if ((velocity > 300 || _dragOffset > threshold) &&
        player.hasPrevious) {
      _snapTo(slideWidth, () => player.previous());
    } else {
      _snapTo(0, null);
    }
  }

  void _snapTo(double target, VoidCallback? onComplete) {
    _snapAnimation = Tween<double>(
      begin: _dragOffset,
      end: target,
    ).animate(CurvedAnimation(
      parent: _snapController,
      curve: Curves.easeOutCubic,
    ));
    _snapController.forward(from: 0).then((_) {
      onComplete?.call();
      _dragOffset = 0;
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, player, _) {
        final song = player.currentSong;
        final progress = player.duration.inMilliseconds > 0
            ? (player.position.inMilliseconds /
                    player.duration.inMilliseconds)
                .clamp(0.0, 1.0)
            : 0.0;

        final nextSong = player.hasNext
            ? player.queue[(player.currentIndex + 1) % player.queue.length]
            : null;
        final prevSong = player.hasPrevious
            ? player.queue[(player.currentIndex - 1 + player.queue.length) % player.queue.length]
            : null;

        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(createPlayerRoute());
          },
          onVerticalDragEnd: (details) {
            if (details.velocity.pixelsPerSecond.dy < -300) {
              Navigator.of(context).push(createPlayerRoute());
            }
          },
          onHorizontalDragUpdate: (d) => _onDragUpdate(d, player),
          onHorizontalDragEnd: (d) {
            final width = MediaQuery.of(context).size.width;
            _onDragEnd(d, player, width);
          },
          child: ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.card.withValues(alpha: 0.85),
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16)),
                    ),
                    child: Row(
                      children: [
                        // Sliding song info area
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final slideWidth = constraints.maxWidth;
                              return ClipRect(
                                child: SizedBox(
                                  height: 44,
                                  child: Stack(
                                    children: [
                                      // Current song
                                      Positioned(
                                        left: _dragOffset,
                                        top: 0,
                                        bottom: 0,
                                        width: slideWidth,
                                        child: _buildSongRow(
                                          song,
                                          isHero: _dragOffset == 0,
                                        ),
                                      ),
                                      // Next song (from right)
                                      if (_dragOffset < 0 &&
                                          nextSong != null)
                                        Positioned(
                                          left: slideWidth + _dragOffset,
                                          top: 0,
                                          bottom: 0,
                                          width: slideWidth,
                                          child: _buildSongRow(nextSong),
                                        ),
                                      // Previous song (from left)
                                      if (_dragOffset > 0 &&
                                          prevSong != null)
                                        Positioned(
                                          left: -slideWidth + _dragOffset,
                                          top: 0,
                                          bottom: 0,
                                          width: slideWidth,
                                          child: _buildSongRow(prevSong),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        // Play/Pause button (fixed)
                        GestureDetector(
                          onTap: song != null
                              ? () => player.togglePlayPause()
                              : null,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              player.isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Progress bar at bottom with glow
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress,
                      child: Container(
                        height: 2.5,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(2),
                            bottomRight: Radius.circular(2),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppColors.primary.withValues(alpha: 0.6),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSongRow(Song? song, {bool isHero = false}) {
    final cover = _buildCover(song);
    return Row(
      children: [
        isHero ? Hero(tag: 'player-cover', child: cover) : cover,
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                song?.title ?? AppLocalizations.of(context)!.miniPlayerNotPlaying,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.foreground,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 1),
              Text(
                song?.artist ?? '',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.mutedForeground,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCover(Song? song) {
    if (song != null &&
        song.coverPath != null &&
        File(song.coverPath!).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(song.coverPath!),
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const AlbumCover(
            width: 44,
            height: 44,
            borderRadius: 8,
            gradientIndex: 1,
            icon: Icons.music_note_rounded,
          ),
        ),
      );
    }
    return AlbumCover(
      width: 44,
      height: 44,
      borderRadius: 8,
      gradientIndex:
          song != null ? song.title.hashCode.abs() % 12 : 1,
      icon: Icons.music_note_rounded,
    );
  }
}
