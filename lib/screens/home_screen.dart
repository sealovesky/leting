import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/album_cover.dart';
import '../providers/library_provider.dart';
import '../providers/playlist_provider.dart';
import '../providers/player_provider.dart';
import '../l10n/app_localizations.dart';
import 'playlist_detail_screen.dart';
import 'artist_screen.dart';
import 'scan_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer3<LibraryProvider, PlaylistProvider, PlayerProvider>(
      builder: (context, library, playlistProv, player, _) {
        final playlists = playlistProv.playlists;
        final recentSongs = library.recentlyPlayed.take(10).toList();
        final artists = library.artists.take(5).toList();
        final hasSongs = library.songs.isNotEmpty;

        return Column(
          children: [
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    l10n.navBrowse,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.foreground,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Scan prompt if no songs
                    if (!hasSongs) ...[
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const ScanScreen()),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withValues(alpha: 0.2),
                                AppColors.primary.withValues(alpha: 0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color:
                                  AppColors.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.library_music_rounded,
                                  size: 40, color: AppColors.primary),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(l10n.homeScanLocalMusic,
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color:
                                                AppColors.foreground)),
                                    const SizedBox(height: 4),
                                    Text(l10n.homeScanLocalMusicHint,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors
                                                .mutedForeground)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios_rounded,
                                  size: 16,
                                  color: AppColors.mutedForeground),
                            ],
                          ),
                        ),
                      ),
                    ],

                    // Playlists
                    const SizedBox(height: 16),
                    Text(
                      l10n.homeRecommendedPlaylists,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: AppColors.foreground,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (playlists.isEmpty)
                      SizedBox(
                        height: 195,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _PlaylistCard(
                                title: l10n.homeCreateFirstPlaylist,
                                subtitle: l10n.homeCreateFirstPlaylistHint,
                                gradientIndex: 0),
                          ],
                        ),
                      )
                    else
                      SizedBox(
                        height: 195,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: playlists.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final p = playlists[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        PlaylistDetailScreen(
                                            playlist: p),
                                  ),
                                );
                              },
                              child: _PlaylistCard(
                                title: p.name,
                                subtitle: l10n.songCount(p.songCount),
                                gradientIndex: p.gradientIndex,
                              ),
                            );
                          },
                        ),
                      ),

                    // Recent / New songs
                    const SizedBox(height: 24),
                    Text(
                      recentSongs.isNotEmpty ? l10n.homeRecentlyPlayed : l10n.homeNewReleases,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: AppColors.foreground,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (recentSongs.isNotEmpty)
                      SizedBox(
                        height: 170,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: recentSongs.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final song = recentSongs[index];
                            return GestureDetector(
                              onTap: () => player.playSong(song,
                                  queue: recentSongs, index: index),
                              child: SizedBox(
                                width: 120,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    AlbumCover(
                                      width: 120,
                                      height: 120,
                                      gradientIndex: song.title
                                              .hashCode
                                              .abs() %
                                          12,
                                      imagePath: song.coverPath,
                                      icon:
                                          Icons.music_note_rounded,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(song.title,
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: AppColors
                                                .foreground),
                                        overflow: TextOverflow
                                            .ellipsis),
                                    Text(song.artist,
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors
                                                .mutedForeground),
                                        overflow: TextOverflow
                                            .ellipsis),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    else
                      SizedBox(
                        height: 170,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _buildPlaceholderSong('晚风', '周深', 3),
                            const SizedBox(width: 12),
                            _buildPlaceholderSong('漠河舞厅', '柳爽', 5),
                            const SizedBox(width: 12),
                            _buildPlaceholderSong(
                                '孤勇者', '陈奕迅', 8),
                            const SizedBox(width: 12),
                            _buildPlaceholderSong(
                                '起风了', '买辣椒也用券', 9),
                          ],
                        ),
                      ),

                    // Artists
                    if (artists.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text(
                        l10n.homeArtists,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: AppColors.foreground,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 110,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: artists.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 16),
                          itemBuilder: (context, index) {
                            final artist = artists[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ArtistScreen(
                                        artistName: artist.name),
                                  ),
                                );
                              },
                              child: SizedBox(
                                width: 80,
                                child: Column(
                                  children: [
                                    AlbumCover(
                                      width: 72,
                                      height: 72,
                                      isCircle: true,
                                      gradientIndex: artist.name
                                              .hashCode
                                              .abs() %
                                          12,
                                      imagePath: artist.coverPath,
                                      icon:
                                          Icons.person_rounded,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      artist.name,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors
                                              .foreground),
                                      overflow:
                                          TextOverflow.ellipsis,
                                      textAlign:
                                          TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],

                    // Charts
                    const SizedBox(height: 24),
                    Text(
                      l10n.homeCharts,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: AppColors.foreground,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildChartItem(1, l10n.homeHotSingles, l10n.homeHotSinglesDesc, 0),
                    const SizedBox(height: 8),
                    _buildChartItem(2, l10n.homeRisingSongs, l10n.homeRisingSongsDesc, 1),
                    const SizedBox(height: 8),
                    _buildChartItem(3, l10n.homeOriginalMusic, l10n.homeOriginalMusicDesc, 2),
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

  static Widget _buildPlaceholderSong(
      String title, String artist, int gradientIndex) {
    return SizedBox(
      width: 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AlbumCover(
            width: 120,
            height: 120,
            gradientIndex: gradientIndex,
            icon: Icons.music_note_rounded,
          ),
          const SizedBox(height: 6),
          Text(title,
              style: TextStyle(
                  fontSize: 13, color: AppColors.foreground),
              overflow: TextOverflow.ellipsis),
          Text(artist,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.mutedForeground),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  static Widget _buildChartItem(
      int rank, String title, String desc, int gradientIndex) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          AlbumCover(
            width: 48,
            height: 48,
            borderRadius: 8,
            gradientIndex: gradientIndex,
            icon: Icons.bar_chart_rounded,
          ),
          const SizedBox(width: 12),
          Text(
            '$rank',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 16, color: AppColors.foreground)),
                const SizedBox(height: 2),
                Text(desc,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.mutedForeground)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.mutedForeground, size: 20),
        ],
      ),
    );
  }
}

class _PlaylistCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final int gradientIndex;

  const _PlaylistCard({
    required this.title,
    required this.subtitle,
    required this.gradientIndex,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AlbumCover(
            width: 170,
            height: 150,
            gradientIndex: gradientIndex,
            icon: Icons.headphones_rounded,
            label: title,
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
                fontSize: 12, color: AppColors.mutedForeground),
          ),
        ],
      ),
    );
  }
}
