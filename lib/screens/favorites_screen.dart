import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/song_list_tile.dart';
import '../providers/library_provider.dart';
import '../providers/player_provider.dart';
import '../l10n/app_localizations.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer2<LibraryProvider, PlayerProvider>(
        builder: (context, library, player, _) {
          final favorites = library.favorites;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.transparent,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back_ios_rounded,
                      color: AppColors.foreground),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                expandedHeight: 240,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primary.withValues(alpha: 0.4),
                          AppColors.background,
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFFC3E4E),
                                Color(0xFFFF7B54),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.favorite_rounded,
                              size: 56, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Text(
                        l10n.favoritesTitle,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.foreground,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.songCount(favorites.length),
                        style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.mutedForeground),
                      ),
                      const SizedBox(height: 16),
                      if (favorites.isNotEmpty)
                        GestureDetector(
                          onTap: () => player.playSong(
                              favorites.first,
                              queue: favorites,
                              index: 0),
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
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.play_arrow_rounded,
                                    color: Colors.white, size: 22),
                                const SizedBox(width: 4),
                                Text(
                                  l10n.favoritesPlayAll,
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
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              if (favorites.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.favorite_border_rounded,
                            size: 48,
                            color: AppColors.mutedForeground),
                        const SizedBox(height: 12),
                        Text(l10n.favoritesEmpty,
                            style: const TextStyle(
                                fontSize: 14,
                                color:
                                    AppColors.mutedForeground)),
                        const SizedBox(height: 4),
                        Text(l10n.favoritesEmptyHint,
                            style: const TextStyle(
                                fontSize: 12,
                                color:
                                    AppColors.mutedForeground)),
                      ],
                    ),
                  ),
                ),
              if (favorites.isNotEmpty)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final song = favorites[index];
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
                          isFavorite: true,
                          onFavoriteToggle: () =>
                              library.toggleFavorite(song.id),
                          onTap: () => player.playSong(song,
                              queue: favorites, index: index),
                          onLongPress: () =>
                              showSongOptionsSheet(context, song),
                        ),
                      );
                    },
                    childCount: favorites.length,
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
}
