import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../theme/app_theme.dart';
import '../widgets/song_list_tile.dart';
import '../providers/player_provider.dart';
import '../providers/library_provider.dart';
import '../l10n/app_localizations.dart';

class PlaylistScreen extends StatefulWidget {
  const PlaylistScreen({super.key});

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  bool _isEditing = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer2<PlayerProvider, LibraryProvider>(
      builder: (context, player, library, _) {
        final queue = player.queue;

        return Column(
          children: [
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.playlistTitle,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.foreground,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (queue.isNotEmpty)
                        GestureDetector(
                          onTap: () =>
                              setState(() => _isEditing = !_isEditing),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _isEditing
                                  ? AppColors.primary.withValues(alpha: 0.15)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              _isEditing ? l10n.playlistDone : l10n.playlistEdit,
                              style: TextStyle(
                                fontSize: 14,
                                color: _isEditing
                                    ? AppColors.primary
                                    : AppColors.foreground,
                              ),
                            ),
                          ),
                        ),
                      if (queue.isNotEmpty) const SizedBox(width: 12),
                      GestureDetector(
                        onTap: queue.isNotEmpty
                            ? () {
                                player.clearQueue();
                                setState(() => _isEditing = false);
                              }
                            : null,
                        child: Text(
                          l10n.playlistClear,
                          style: TextStyle(
                            fontSize: 14,
                            color: queue.isNotEmpty
                                ? AppColors.primary
                                : AppColors.mutedForeground,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Now playing hint
            if (queue.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.graphic_eq_rounded,
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      l10n.playlistQueueInfo(
                        queue.length,
                        player.isPlaying ? l10n.playlistStatusPlaying : l10n.playlistStatusPaused,
                      ),
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            if (queue.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.queue_music_rounded,
                          size: 64, color: AppColors.mutedForeground),
                      const SizedBox(height: 16),
                      Text(
                        l10n.playlistEmpty,
                        style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.mutedForeground),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.playlistEmptyHint,
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.mutedForeground),
                      ),
                    ],
                  ),
                ),
              ),
            if (queue.isNotEmpty) ...[
              const SizedBox(height: 8),
              Expanded(
                child: _isEditing
                    ? _buildEditableList(player, library, queue)
                    : _buildNormalList(player, library, queue),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildNormalList(
      PlayerProvider player, LibraryProvider library, List<Song> queue) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: queue.length,
      itemBuilder: (context, index) {
        final song = queue[index];
        final isPlaying = index == player.currentIndex;
        return SongListTile(
          song: song,
          isPlaying: isPlaying,
          isFavorite: library.isFavSync(song.id),
          onFavoriteToggle: () => library.toggleFavorite(song.id),
          onTap: () =>
              player.playSong(song, queue: queue, index: index),
          onLongPress: () => showSongOptionsSheet(context, song),
        );
      },
    );
  }

  Widget _buildEditableList(
      PlayerProvider player, LibraryProvider library, List<Song> queue) {
    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) => Material(
            color: Colors.transparent,
            elevation: 6,
            shadowColor: AppColors.primary.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            child: child,
          ),
          child: child,
        );
      },
      onReorder: (oldIndex, newIndex) =>
          player.reorderQueue(oldIndex, newIndex),
      itemCount: queue.length,
      itemBuilder: (context, index) {
        final song = queue[index];
        final isPlaying = index == player.currentIndex;
        return Container(
          key: ValueKey('${song.id}_$index'),
          height: 68,
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.only(left: 4, right: 8),
          decoration: BoxDecoration(
            color: isPlaying
                ? AppColors.primary.withValues(alpha: 0.08)
                : AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: isPlaying
                ? Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2))
                : null,
          ),
          child: Row(
            children: [
              // Drag handle
              ReorderableDragStartListener(
                index: index,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  child: Icon(Icons.menu_rounded,
                      size: 20, color: AppColors.mutedForeground),
                ),
              ),
              // Song info
              Expanded(
                child: GestureDetector(
                  onTap: () => player.playSong(song,
                      queue: queue, index: index),
                  child: Row(
                    children: [
                      const SizedBox(width: 4),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              song.title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: isPlaying
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isPlaying
                                    ? AppColors.primary
                                    : AppColors.foreground,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              song.artist,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.mutedForeground),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isPlaying)
                const Icon(Icons.graphic_eq_rounded,
                    size: 18, color: AppColors.primary),
              // Delete button
              if (!isPlaying)
                GestureDetector(
                  onTap: () => player.removeFromQueue(index),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.remove_circle_outline_rounded,
                        size: 20, color: AppColors.mutedForeground),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
