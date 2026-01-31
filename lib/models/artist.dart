class Artist {
  final String name;
  final String? bio;
  final String? coverPath;
  final int songCount;

  const Artist({
    required this.name,
    this.bio,
    this.coverPath,
    this.songCount = 0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Artist && name == other.name;

  @override
  int get hashCode => name.hashCode;
}
