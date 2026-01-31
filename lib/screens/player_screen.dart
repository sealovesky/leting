import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/album_cover.dart';
import '../models/play_mode.dart';
import '../providers/player_provider.dart';
import '../providers/library_provider.dart';
import '../services/lyrics_service.dart';
import '../l10n/app_localizations.dart';

Route createPlayerRoute() {
  return PageRouteBuilder(
    pageBuilder: (_, __, ___) => const PlayerScreen(),
    transitionsBuilder: (_, animation, __, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        )),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 350),
    reverseTransitionDuration: const Duration(milliseconds: 300),
  );
}

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final LyricsService _lyricsService = LyricsService();
  List<LyricLine> _lyrics = [];
  String? _loadedForPath;
  final ScrollController _lyricsScrollController = ScrollController();
  int _lastHighlightedIndex = -1;
  bool _userScrolling = false;
  Timer? _scrollResumeTimer;
  bool _isSeeking = false;
  double _seekValue = 0;

  @override
  void initState() {
    super.initState();
    _lyricsScrollController.addListener(_onScrollUpdate);
  }

  @override
  void dispose() {
    _lyricsScrollController.removeListener(_onScrollUpdate);
    _lyricsScrollController.dispose();
    _scrollResumeTimer?.cancel();
    super.dispose();
  }

  void _onScrollUpdate() {
    if (_userScrolling) {
      setState(() {});
    }
  }

  void _loadLyricsIfNeeded(String? filePath) {
    if (filePath == null || filePath == _loadedForPath) return;
    _loadedForPath = filePath;
    _lastHighlightedIndex = -1;
    _userScrolling = false;
    _lyricsService.loadLyrics(filePath).then((lyrics) {
      if (mounted) setState(() => _lyrics = lyrics);
    });
  }

  void _scrollToLine(int index) {
    if (index < 0 || !_lyricsScrollController.hasClients) return;
    if (index == _lastHighlightedIndex) return;
    if (_userScrolling) return;
    _lastHighlightedIndex = index;
    final viewportHeight =
        _lyricsScrollController.position.viewportDimension;
    final targetOffset = (index * 36.0 - viewportHeight / 2 + 18.0).clamp(
      0.0,
      _lyricsScrollController.position.maxScrollExtent,
    );
    _lyricsScrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void _onUserScroll() {
    if (!_userScrolling) {
      _userScrolling = true;
      setState(() {});
    }
    _scrollResumeTimer?.cancel();
    _scrollResumeTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _userScrolling = false;
          _lastHighlightedIndex = -1;
        });
      }
    });
  }

  int _getCenteredLyricIndex() {
    if (!_lyricsScrollController.hasClients || _lyrics.isEmpty) return -1;
    final offset = _lyricsScrollController.offset;
    final viewportHeight =
        _lyricsScrollController.position.viewportDimension;
    final centerOffset = offset + viewportHeight / 2 - 16;
    final index = (centerOffset / 36.0).round();
    return index.clamp(0, _lyrics.length - 1);
  }

  void _seekToLyric(PlayerProvider player, int index) {
    if (index < 0 || index >= _lyrics.length) return;
    player.seek(_lyrics[index].time);
    _userScrolling = false;
    _lastHighlightedIndex = -1;
    _scrollResumeTimer?.cancel();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.foreground, size: 32),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: Column(
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: AppColors.mutedForeground.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(l10n.playerNowPlaying,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.mutedForeground)),
          ],
        ),
        actions: [
          Consumer<LibraryProvider>(
            builder: (context, library, _) {
              final song = context.read<PlayerProvider>().currentSong;
              if (song == null) return const SizedBox.shrink();
              final isFav = library.isFavSync(song.id);
              return IconButton(
                icon: Icon(
                  isFav
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: isFav ? AppColors.primary : AppColors.foreground,
                ),
                onPressed: () => library.toggleFavorite(song.id),
              );
            },
          ),
        ],
      ),
      body: Consumer<PlayerProvider>(
        builder: (context, player, _) {
          final song = player.currentSong;
          final title = song?.title ?? l10n.playerNoSong;
          final artist = song?.artist ?? '';
          final totalMs = player.duration.inMilliseconds;
          final posMs = player.position.inMilliseconds;
          final progress = totalMs > 0 ? posMs / totalMs : 0.0;

          _loadLyricsIfNeeded(song?.filePath);
          final currentLine =
              _lyricsService.currentLineIndex(_lyrics, player.position);
          final hasLyrics = _lyrics.isNotEmpty;

          if (hasLyrics) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToLine(currentLine);
            });
          }

          return SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 8),
                GestureDetector(
                  onVerticalDragEnd: (details) {
                    if (details.velocity.pixelsPerSecond.dy > 300) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final screenH = MediaQuery.of(context).size.height;
                            final coverSize = hasLyrics
                                ? (screenH * 0.22).clamp(100.0, 180.0)
                                : (screenH * 0.35).clamp(120.0, 280.0);
                            return Hero(
                              tag: 'player-cover',
                              child: _buildCover(song, coverSize),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.foreground,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        artist,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: hasLyrics
                      ? _buildLyricsArea(currentLine, player)
                      : const SizedBox.shrink(),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildControls(player, song, progress, totalMs),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLyricsArea(int currentLine, PlayerProvider player) {
    final l10n = AppLocalizations.of(context)!;
    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is UserScrollNotification ||
                  notification is ScrollUpdateNotification &&
                      notification.dragDetails != null) {
                _onUserScroll();
              }
              return false;
            },
            child: ListView.builder(
              controller: _lyricsScrollController,
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: _lyrics.length,
              itemExtent: 36,
              itemBuilder: (_, index) {
                final isActive = index == currentLine;
                final centeredIdx = _userScrolling
                    ? _getCenteredLyricIndex()
                    : -1;
                final isCentered =
                    _userScrolling && index == centeredIdx && !isActive;

                Color textColor;
                double fontSize;
                FontWeight fontWeight;

                if (isActive) {
                  textColor = AppColors.foreground;
                  fontSize = 16;
                  fontWeight = FontWeight.w600;
                } else if (isCentered) {
                  textColor = AppColors.primary;
                  fontSize = 15;
                  fontWeight = FontWeight.w500;
                } else {
                  textColor = AppColors.mutedForeground
                      .withValues(alpha: 0.6);
                  fontSize = 14;
                  fontWeight = FontWeight.normal;
                }

                return GestureDetector(
                  onTap: () => _seekToLyric(player, index),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: fontWeight,
                        color: textColor,
                      ),
                      child: Text(
                        _lyrics[index].text,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        // Top fade overlay
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 40,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.background,
                    AppColors.background.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Bottom fade overlay
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 40,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    AppColors.background,
                    AppColors.background.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Floating buttons when user scrolled away
        if (_userScrolling)
          Positioned(
            right: 12,
            bottom: 8,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    final idx = _getCenteredLyricIndex();
                    _seekToLyric(player, idx);
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.play_arrow_rounded,
                        size: 18, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    _userScrolling = false;
                    _lastHighlightedIndex = -1;
                    _scrollResumeTimer?.cancel();
                    setState(() {});
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.my_location_rounded,
                            size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(l10n.playerBackToCurrent,
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.primary)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildControls(
      PlayerProvider player, dynamic song, double progress, int totalMs) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 4,
            thumbShape:
                const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape:
                const RoundSliderOverlayShape(overlayRadius: 14),
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.border,
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withValues(alpha: 0.2),
          ),
          child: Slider(
            value: (_isSeeking ? _seekValue : progress).clamp(0.0, 1.0),
            onChangeStart: song != null
                ? (v) => setState(() {
                      _isSeeking = true;
                      _seekValue = v;
                    })
                : null,
            onChanged: song != null
                ? (v) => setState(() => _seekValue = v)
                : null,
            onChangeEnd: song != null
                ? (v) {
                    final newPos = Duration(
                        milliseconds: (v * totalMs).round());
                    player.seek(newPos);
                    setState(() => _isSeeking = false);
                  }
                : null,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isSeeking
                    ? _formatDuration(Duration(
                        milliseconds: (_seekValue * totalMs).round()))
                    : _formatDuration(player.position),
                style: const TextStyle(
                    fontSize: 12, color: AppColors.mutedForeground),
              ),
              Text(
                _formatDuration(player.duration),
                style: const TextStyle(
                    fontSize: 12, color: AppColors.mutedForeground),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(
                _playModeIcon(player.playMode),
                color: player.playMode != PlayMode.sequence
                    ? AppColors.primary
                    : AppColors.mutedForeground,
                size: 22,
              ),
              onPressed: () => player.cyclePlayMode(),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => player.previous(),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.cardSecondary,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.skip_previous_rounded,
                    color: AppColors.foreground, size: 28),
              ),
            ),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: () => player.togglePlayPause(),
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  player.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: () => player.next(),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.cardSecondary,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.skip_next_rounded,
                    color: AppColors.foreground, size: 28),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.queue_music_rounded,
                  color: AppColors.mutedForeground, size: 22),
              onPressed: () {},
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.volume_down_rounded,
                size: 20, color: AppColors.mutedForeground),
            const SizedBox(width: 8),
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 5),
                  overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 12),
                  activeTrackColor: AppColors.mutedForeground,
                  inactiveTrackColor: AppColors.border,
                  thumbColor: AppColors.mutedForeground,
                  overlayColor:
                      AppColors.mutedForeground.withValues(alpha: 0.15),
                ),
                child: Slider(
                  value: player.volume,
                  onChanged: (v) => player.setVolume(v),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.volume_up_rounded,
                size: 20, color: AppColors.mutedForeground),
          ],
        ),
      ],
    );
  }

  Widget _buildCover(dynamic song, double size) {
    if (song != null &&
        song.coverPath != null &&
        File(song.coverPath!).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(
          File(song.coverPath!),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => AlbumCover(
            width: size,
            height: size,
            borderRadius: 16,
            gradientIndex: 1,
            icon: Icons.music_note_rounded,
          ),
        ),
      );
    }
    return AlbumCover(
      width: size,
      height: size,
      borderRadius: 16,
      gradientIndex: song != null ? song.title.hashCode.abs() % 12 : 1,
      icon: Icons.music_note_rounded,
    );
  }

  IconData _playModeIcon(PlayMode mode) {
    switch (mode) {
      case PlayMode.sequence:
        return Icons.arrow_forward_rounded;
      case PlayMode.loop:
        return Icons.repeat_rounded;
      case PlayMode.single:
        return Icons.repeat_one_rounded;
      case PlayMode.shuffle:
        return Icons.shuffle_rounded;
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
