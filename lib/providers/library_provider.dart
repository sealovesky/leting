import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/song.dart';
import '../models/artist.dart';
import '../models/album.dart';
import '../services/storage_service.dart';
import '../services/local_music_service.dart';
import '../services/preference_service.dart';

class LibraryProvider extends ChangeNotifier {
  final StorageService _storageService;
  final LocalMusicService _localMusicService;
  final PreferenceService _preferenceService;

  List<Song> _songs = [];
  List<Song> _favorites = [];
  List<Song> _recentlyPlayed = [];
  List<Artist> _artists = [];
  List<Album> _albums = [];
  Set<String> _favoriteIds = {};
  int _favoriteCount = 0;
  bool _isScanning = false;
  int _scanCount = 0;
  String _scanStatus = '';
  bool _permissionDenied = false;
  bool _permissionPermanentlyDenied = false;

  LibraryProvider({
    required StorageService storageService,
    required LocalMusicService localMusicService,
    required PreferenceService preferenceService,
  })  : _storageService = storageService,
        _localMusicService = localMusicService,
        _preferenceService = preferenceService;

  // Getters
  List<Song> get songs => _songs;
  List<Song> get favorites => _favorites;
  List<Song> get recentlyPlayed => _recentlyPlayed;
  List<Artist> get artists => _artists;
  List<Album> get albums => _albums;
  int get favoriteCount => _favoriteCount;
  bool get isScanning => _isScanning;
  int get scanCount => _scanCount;
  String get scanStatus => _scanStatus;
  bool get permissionDenied => _permissionDenied;
  bool get permissionPermanentlyDenied => _permissionPermanentlyDenied;

  Future<void> loadLibrary() async {
    _songs = await _storageService.getAllSongs();
    _favorites = await _storageService.getFavorites();
    _favoriteIds = _favorites.map((s) => s.id).toSet();
    _recentlyPlayed = await _storageService.getPlayHistory(limit: 20);
    _favoriteCount = await _storageService.getFavoriteCount();
    _buildArtistsAndAlbums();
    notifyListeners();
  }

  Future<bool> _requestPermission() async {
    if (!Platform.isAndroid) return true;

    // 先检查 Permission.audio（Android 13+ 对应 READ_MEDIA_AUDIO）
    // 再检查 Permission.storage（Android 12- 对应 READ_EXTERNAL_STORAGE）
    // permission_handler 会根据系统版本自动忽略不适用的权限

    final audioStatus = await Permission.audio.status;
    final storageStatus = await Permission.storage.status;

    if (audioStatus.isGranted || storageStatus.isGranted) return true;

    // 同时请求两个权限，系统会根据 API 级别只弹出适用的那个
    final statuses = await [
      Permission.audio,
      Permission.storage,
    ].request();

    final audioResult = statuses[Permission.audio]!;
    final storageResult = statuses[Permission.storage]!;

    if (audioResult.isGranted || storageResult.isGranted) {
      _permissionDenied = false;
      _permissionPermanentlyDenied = false;
      return true;
    }

    if (audioResult.isPermanentlyDenied || storageResult.isPermanentlyDenied) {
      _permissionDenied = true;
      _permissionPermanentlyDenied = true;
      notifyListeners();
      return false;
    }

    _permissionDenied = true;
    _permissionPermanentlyDenied = false;
    notifyListeners();
    return false;
  }

  Future<void> openSettings() async {
    await openAppSettings();
  }

  Future<void> scanLocalMusic() async {
    // 权限检查（仅 Android）
    _permissionDenied = false;
    _permissionPermanentlyDenied = false;

    final hasPermission = await _requestPermission();
    if (!hasPermission) return;

    _isScanning = true;
    _scanCount = 0;
    _scanStatus = '正在扫描...';
    notifyListeners();

    final scannedSongs = <Song>[];
    await for (final song in _localMusicService.scanLocalMusic()) {
      scannedSongs.add(song);
      _scanCount++;
      _scanStatus = '已扫描 $_scanCount 首: ${song.title}';
      notifyListeners();
    }

    if (scannedSongs.isNotEmpty) {
      await _storageService.insertSongs(scannedSongs);
    }

    _isScanning = false;
    _scanStatus = '扫描完成，共 $_scanCount 首';
    notifyListeners();

    await loadLibrary();
  }

  void _buildArtistsAndAlbums() {
    final artistCountMap = <String, int>{};
    final artistCoverMap = <String, String?>{};
    final albumMap = <String, Album>{};

    for (final song in _songs) {
      artistCountMap[song.artist] =
          (artistCountMap[song.artist] ?? 0) + 1;
      // 默认：第一首有封面的歌曲决定艺人头像
      artistCoverMap[song.artist] ??= song.coverPath;

      final key = '${song.album}|${song.artist}';
      if (!albumMap.containsKey(key)) {
        albumMap[key] = Album(
          name: song.album,
          artist: song.artist,
          coverPath: song.coverPath,
          songCount: 1,
        );
      } else {
        final existing = albumMap[key]!;
        albumMap[key] = Album(
          name: existing.name,
          artist: existing.artist,
          coverPath: existing.coverPath ?? song.coverPath,
          songCount: existing.songCount + 1,
        );
      }
    }

    // 自定义封面覆盖默认
    final customCovers = _preferenceService.artistCovers;

    _artists = artistCountMap.entries
        .map((e) => Artist(
              name: e.key,
              songCount: e.value,
              coverPath: customCovers[e.key] ?? artistCoverMap[e.key],
            ))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    _albums = albumMap.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<void> setArtistCover(String artistName, String coverPath) async {
    await _preferenceService.setArtistCover(artistName, coverPath);
    _buildArtistsAndAlbums();
    notifyListeners();
  }

  Future<void> clearArtistCover(String artistName) async {
    await _preferenceService.removeArtistCover(artistName);
    _buildArtistsAndAlbums();
    notifyListeners();
  }

  bool isFavSync(String songId) => _favoriteIds.contains(songId);

  Future<void> toggleFavorite(String songId) async {
    final isFav = _favoriteIds.contains(songId);
    if (isFav) {
      _favoriteIds.remove(songId);
      await _storageService.removeFavorite(songId);
    } else {
      _favoriteIds.add(songId);
      await _storageService.addFavorite(songId);
    }
    _favorites = await _storageService.getFavorites();
    _favoriteCount = await _storageService.getFavoriteCount();
    notifyListeners();
  }

  Future<bool> isFavorite(String songId) async {
    return _storageService.isFavorite(songId);
  }

  Future<void> loadRecentlyPlayed() async {
    _recentlyPlayed = await _storageService.getPlayHistory(limit: 20);
    notifyListeners();
  }

  List<Song> getSongsByArtist(String artist) {
    return _songs.where((s) => s.artist == artist).toList();
  }

  List<Song> getSongsByAlbum(String album, String artist) {
    return _songs
        .where((s) => s.album == album && s.artist == artist)
        .toList();
  }
}
