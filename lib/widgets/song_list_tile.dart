import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../theme/app_theme.dart';
import '../providers/playlist_provider.dart';
import '../l10n/app_localizations.dart';
import 'album_cover.dart';

class SongListTile extends StatelessWidget {
  final Song song;
  final int? index;
  final bool isPlaying;
  final bool isFavorite;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onMore;
  final VoidCallback? onDelete;
  final VoidCallback? onFavoriteToggle;
  final bool showDuration;

  const SongListTile({
    super.key,
    required this.song,
    this.index,
    this.isPlaying = false,
    this.isFavorite = false,
    this.onTap,
    this.onLongPress,
    this.onMore,
    this.onDelete,
    this.onFavoriteToggle,
    this.showDuration = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        height: 68,
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isPlaying
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: isPlaying
              ? Border.all(color: AppColors.primary.withValues(alpha: 0.2))
              : null,
        ),
        child: Row(
          children: [
            // Cover
            _buildCover(),
            const SizedBox(width: 12),
            // Title & Artist
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          isPlaying ? FontWeight.w600 : FontWeight.normal,
                      color:
                          isPlaying ? AppColors.primary : AppColors.foreground,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    song.artist,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.mutedForeground),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Duration or action
            if (showDuration)
              Text(
                song.durationFormatted,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.mutedForeground),
              ),
            if (isPlaying)
              const Icon(Icons.graphic_eq_rounded,
                  size: 18, color: AppColors.primary),
            if (onFavoriteToggle != null)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: GestureDetector(
                  onTap: onFavoriteToggle,
                  child: Icon(
                    isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    size: 18,
                    color: isFavorite
                        ? AppColors.primary
                        : AppColors.mutedForeground,
                  ),
                ),
              ),
            if (onDelete != null && !isPlaying)
              GestureDetector(
                onTap: onDelete,
                child: const Icon(Icons.delete_outline_rounded,
                    size: 18, color: AppColors.mutedForeground),
              ),
            if (onMore != null)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: GestureDetector(
                  onTap: onMore,
                  child: const Icon(Icons.more_vert_rounded,
                      size: 18, color: AppColors.mutedForeground),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCover() {
    if (song.coverPath != null && File(song.coverPath!).existsSync()) {
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
      gradientIndex: song.title.hashCode.abs() % 12,
      icon: Icons.music_note_rounded,
    );
  }
}

void showSongOptionsSheet(BuildContext context, Song song) {
  final l10n = AppLocalizations.of(context)!;
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Song info header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.foreground,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          song.artist,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.mutedForeground,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: AppColors.border, height: 1),
            // Add to playlist option
            ListTile(
              leading: Icon(Icons.playlist_add_rounded,
                  color: AppColors.foreground),
              title: Text(l10n.songOptionsAddToPlaylist,
                  style: TextStyle(color: AppColors.foreground)),
              onTap: () {
                Navigator.of(ctx).pop();
                _showPlaylistPicker(context, song);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}

void _showPlaylistPicker(BuildContext context, Song song) {
  final l10n = AppLocalizations.of(context)!;
  final playlistProv = context.read<PlaylistProvider>();
  final playlists = playlistProv.playlists;

  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Text(
                l10n.songOptionsSelectPlaylist,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.foreground,
                ),
              ),
            ),
            Divider(color: AppColors.border, height: 1),
            if (playlists.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  l10n.songOptionsNoPlaylist,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.mutedForeground,
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: playlists.length,
                  itemBuilder: (_, index) {
                    final playlist = playlists[index];
                    return ListTile(
                      leading: Icon(Icons.queue_music_rounded,
                          color: AppColors.foreground),
                      title: Text(playlist.name,
                          style:
                              TextStyle(color: AppColors.foreground)),
                      onTap: () async {
                        await playlistProv.addSongToPlaylist(
                            playlist.id, song.id);
                        if (ctx.mounted) Navigator.of(ctx).pop();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.songOptionsAddedTo(playlist.name)),
                              backgroundColor: AppColors.cardSecondary,
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}
