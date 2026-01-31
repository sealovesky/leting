class Playlist {
  final String id;
  final String name;
  final String? description;
  final int gradientIndex;
  final DateTime createdAt;
  final DateTime updatedAt;
  int songCount;

  Playlist({
    required this.id,
    required this.name,
    this.description,
    this.gradientIndex = 0,
    required this.createdAt,
    required this.updatedAt,
    this.songCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'gradient_index': gradientIndex,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Playlist.fromMap(Map<String, dynamic> map) {
    return Playlist(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      gradientIndex: map['gradient_index'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      songCount: map['song_count'] as int? ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Playlist && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
