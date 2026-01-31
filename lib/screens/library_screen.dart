import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/album_cover.dart';
import '../providers/library_provider.dart';
import '../providers/playlist_provider.dart';
import '../providers/player_provider.dart';
import '../l10n/app_localizations.dart';
import 'playlist_detail_screen.dart';
import 'favorites_screen.dart';
import 'all_songs_screen.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer3<LibraryProvider, PlaylistProvider, PlayerProvider>(
      builder: (context, library, playlistProv, player, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                height: 56,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.libraryTitle,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.foreground,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pushNamed('/settings'),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.tune_rounded,
                          size: 24,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Recently played
                    Text(
                      l10n.libraryRecentlyPlayed,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.foreground,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (library.recentlyPlayed.isEmpty)
                      _buildEmptyHint(l10n.libraryNoPlayHistory)
                    else
                      SizedBox(
                        height: 145,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: library.recentlyPlayed.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final song = library.recentlyPlayed[index];
                            return GestureDetector(
                              onTap: () => player.playSong(song,
                                  queue: library.recentlyPlayed,
                                  index: index),
                              child: SizedBox(
                                width: 100,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    AlbumCover(
                                      width: 100,
                                      height: 100,
                                      borderRadius: 8,
                                      gradientIndex: song.title.hashCode
                                              .abs() %
                                          12,
                                      imagePath: song.coverPath,
                                      icon: Icons.music_note_rounded,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(song.title,
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.foreground),
                                        overflow:
                                            TextOverflow.ellipsis),
                                    Text(song.artist,
                                        style: const TextStyle(
                                            fontSize: 10,
                                            color: AppColors
                                                .mutedForeground),
                                        overflow:
                                            TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                    // Favorites
                    const SizedBox(height: 24),
                    Text(
                      l10n.libraryFavorites,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.foreground,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const FavoritesScreen()),
                        );
                      },
                      child: Container(
                        height: 64,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFC3E4E),
                                    Color(0xFFFF7B54)
                                  ],
                                ),
                                borderRadius:
                                    BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                  Icons.favorite_rounded,
                                  size: 22,
                                  color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(l10n.libraryFavoriteSongs,
                                      style: TextStyle(
                                          fontSize: 16,
                                          color:
                                              AppColors.foreground)),
                                  Text(
                                      l10n.songCount(library.favoriteCount),
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors
                                              .mutedForeground)),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded,
                                size: 20,
                                color: AppColors.mutedForeground),
                          ],
                        ),
                      ),
                    ),

                    // All songs
                    const SizedBox(height: 24),
                    Text(
                      l10n.libraryAllSongs,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.foreground,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const AllSongsScreen()),
                        );
                      },
                      child: Container(
                        height: 64,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF4FACFE),
                                    Color(0xFF00F2FE)
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                  Icons.library_music_rounded,
                                  size: 22,
                                  color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(l10n.libraryAllSongs,
                                      style: TextStyle(
                                          fontSize: 16,
                                          color:
                                              AppColors.foreground)),
                                  Text(l10n.songCount(library.songs.length),
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors
                                              .mutedForeground)),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded,
                                size: 20,
                                color: AppColors.mutedForeground),
                          ],
                        ),
                      ),
                    ),

                    // Playlists
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.libraryMyPlaylists,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppColors.foreground,
                          ),
                        ),
                        GestureDetector(
                          onTap: () =>
                              _showCreatePlaylistDialog(context),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.cardSecondary,
                              borderRadius:
                                  BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.add_rounded,
                                size: 20,
                                color: AppColors.foreground),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (playlistProv.playlists.isEmpty)
                      _buildEmptyHint(l10n.libraryNoPlaylistHint)
                    else
                      ...playlistProv.playlists.map((playlist) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      PlaylistDetailScreen(
                                          playlist: playlist),
                                ),
                              );
                            },
                            child: Container(
                              height: 64,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12),
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius:
                                    BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  AlbumCover(
                                    width: 44,
                                    height: 44,
                                    borderRadius: 8,
                                    gradientIndex:
                                        playlist.gradientIndex,
                                    icon: Icons
                                        .queue_music_rounded,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment
                                              .center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,
                                      children: [
                                        Text(playlist.name,
                                            style:
                                                TextStyle(
                                                    fontSize:
                                                        16,
                                                    color: AppColors
                                                        .foreground)),
                                        Text(
                                            l10n.songCount(playlist.songCount),
                                            style:
                                                const TextStyle(
                                                    fontSize:
                                                        12,
                                                    color: AppColors
                                                        .mutedForeground)),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                      Icons
                                          .chevron_right_rounded,
                                      size: 20,
                                      color: AppColors
                                          .mutedForeground),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyHint(String text) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
              fontSize: 14, color: AppColors.mutedForeground),
        ),
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(l10n.libraryNewPlaylist,
            style: TextStyle(color: AppColors.foreground)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: AppColors.foreground),
          decoration: InputDecoration(
            hintText: l10n.libraryPlaylistName,
            hintStyle:
                const TextStyle(color: AppColors.mutedForeground),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                  color: AppColors.border),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.commonCancel,
                style: const TextStyle(color: AppColors.mutedForeground)),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                context
                    .read<PlaylistProvider>()
                    .createPlaylist(name);
                Navigator.of(ctx).pop();
              }
            },
            child: Text(l10n.commonCreate,
                style: const TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}
