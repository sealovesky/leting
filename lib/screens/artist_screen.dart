import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/album_cover.dart';
import '../widgets/song_list_tile.dart';
import '../providers/library_provider.dart';
import '../providers/player_provider.dart';
import '../l10n/app_localizations.dart';

class ArtistScreen extends StatelessWidget {
  final String artistName;

  const ArtistScreen({super.key, required this.artistName});

  void _showAvatarPicker(BuildContext context, LibraryProvider library) {
    final l10n = AppLocalizations.of(context)!;
    final songs = library.getSongsByArtist(artistName);

    // 收集每个专辑的封面（去重）
    final albumCovers = <String, String>{};
    for (final song in songs) {
      if (song.coverPath != null && !albumCovers.containsKey(song.album)) {
        albumCovers[song.album] = song.coverPath!;
      }
    }

    if (albumCovers.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final entries = albumCovers.entries.toList();
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.artistSelectAvatar,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.foreground,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      library.clearArtistCover(artistName);
                      Navigator.of(ctx).pop();
                    },
                    child: Text(
                      l10n.artistResetAvatar,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 140,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, index) {
                    final album = entries[index].key;
                    final coverPath = entries[index].value;
                    return GestureDetector(
                      onTap: () {
                        library.setArtistCover(artistName, coverPath);
                        Navigator.of(ctx).pop();
                      },
                      child: SizedBox(
                        width: 100,
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(50),
                              child: Image.file(
                                File(coverPath),
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.cardSecondary,
                                  ),
                                  child: Icon(Icons.album_rounded,
                                      color: AppColors.mutedForeground),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              album,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.foreground,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer2<LibraryProvider, PlayerProvider>(
        builder: (context, library, player, _) {
          final songs = library.getSongsByArtist(artistName);
          final artistMatch = library.artists.where(
            (a) => a.name == artistName,
          );
          final artist = artistMatch.isNotEmpty ? artistMatch.first : null;
          final songCount = artist?.songCount ?? songs.length;
          final artistCover = artist?.coverPath;

          // Group by album
          final albumMap = <String, List<dynamic>>{};
          for (final song in songs) {
            albumMap.putIfAbsent(song.album, () => []).add(song);
          }
          final albums = albumMap.entries.toList();

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.transparent,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back_ios_rounded,
                      color: AppColors.foreground),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                expandedHeight: 280,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(
                            (artistName.hashCode & 0xFFFFFF) | 0xFF000000,
                          ).withValues(alpha: 0.5),
                          AppColors.background,
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 32),
                        GestureDetector(
                          onTap: () => _showAvatarPicker(context, library),
                          child: AlbumCover(
                            width: 140,
                            height: 140,
                            gradientIndex:
                                artistName.hashCode.abs() % 12,
                            isCircle: true,
                            imagePath: artistCover,
                            icon: Icons.person_rounded,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      Text(
                        artistName,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.foreground,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.artistSongCount(songCount),
                        style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.mutedForeground),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: songs.isNotEmpty
                                ? () => player.playSong(
                                    songs.first,
                                    queue: songs,
                                    index: 0)
                                : null,
                            child: Container(
                              height: 36,
                              padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 24),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius:
                                    BorderRadius.circular(999),
                              ),
                              child: Center(
                                child: Text(l10n.artistPlayAll,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight:
                                            FontWeight.w600,
                                        color: Colors.white)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            height: 36,
                            padding:
                                const EdgeInsets.symmetric(
                                    horizontal: 20),
                            decoration: BoxDecoration(
                              color: AppColors.cardSecondary,
                              borderRadius:
                                  BorderRadius.circular(999),
                            ),
                            child: Center(
                              child: Row(
                                children: [
                                  Icon(Icons.shuffle_rounded,
                                      size: 16,
                                      color:
                                          AppColors.foreground),
                                  const SizedBox(width: 4),
                                  Text(l10n.artistShuffle,
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: AppColors
                                              .foreground)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ),

              // Song list
              if (songs.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.artistSongs,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppColors.foreground,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
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
                        ),
                      );
                    },
                    childCount: songs.length,
                  ),
                ),
              ],

              // Albums
              if (albums.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.artistAlbums,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppColors.foreground,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 170,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: albums.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final albumEntry =
                                  albums[index];
                              final firstSong =
                                  albumEntry.value.first;
                              return SizedBox(
                                width: 120,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    AlbumCover(
                                      width: 120,
                                      height: 120,
                                      borderRadius: 10,
                                      gradientIndex: albumEntry
                                              .key
                                              .hashCode
                                              .abs() %
                                          12,
                                      imagePath: firstSong
                                          .coverPath,
                                      icon: Icons
                                          .album_rounded,
                                    ),
                                    const SizedBox(
                                        height: 6),
                                    Text(albumEntry.key,
                                        style:
                                            TextStyle(
                                                fontSize:
                                                    13,
                                                color: AppColors
                                                    .foreground),
                                        overflow:
                                            TextOverflow
                                                .ellipsis),
                                    Text(
                                        l10n.songCount(albumEntry.value.length),
                                        style:
                                            const TextStyle(
                                                fontSize:
                                                    11,
                                                color: AppColors
                                                    .mutedForeground)),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Empty state
              if (songs.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      l10n.artistNoSongs,
                      style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.mutedForeground),
                    ),
                  ),
                ),

              const SliverToBoxAdapter(
                  child: SizedBox(height: 40)),
            ],
          );
        },
      ),
    );
  }
}
