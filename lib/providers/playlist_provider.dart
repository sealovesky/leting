import 'package:flutter/foundation.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import '../services/storage_service.dart';

class PlaylistProvider extends ChangeNotifier {
  final StorageService _storageService;

  List<Playlist> _playlists = [];
  List<Song> _currentPlaylistSongs = [];

  PlaylistProvider({required StorageService storageService})
      : _storageService = storageService;

  List<Playlist> get playlists => _playlists;
  List<Song> get currentPlaylistSongs => _currentPlaylistSongs;

  Future<void> loadPlaylists() async {
    _playlists = await _storageService.getAllPlaylists();
    notifyListeners();
  }

  Future<void> createPlaylist(String name, {String? description, int gradientIndex = 0}) async {
    final now = DateTime.now();
    final playlist = Playlist(
      id: now.millisecondsSinceEpoch.toRadixString(36),
      name: name,
      description: description,
      gradientIndex: gradientIndex,
      createdAt: now,
      updatedAt: now,
    );
    await _storageService.insertPlaylist(playlist);
    await loadPlaylists();
  }

  Future<void> deletePlaylist(String id) async {
    await _storageService.deletePlaylist(id);
    await loadPlaylists();
  }

  Future<void> loadPlaylistSongs(String playlistId) async {
    _currentPlaylistSongs =
        await _storageService.getPlaylistSongs(playlistId);
    notifyListeners();
  }

  Future<void> addSongToPlaylist(String playlistId, String songId) async {
    await _storageService.addSongToPlaylist(playlistId, songId);
    await loadPlaylists();
  }

  Future<void> removeSongFromPlaylist(
      String playlistId, String songId) async {
    await _storageService.removeSongFromPlaylist(playlistId, songId);
    await loadPlaylists();
    await loadPlaylistSongs(playlistId);
  }
}
