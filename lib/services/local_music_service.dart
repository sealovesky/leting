import 'dart:io';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/song.dart';

class LocalMusicService {
  static const _audioExtensions = {
    '.mp3', '.flac', '.wav', '.aac', '.m4a', '.ogg', '.wma',
  };

  /// Scan for music files in common directories
  Stream<Song> scanLocalMusic() async* {
    final directories = await _getMusicDirectories();
    for (final dir in directories) {
      if (!await dir.exists()) continue;
      yield* _scanDirectory(dir);
    }
  }

  Stream<Song> _scanDirectory(Directory dir) async* {
    try {
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is! File) continue;
        final ext = p.extension(entity.path).toLowerCase();
        if (!_audioExtensions.contains(ext)) continue;

        final song = await _extractMetadata(entity);
        if (song != null) yield song;
      }
    } catch (_) {
      // Skip directories we can't access
    }
  }

  Future<Song?> _extractMetadata(File file) async {
    try {
      final metadata = readMetadata(file, getImage: true);
      final coverPath = await _saveCoverArt(file.path, metadata);

      return Song(
        id: file.path.hashCode.toRadixString(36),
        title: metadata.title ?? p.basenameWithoutExtension(file.path),
        artist: metadata.artist ?? '未知艺人',
        album: metadata.album ?? '未知专辑',
        duration: metadata.duration?.inMilliseconds ?? 0,
        filePath: file.path,
        coverPath: coverPath,
        isLocal: true,
        addedAt: DateTime.now(),
      );
    } catch (_) {
      // Fallback: use filename as title
      return Song(
        id: file.path.hashCode.toRadixString(36),
        title: p.basenameWithoutExtension(file.path),
        artist: '未知艺人',
        album: '未知专辑',
        duration: 0,
        filePath: file.path,
        isLocal: true,
        addedAt: DateTime.now(),
      );
    }
  }

  Future<String?> _saveCoverArt(
      String filePath, AudioMetadata metadata) async {
    if (metadata.pictures.isEmpty) return null;
    final picture = metadata.pictures.first;

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final coverDir = Directory(p.join(appDir.path, 'covers'));
      if (!await coverDir.exists()) {
        await coverDir.create(recursive: true);
      }
      final ext = picture.mimetype.contains('png') ? '.png' : '.jpg';
      final coverFile = File(p.join(
        coverDir.path,
        '${filePath.hashCode.toRadixString(36)}$ext',
      ));
      await coverFile.writeAsBytes(picture.bytes);
      return coverFile.path;
    } catch (_) {
      return null;
    }
  }

  Future<List<Directory>> _getMusicDirectories() async {
    final dirs = <Directory>[];
    if (Platform.isAndroid) {
      dirs.add(Directory('/storage/emulated/0/Music'));
      dirs.add(Directory('/storage/emulated/0/Download'));
      // External storage
      try {
        final extDirs = await getExternalStorageDirectories(
            type: StorageDirectory.music);
        if (extDirs != null) dirs.addAll(extDirs);
      } catch (_) {}
    } else if (Platform.isIOS) {
      final appDir = await getApplicationDocumentsDirectory();
      dirs.add(appDir);
    } else if (Platform.isMacOS) {
      final home = Platform.environment['HOME'];
      if (home != null) {
        dirs.add(Directory('$home/Music'));
        dirs.add(Directory('$home/Downloads'));
      }
    }
    return dirs;
  }
}
