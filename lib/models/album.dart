class Album {
  final String name;
  final String artist;
  final String? coverPath;
  final int songCount;

  const Album({
    required this.name,
    required this.artist,
    this.coverPath,
    this.songCount = 0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Album && name == other.name && artist == other.artist;

  @override
  int get hashCode => Object.hash(name, artist);
}
