import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../theme/app_theme.dart';
import '../widgets/album_cover.dart';
import '../widgets/song_list_tile.dart';
import '../providers/search_provider.dart';
import '../providers/player_provider.dart';
import '../providers/library_provider.dart';
import '../l10n/app_localizations.dart';
import 'artist_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer2<SearchProvider, PlayerProvider>(
      builder: (context, search, player, _) {
        final hasQuery = search.query.isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded,
                        size: 20, color: AppColors.mutedForeground),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        style: TextStyle(
                            fontSize: 16, color: AppColors.foreground),
                        decoration: InputDecoration(
                          hintText: l10n.searchHint,
                          hintStyle: const TextStyle(
                              color: AppColors.mutedForeground),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (value) => search.search(value),
                        onSubmitted: (value) {
                          if (value.trim().isNotEmpty) {
                            search.addToHistory(value.trim());
                          }
                        },
                      ),
                    ),
                    if (hasQuery)
                      GestureDetector(
                        onTap: () {
                          _controller.clear();
                          search.clearResults();
                        },
                        child: const Icon(Icons.close_rounded,
                            size: 20,
                            color: AppColors.mutedForeground),
                      ),
                  ],
                ),
              ),
            ),

            // Content
            Expanded(
              child: hasQuery
                  ? _buildSearchResults(search, player)
                  : _buildDefaultContent(search, player),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDefaultContent(
      SearchProvider search, PlayerProvider player) {
    final l10n = AppLocalizations.of(context)!;
    final library = context.watch<LibraryProvider>();
    final artists = library.artists;
    final songs = library.songs;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search history
          if (search.searchHistory.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.searchHistory,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.foreground,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => search.clearHistory(),
                    child: Text(l10n.searchClear,
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.mutedForeground)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ...search.searchHistory.map((text) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GestureDetector(
                  onTap: () {
                    _controller.text = text;
                    search.search(text);
                  },
                  child: SizedBox(
                    height: 44,
                    child: Row(
                      children: [
                        const Icon(Icons.access_time_rounded,
                            size: 18,
                            color: AppColors.mutedForeground),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            text,
                            style: TextStyle(
                                fontSize: 15,
                                color: AppColors.foreground),
                          ),
                        ),
                        GestureDetector(
                          onTap: () =>
                              search.removeFromHistory(text),
                          child: const Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: AppColors.mutedForeground),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],

          // Browse Artists
          if (artists.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Text(
                l10n.searchBrowseArtists,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.foreground,
                ),
              ),
            ),
            SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: artists.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final artist = artists[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              ArtistScreen(artistName: artist.name),
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
                            gradientIndex:
                                artist.name.hashCode.abs() % 12,
                            imagePath: artist.coverPath,
                            icon: Icons.person_rounded,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            artist.name,
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.foreground),
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

          // For You - random picks from library
          if (songs.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Text(
                l10n.searchForYou,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.foreground,
                ),
              ),
            ),
            Builder(builder: (context) {
              // 稳定的打散顺序：按标题 hash 排序
              final shuffled = List<Song>.from(songs)
                ..sort((a, b) => (a.title.hashCode ^ 0x9e3779b9)
                    .compareTo(b.title.hashCode ^ 0x9e3779b9));
              final picks = shuffled.take(10).toList();
              return SizedBox(
                height: 170,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: picks.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final song = picks[index];
                    return GestureDetector(
                      onTap: () => player.playSong(song,
                          queue: picks, index: index),
                      child: SizedBox(
                        width: 120,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AlbumCover(
                              width: 120,
                              height: 120,
                              gradientIndex:
                                  song.title.hashCode.abs() % 12,
                              imagePath: song.coverPath,
                              icon: Icons.music_note_rounded,
                            ),
                            const SizedBox(height: 6),
                            Text(song.title,
                                style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.foreground),
                                overflow: TextOverflow.ellipsis),
                            Text(song.artist,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.mutedForeground),
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
          ],

          // Hot categories
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
            child: Text(
              l10n.searchHotRecommend,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.foreground,
              ),
            ),
          ),
          SizedBox(
            height: 140,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _CategoryCard(
                    label: l10n.searchCategoryPop,
                    icon: Icons.trending_up_rounded,
                    gradientIndex: 0),
                const SizedBox(width: 12),
                _CategoryCard(
                    label: l10n.searchCategoryRock,
                    icon: Icons.electric_bolt_rounded,
                    gradientIndex: 1),
                const SizedBox(width: 12),
                _CategoryCard(
                    label: l10n.searchCategoryElectronic,
                    icon: Icons.waves_rounded,
                    gradientIndex: 4),
                const SizedBox(width: 12),
                _CategoryCard(
                    label: l10n.searchCategoryClassical,
                    icon: Icons.piano_rounded,
                    gradientIndex: 7),
              ],
            ),
          ),

          // Empty state hint
          if (songs.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.library_music_outlined,
                        size: 48,
                        color: AppColors.mutedForeground.withValues(alpha: 0.5)),
                    const SizedBox(height: 12),
                    Text(
                      l10n.searchStartListening,
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.mutedForeground),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSearchResults(
      SearchProvider search, PlayerProvider player) {
    final l10n = AppLocalizations.of(context)!;
    if (search.isSearching) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    final results = search.results;

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded,
                size: 48, color: AppColors.mutedForeground),
            const SizedBox(height: 12),
            Text(
              l10n.searchNoResult(search.query),
              style: const TextStyle(
                  fontSize: 14, color: AppColors.mutedForeground),
            ),
          ],
        ),
      );
    }

    // Group by artist
    final library = context.read<LibraryProvider>();
    final artistNames = <String>{};
    for (final song in results) {
      artistNames.add(song.artist);
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        // Artist cards with avatars
        if (artistNames.length > 1) ...[
          Text(l10n.searchRelatedArtists,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.foreground)),
          const SizedBox(height: 10),
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount:
                  artistNames.length > 5 ? 5 : artistNames.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final name = artistNames.elementAt(index);
                final artistMatch = library.artists
                    .where((a) => a.name == name);
                final coverPath = artistMatch.isNotEmpty
                    ? artistMatch.first.coverPath
                    : null;
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            ArtistScreen(artistName: name),
                      ),
                    );
                  },
                  child: SizedBox(
                    width: 70,
                    child: Column(
                      children: [
                        AlbumCover(
                          width: 56,
                          height: 56,
                          isCircle: true,
                          gradientIndex:
                              name.hashCode.abs() % 12,
                          imagePath: coverPath,
                          icon: Icons.person_rounded,
                        ),
                        const SizedBox(height: 6),
                        Text(name,
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.foreground),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
        // Song results
        Text(l10n.searchSongsCount(results.length),
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.foreground)),
        const SizedBox(height: 8),
        ...results.asMap().entries.map((entry) {
          final index = entry.key;
          final song = entry.value;
          final isPlaying = player.currentSong?.id == song.id &&
              player.isPlaying;
          return Consumer<LibraryProvider>(
            builder: (context, library, _) => SongListTile(
              song: song,
              isPlaying: isPlaying,
              showDuration: true,
              isFavorite: library.isFavSync(song.id),
              onFavoriteToggle: () => library.toggleFavorite(song.id),
              onTap: () {
                search.addToHistory(search.query);
                player.playSong(song,
                    queue: results, index: index);
              },
              onLongPress: () => showSongOptionsSheet(context, song),
            ),
          );
        }),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final int gradientIndex;

  const _CategoryCard({
    required this.label,
    required this.icon,
    required this.gradientIndex,
  });

  @override
  Widget build(BuildContext context) {
    return AlbumCover(
      width: 120,
      height: 120,
      borderRadius: 16,
      gradientIndex: gradientIndex,
      icon: icon,
      label: label,
    );
  }
}
