class Song {
  final String id;
  final String title;
  final String artist;
  final String album;
  final int duration; // milliseconds
  final String filePath;
  final String? coverPath;
  final bool isLocal;
  final DateTime addedAt;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    required this.filePath,
    this.coverPath,
    this.isLocal = true,
    required this.addedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'duration': duration,
      'file_path': filePath,
      'cover_path': coverPath,
      'is_local': isLocal ? 1 : 0,
      'added_at': addedAt.toIso8601String(),
    };
  }

  factory Song.fromMap(Map<String, dynamic> map) {
    return Song(
      id: map['id'] as String,
      title: map['title'] as String,
      artist: map['artist'] as String? ?? '未知艺人',
      album: map['album'] as String? ?? '未知专辑',
      duration: map['duration'] as int? ?? 0,
      filePath: map['file_path'] as String,
      coverPath: map['cover_path'] as String?,
      isLocal: (map['is_local'] as int? ?? 1) == 1,
      addedAt: DateTime.parse(
          map['added_at'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  String get durationFormatted {
    final total = Duration(milliseconds: duration);
    final minutes = total.inMinutes;
    final seconds = total.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Song && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
