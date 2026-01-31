import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/play_mode.dart';

class PreferenceService {
  late SharedPreferences _prefs;

  static const _keyAudioQuality = 'audio_quality';
  static const _keyNotification = 'notification_enabled';
  static const _keyPlayMode = 'play_mode';
  static const _keyVolume = 'volume';
  static const _keyLastSongId = 'last_song_id';
  static const _keyLastPosition = 'last_position';
  static const _keySearchHistory = 'search_history';
  static const _keyHasScanned = 'has_scanned';
  static const _keyThemeMode = 'theme_mode';
  static const _keyLocale = 'locale';
  static const _keyLastQueueIds = 'last_queue_ids';
  static const _keyLastQueueIndex = 'last_queue_index';
  static const _keyArtistCovers = 'artist_covers';

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // 音质
  String get audioQuality => _prefs.getString(_keyAudioQuality) ?? '高品质';
  Future<void> setAudioQuality(String value) =>
      _prefs.setString(_keyAudioQuality, value);

  // 通知
  bool get notificationEnabled =>
      _prefs.getBool(_keyNotification) ?? true;
  Future<void> setNotificationEnabled(bool value) =>
      _prefs.setBool(_keyNotification, value);

  // 播放模式
  PlayMode get playMode {
    final index = _prefs.getInt(_keyPlayMode) ?? 0;
    return PlayMode.values[index];
  }

  Future<void> setPlayMode(PlayMode mode) =>
      _prefs.setInt(_keyPlayMode, mode.index);

  // 音量
  double get volume => _prefs.getDouble(_keyVolume) ?? 0.8;
  Future<void> setVolume(double value) =>
      _prefs.setDouble(_keyVolume, value);

  // 上次播放
  String? get lastSongId => _prefs.getString(_keyLastSongId);
  Future<void> setLastSongId(String? id) {
    if (id == null) return _prefs.remove(_keyLastSongId);
    return _prefs.setString(_keyLastSongId, id);
  }

  int get lastPosition => _prefs.getInt(_keyLastPosition) ?? 0;
  Future<void> setLastPosition(int ms) =>
      _prefs.setInt(_keyLastPosition, ms);

  // 播放队列
  List<String> get lastQueueIds =>
      _prefs.getStringList(_keyLastQueueIds) ?? [];
  Future<void> setLastQueueIds(List<String> ids) =>
      _prefs.setStringList(_keyLastQueueIds, ids);

  int get lastQueueIndex => _prefs.getInt(_keyLastQueueIndex) ?? 0;
  Future<void> setLastQueueIndex(int index) =>
      _prefs.setInt(_keyLastQueueIndex, index);

  Future<void> clearQueueState() async {
    await _prefs.remove(_keyLastQueueIds);
    await _prefs.remove(_keyLastQueueIndex);
  }

  // 艺人自定义封面
  Map<String, String> get artistCovers {
    final json = _prefs.getString(_keyArtistCovers);
    if (json == null) return {};
    return Map<String, String>.from(jsonDecode(json) as Map);
  }

  Future<void> setArtistCover(String artistName, String coverPath) async {
    final covers = artistCovers;
    covers[artistName] = coverPath;
    await _prefs.setString(_keyArtistCovers, jsonEncode(covers));
  }

  Future<void> removeArtistCover(String artistName) async {
    final covers = artistCovers;
    covers.remove(artistName);
    await _prefs.setString(_keyArtistCovers, jsonEncode(covers));
  }

  // 搜索历史
  List<String> get searchHistory =>
      _prefs.getStringList(_keySearchHistory) ?? [];
  Future<void> setSearchHistory(List<String> history) =>
      _prefs.setStringList(_keySearchHistory, history);

  // 是否已扫描
  bool get hasScanned => _prefs.getBool(_keyHasScanned) ?? false;
  Future<void> setHasScanned(bool value) =>
      _prefs.setBool(_keyHasScanned, value);

  // 主题模式: 0=dark, 1=light, 2=system
  int get themeMode => _prefs.getInt(_keyThemeMode) ?? 0;
  Future<void> setThemeMode(int value) =>
      _prefs.setInt(_keyThemeMode, value);

  // 语言: null=system, 'zh', 'en'
  String? get locale => _prefs.getString(_keyLocale);
  Future<void> setLocale(String? value) {
    if (value == null) return _prefs.remove(_keyLocale);
    return _prefs.setString(_keyLocale, value);
  }
}
