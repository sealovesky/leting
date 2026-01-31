import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/song.dart';
import '../widgets/song_list_tile.dart';
import '../providers/library_provider.dart';
import '../providers/player_provider.dart';
import '../l10n/app_localizations.dart';

enum SongSortType { title, artist, album, recent }

class AllSongsScreen extends StatefulWidget {
  const AllSongsScreen({super.key});

  @override
  State<AllSongsScreen> createState() => _AllSongsScreenState();
}

class _AllSongsScreenState extends State<AllSongsScreen> {
  SongSortType _sortType = SongSortType.title;

  List<Song> _sortedSongs(List<Song> songs) {
    final sorted = List<Song>.from(songs);
    switch (_sortType) {
      case SongSortType.title:
        sorted.sort((a, b) => a.title.compareTo(b.title));
      case SongSortType.artist:
        sorted.sort((a, b) => a.artist.compareTo(b.artist));
      case SongSortType.album:
        sorted.sort((a, b) => a.album.compareTo(b.album));
      case SongSortType.recent:
        sorted.sort((a, b) => b.addedAt.compareTo(a.addedAt));
    }
    return sorted;
  }

  String _sortLabel(SongSortType type) {
    final l10n = AppLocalizations.of(context)!;
    switch (type) {
      case SongSortType.title:
        return l10n.allSongsSortByTitle;
      case SongSortType.artist:
        return l10n.allSongsSortByArtist;
      case SongSortType.album:
        return l10n.allSongsSortByAlbum;
      case SongSortType.recent:
        return l10n.allSongsSortByRecent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded,
              color: AppColors.foreground),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l10n.allSongsTitle,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.foreground,
          ),
        ),
        actions: [
          PopupMenuButton<SongSortType>(
            icon: Icon(Icons.sort_rounded,
                color: AppColors.foreground),
            color: AppColors.card,
            onSelected: (type) => setState(() => _sortType = type),
            itemBuilder: (_) => SongSortType.values.map((type) {
              return PopupMenuItem(
                value: type,
                child: Row(
                  children: [
                    if (_sortType == type)
                      const Icon(Icons.check_rounded,
                          size: 16, color: AppColors.primary)
                    else
                      const SizedBox(width: 16),
                    const SizedBox(width: 8),
                    Text(
                      _sortLabel(type),
                      style: TextStyle(
                        color: _sortType == type
                            ? AppColors.primary
                            : AppColors.foreground,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
      body: Consumer2<LibraryProvider, PlayerProvider>(
        builder: (context, library, player, _) {
          final songs = _sortedSongs(library.songs);

          if (songs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.library_music_rounded,
                      size: 48, color: AppColors.mutedForeground),
                  const SizedBox(height: 12),
                  Text(l10n.allSongsEmpty,
                      style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.mutedForeground)),
                ],
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      l10n.allSongsSortInfo(songs.length, _sortLabel(_sortType)),
                      style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.mutedForeground),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: songs.isNotEmpty
                          ? () => player.playSong(songs.first,
                              queue: songs, index: 0)
                          : null,
                      child: Container(
                        height: 32,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.play_arrow_rounded,
                                color: Colors.white, size: 18),
                            const SizedBox(width: 4),
                            Text(l10n.allSongsPlayAll,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: songs.length,
                  itemBuilder: (context, index) {
                    final song = songs[index];
                    final isPlaying = player.currentSong?.id == song.id &&
                        player.isPlaying;
                    return SongListTile(
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
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
