import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song.dart';
import '../models/play_mode.dart';
import '../services/audio_player_service.dart';
import '../services/storage_service.dart';
import '../services/preference_service.dart';

class PlayerProvider extends ChangeNotifier {
  final AudioPlayerService _audioService;
  final StorageService _storageService;
  final PreferenceService _preferenceService;

  final List<StreamSubscription> _subscriptions = [];

  VoidCallback? onPlayHistoryChanged;

  // State
  Song? _currentSong;
  List<Song> _queue = [];
  int _currentIndex = -1;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _volume = 0.8;
  PlayMode _playMode = PlayMode.sequence;

  PlayerProvider({
    required AudioPlayerService audioService,
    required StorageService storageService,
    required PreferenceService preferenceService,
  })  : _audioService = audioService,
        _storageService = storageService,
        _preferenceService = preferenceService {
    _init();
  }

  // Getters
  AndroidEqualizer? get equalizer => _audioService.equalizer;
  Song? get currentSong => _currentSong;
  List<Song> get queue => _queue;
  int get currentIndex => _currentIndex;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _duration;
  double get volume => _volume;
  PlayMode get playMode => _playMode;
  bool get hasNext {
    if (_queue.isEmpty) return false;
    if (_playMode == PlayMode.loop || _playMode == PlayMode.shuffle) {
      return _queue.length > 1;
    }
    return _currentIndex < _queue.length - 1;
  }

  bool get hasPrevious {
    if (_queue.isEmpty) return false;
    if (_playMode == PlayMode.loop) return _queue.length > 1;
    return _currentIndex > 0;
  }

  void _init() {
    _volume = _preferenceService.volume;
    _playMode = _preferenceService.playMode;
    _audioService.setVolume(_volume);
    _audioService.setPlayMode(_playMode);

    // Register notification control callbacks
    _audioService.onSkipToNext = () => next();
    _audioService.onSkipToPrevious = () => previous();

    _subscriptions.add(
      _audioService.positionStream.listen((pos) {
        _position = pos;
        notifyListeners();
      }),
    );

    _subscriptions.add(
      _audioService.durationStream.listen((dur) {
        _duration = dur ?? Duration.zero;
        notifyListeners();
      }),
    );

    _subscriptions.add(
      _audioService.playerStateStream.listen((state) {
        _isPlaying = state.playing;
        // Auto-next on completion
        if (state.processingState == ProcessingState.completed) {
          _onSongCompleted();
        }
        notifyListeners();
      }),
    );
  }

  void _saveQueueState() {
    final ids = _queue.map((s) => s.id).toList();
    _preferenceService.setLastQueueIds(ids);
    _preferenceService.setLastQueueIndex(_currentIndex);
  }

  Future<void> playSong(Song song, {List<Song>? queue, int? index}) async {
    if (queue != null) {
      _queue = List.from(queue);
      _currentIndex = index ?? 0;
    } else if (!_queue.contains(song)) {
      _queue.add(song);
      _currentIndex = _queue.length - 1;
    } else {
      _currentIndex = _queue.indexOf(song);
    }

    _currentSong = song;
    _saveQueueState();
    notifyListeners();

    await _audioService.playFile(song.filePath, song: song);
    _storageService.addPlayHistory(song.id);
    _preferenceService.setLastSongId(song.id);
    onPlayHistoryChanged?.call();
  }

  Future<void> play() async {
    await _audioService.play();
  }

  Future<void> pause() async {
    await _audioService.pause();
  }

  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> seek(Duration position) async {
    await _audioService.seek(position);
  }

  Future<void> next() async {
    if (_queue.isEmpty) return;
    if (_playMode == PlayMode.shuffle) {
      _currentIndex = (_currentIndex + 1) % _queue.length;
    } else if (_currentIndex < _queue.length - 1) {
      _currentIndex++;
    } else if (_playMode == PlayMode.loop) {
      _currentIndex = 0;
    } else {
      return;
    }
    await playSong(_queue[_currentIndex]);
  }

  Future<void> previous() async {
    if (_queue.isEmpty) return;
    // If past 3 seconds, restart current song
    if (_position.inSeconds > 3) {
      await seek(Duration.zero);
      return;
    }
    if (_currentIndex > 0) {
      _currentIndex--;
    } else if (_playMode == PlayMode.loop) {
      _currentIndex = _queue.length - 1;
    } else {
      await seek(Duration.zero);
      return;
    }
    await playSong(_queue[_currentIndex]);
  }

  Future<void> setVolume(double value) async {
    _volume = value;
    await _audioService.setVolume(value);
    _preferenceService.setVolume(value);
    notifyListeners();
  }

  void setPlayMode(PlayMode mode) {
    _playMode = mode;
    _audioService.setPlayMode(mode);
    _preferenceService.setPlayMode(mode);
    notifyListeners();
  }

  void cyclePlayMode() {
    final nextIndex = (PlayMode.values.indexOf(_playMode) + 1) %
        PlayMode.values.length;
    setPlayMode(PlayMode.values[nextIndex]);
  }

  void removeFromQueue(int index) {
    if (index < 0 || index >= _queue.length) return;
    _queue.removeAt(index);
    if (index < _currentIndex) {
      _currentIndex--;
    } else if (index == _currentIndex) {
      if (_queue.isEmpty) {
        _currentSong = null;
        _currentIndex = -1;
        _audioService.stop();
      } else {
        _currentIndex = _currentIndex.clamp(0, _queue.length - 1);
        playSong(_queue[_currentIndex]);
      }
    }
    _saveQueueState();
    notifyListeners();
  }

  void reorderQueue(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex--;
    final song = _queue.removeAt(oldIndex);
    _queue.insert(newIndex, song);
    // Update currentIndex to follow the currently playing song
    if (oldIndex == _currentIndex) {
      _currentIndex = newIndex;
    } else if (oldIndex < _currentIndex && newIndex >= _currentIndex) {
      _currentIndex--;
    } else if (oldIndex > _currentIndex && newIndex <= _currentIndex) {
      _currentIndex++;
    }
    _saveQueueState();
    notifyListeners();
  }

  void clearQueue() {
    _queue.clear();
    _currentSong = null;
    _currentIndex = -1;
    _audioService.stop();
    _preferenceService.clearQueueState();
    notifyListeners();
  }

  void _onSongCompleted() {
    if (_playMode == PlayMode.single) {
      seek(Duration.zero);
      play();
    } else {
      next();
    }
  }

  Future<void> restoreLastSession() async {
    final queueIds = _preferenceService.lastQueueIds;
    final queueIndex = _preferenceService.lastQueueIndex;

    if (queueIds.isNotEmpty) {
      final songs = await _storageService.getSongsByIds(queueIds);
      if (songs.isNotEmpty) {
        _queue = songs;
        _currentIndex = queueIndex.clamp(0, songs.length - 1);
        _currentSong = _queue[_currentIndex];
        notifyListeners();
        await _audioService.loadFile(_currentSong!.filePath, song: _currentSong!);
        return;
      }
    }

    // 兜底：旧版只存了单首歌 ID
    final songId = _preferenceService.lastSongId;
    if (songId == null) return;
    final song = await _storageService.getSongById(songId);
    if (song != null) {
      _currentSong = song;
      _queue = [song];
      _currentIndex = 0;
      notifyListeners();
      await _audioService.loadFile(song.filePath, song: song);
    }
  }

  void savePosition() {
    _preferenceService.setLastPosition(_position.inMilliseconds);
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _audioService.dispose();
    super.dispose();
  }
}
