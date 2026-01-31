import 'dart:async';
import 'dart:io';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import '../models/play_mode.dart';
import '../models/song.dart';

class AudioPlayerService {
  late final AndroidEqualizer? _equalizer;
  late final AudioPlayer _player;
  _MusicAudioHandler? _audioHandler;

  AudioPlayerService() {
    _equalizer = Platform.isAndroid ? AndroidEqualizer() : null;
    _player = AudioPlayer(
      audioPipeline: AudioPipeline(
        androidAudioEffects: [if (_equalizer != null) _equalizer],
      ),
    );
  }

  AndroidEqualizer? get equalizer => _equalizer;

  // Callbacks for notification controls
  Future<void> Function()? onSkipToNext;
  Future<void> Function()? onSkipToPrevious;

  // Streams
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<bool> get playingStream => _player.playingStream;

  // Current state
  bool get isPlaying => _player.playing;
  Duration get position => _player.position;
  Duration get duration => _player.duration ?? Duration.zero;
  double get volume => _player.volume;

  Future<void> initAudioService() async {
    final handler = _MusicAudioHandler(_player);
    _audioHandler = await AudioService.init(
      builder: () => handler,
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.sls.leting.audio',
        androidNotificationChannelName: '乐听',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
      ),
    );
    _audioHandler!.onSkipToNext = () async => onSkipToNext?.call();
    _audioHandler!.onSkipToPrevious = () async => onSkipToPrevious?.call();
  }

  Future<void> play() => _player.play();
  Future<void> pause() => _player.pause();

  Future<void> playFile(String filePath, {Song? song}) async {
    await loadFile(filePath, song: song);
    await _player.play();
  }

  Future<void> loadFile(String filePath, {Song? song}) async {
    await _player.setFilePath(filePath);
    if (_audioHandler != null && song != null) {
      Uri? artUri;
      if (song.coverPath != null && song.coverPath!.isNotEmpty) {
        artUri = Uri.file(song.coverPath!);
      }
      await _audioHandler!.updateMediaItem(MediaItem(
        id: song.id,
        title: song.title,
        artist: song.artist,
        album: song.album,
        duration: Duration(milliseconds: song.duration),
        artUri: artUri,
      ));
    }
  }

  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> setVolume(double volume) => _player.setVolume(volume);

  void setPlayMode(PlayMode mode) {
    switch (mode) {
      case PlayMode.sequence:
        _player.setLoopMode(LoopMode.off);
        _player.setShuffleModeEnabled(false);
      case PlayMode.loop:
        _player.setLoopMode(LoopMode.all);
        _player.setShuffleModeEnabled(false);
      case PlayMode.single:
        _player.setLoopMode(LoopMode.one);
        _player.setShuffleModeEnabled(false);
      case PlayMode.shuffle:
        _player.setLoopMode(LoopMode.all);
        _player.setShuffleModeEnabled(true);
    }
  }

  Future<void> stop() async {
    await _player.stop();
  }

  void dispose() {
    _player.dispose();
  }
}

/// AudioHandler for background playback & notification controls
class _MusicAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player;
  Future<void> Function()? onSkipToNext;
  Future<void> Function()? onSkipToPrevious;

  _MusicAudioHandler(this._player) {
    // Broadcast player state to notification
    _player.playbackEventStream.listen((event) {
      final newState = playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          _player.playing ? MediaControl.pause : MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: _mapProcessingState(_player.processingState),
        playing: _player.playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
      );
      playbackState.add(newState);
    });
  }

  AudioProcessingState _mapProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  @override
  Future<void> updateMediaItem(MediaItem item) async {
    mediaItem.add(item);
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async => onSkipToNext?.call();

  @override
  Future<void> skipToPrevious() async => onSkipToPrevious?.call();

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }
}
