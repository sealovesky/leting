import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/album_cover.dart';
import '../widgets/song_list_tile.dart';
import '../models/playlist.dart';
import '../providers/playlist_provider.dart';
import '../providers/player_provider.dart';
import '../providers/library_provider.dart';
import '../l10n/app_localizations.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final Playlist playlist;

  const PlaylistDetailScreen({super.key, required this.playlist});

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<PlaylistProvider>()
          .loadPlaylistSongs(widget.playlist.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer3<PlaylistProvider, PlayerProvider, LibraryProvider>(
        builder: (context, playlistProv, player, library, _) {
          final songs = playlistProv.currentPlaylistSongs;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.transparent,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back_ios_rounded,
                      color: AppColors.foreground),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                expandedHeight: 320,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF667EEA)
                              .withValues(alpha: 0.4),
                          AppColors.background,
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        AlbumCover(
                          width: 200,
                          height: 200,
                          borderRadius: 16,
                          gradientIndex: widget.playlist.gradientIndex,
                          icon: Icons.headphones_rounded,
                          label: widget.playlist.name,
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Icon(Icons.delete_outline_rounded,
                        color: AppColors.foreground),
                    onPressed: () => _confirmDelete(context),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Text(
                        widget.playlist.name,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.foreground,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.playlistDetailTotalSongs(songs.length),
                        style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.mutedForeground),
                      ),
                      if (widget.playlist.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.playlist.description!,
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.mutedForeground),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: songs.isNotEmpty
                                ? () => player.playSong(
                                    songs.first,
                                    queue: songs,
                                    index: 0)
                                : null,
                            child: Container(
                              height: 44,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 28),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius:
                                    BorderRadius.circular(999),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.play_arrow_rounded,
                                      color: Colors.white,
                                      size: 22),
                                  const SizedBox(width: 4),
                                  Text(
                                    l10n.playlistDetailPlayAll,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.cardSecondary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                                Icons.shuffle_rounded,
                                size: 20,
                                color: AppColors.mutedForeground),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              if (songs.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.music_off_rounded,
                            size: 48,
                            color: AppColors.mutedForeground),
                        const SizedBox(height: 12),
                        Text(l10n.playlistDetailEmpty,
                            style: const TextStyle(
                                fontSize: 14,
                                color:
                                    AppColors.mutedForeground)),
                      ],
                    ),
                  ),
                ),
              if (songs.isNotEmpty)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final song = songs[index];
                      final isPlaying =
                          player.currentSong?.id == song.id &&
                              player.isPlaying;
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20),
                        child: SongListTile(
                          song: song,
                          isPlaying: isPlaying,
                          showDuration: true,
                          isFavorite: library.isFavSync(song.id),
                          onFavoriteToggle: () =>
                              library.toggleFavorite(song.id),
                          onTap: () => player.playSong(song,
                              queue: songs, index: index),
                          onLongPress: () =>
                              showSongOptionsSheet(context, song),
                          onDelete: () => playlistProv
                              .removeSongFromPlaylist(
                                  widget.playlist.id, song.id),
                        ),
                      );
                    },
                    childCount: songs.length,
                  ),
                ),
              const SliverToBoxAdapter(
                  child: SizedBox(height: 32)),
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(l10n.playlistDetailDelete,
            style: TextStyle(color: AppColors.foreground)),
        content: Text(l10n.playlistDetailDeleteConfirm(widget.playlist.name),
            style:
                const TextStyle(color: AppColors.mutedForeground)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.commonCancel,
                style:
                    const TextStyle(color: AppColors.mutedForeground)),
          ),
          TextButton(
            onPressed: () {
              context
                  .read<PlaylistProvider>()
                  .deletePlaylist(widget.playlist.id);
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: Text(l10n.commonDelete,
                style: const TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}
