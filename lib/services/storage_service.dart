import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/song.dart';
import '../models/playlist.dart';

class StorageService {
  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'music_player.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE songs (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        artist TEXT,
        album TEXT,
        duration INTEGER DEFAULT 0,
        file_path TEXT NOT NULL,
        cover_path TEXT,
        is_local INTEGER DEFAULT 1,
        added_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE playlists (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        gradient_index INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE playlist_songs (
        playlist_id TEXT NOT NULL,
        song_id TEXT NOT NULL,
        sort_order INTEGER DEFAULT 0,
        added_at TEXT NOT NULL,
        PRIMARY KEY (playlist_id, song_id),
        FOREIGN KEY (playlist_id) REFERENCES playlists(id) ON DELETE CASCADE,
        FOREIGN KEY (song_id) REFERENCES songs(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE favorites (
        song_id TEXT PRIMARY KEY,
        added_at TEXT NOT NULL,
        FOREIGN KEY (song_id) REFERENCES songs(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE play_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        song_id TEXT NOT NULL,
        played_at TEXT NOT NULL,
        FOREIGN KEY (song_id) REFERENCES songs(id) ON DELETE CASCADE
      )
    ''');
  }

  // --- Songs CRUD ---

  Future<void> insertSong(Song song) async {
    final db = await database;
    await db.insert('songs', song.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertSongs(List<Song> songs) async {
    final db = await database;
    final batch = db.batch();
    for (final song in songs) {
      batch.insert('songs', song.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Song>> getAllSongs() async {
    final db = await database;
    final maps = await db.query('songs', orderBy: 'title ASC');
    return maps.map((m) => Song.fromMap(m)).toList();
  }

  Future<Song?> getSongById(String id) async {
    final db = await database;
    final maps = await db.query('songs', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Song.fromMap(maps.first);
  }

  Future<List<Song>> getSongsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final db = await database;
    final placeholders = List.filled(ids.length, '?').join(',');
    final maps = await db.query(
      'songs',
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
    final songMap = {for (final m in maps) m['id'] as String: Song.fromMap(m)};
    // 按传入的 ids 顺序返回，跳过不存在的
    return ids.where((id) => songMap.containsKey(id)).map((id) => songMap[id]!).toList();
  }

  Future<List<Song>> searchSongs(String query) async {
    final db = await database;
    final q = '%$query%';
    final maps = await db.query(
      'songs',
      where: 'title LIKE ? OR artist LIKE ? OR album LIKE ?',
      whereArgs: [q, q, q],
      orderBy: 'title ASC',
    );
    return maps.map((m) => Song.fromMap(m)).toList();
  }

  Future<void> deleteSong(String id) async {
    final db = await database;
    await db.delete('songs', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAllSongs() async {
    final db = await database;
    await db.delete('songs');
  }

  // --- Playlists CRUD ---

  Future<void> insertPlaylist(Playlist playlist) async {
    final db = await database;
    await db.insert('playlists', playlist.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Playlist>> getAllPlaylists() async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT p.*, COUNT(ps.song_id) as song_count
      FROM playlists p
      LEFT JOIN playlist_songs ps ON p.id = ps.playlist_id
      GROUP BY p.id
      ORDER BY p.updated_at DESC
    ''');
    return maps.map((m) => Playlist.fromMap(m)).toList();
  }

  Future<void> updatePlaylist(Playlist playlist) async {
    final db = await database;
    await db.update('playlists', playlist.toMap(),
        where: 'id = ?', whereArgs: [playlist.id]);
  }

  Future<void> deletePlaylist(String id) async {
    final db = await database;
    await db.delete('playlist_songs',
        where: 'playlist_id = ?', whereArgs: [id]);
    await db.delete('playlists', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Song>> getPlaylistSongs(String playlistId) async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT s.* FROM songs s
      INNER JOIN playlist_songs ps ON s.id = ps.song_id
      WHERE ps.playlist_id = ?
      ORDER BY ps.sort_order ASC
    ''', [playlistId]);
    return maps.map((m) => Song.fromMap(m)).toList();
  }

  Future<void> addSongToPlaylist(String playlistId, String songId) async {
    final db = await database;
    final count = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT MAX(sort_order) FROM playlist_songs WHERE playlist_id = ?',
      [playlistId],
    ));
    await db.insert(
      'playlist_songs',
      {
        'playlist_id': playlistId,
        'song_id': songId,
        'sort_order': (count ?? 0) + 1,
        'added_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> removeSongFromPlaylist(
      String playlistId, String songId) async {
    final db = await database;
    await db.delete('playlist_songs',
        where: 'playlist_id = ? AND song_id = ?',
        whereArgs: [playlistId, songId]);
  }

  // --- Favorites ---

  Future<void> addFavorite(String songId) async {
    final db = await database;
    await db.insert(
      'favorites',
      {'song_id': songId, 'added_at': DateTime.now().toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> removeFavorite(String songId) async {
    final db = await database;
    await db.delete('favorites', where: 'song_id = ?', whereArgs: [songId]);
  }

  Future<bool> isFavorite(String songId) async {
    final db = await database;
    final result = await db
        .query('favorites', where: 'song_id = ?', whereArgs: [songId]);
    return result.isNotEmpty;
  }

  Future<List<Song>> getFavorites() async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT s.* FROM songs s
      INNER JOIN favorites f ON s.id = f.song_id
      ORDER BY f.added_at DESC
    ''');
    return maps.map((m) => Song.fromMap(m)).toList();
  }

  Future<int> getFavoriteCount() async {
    final db = await database;
    return Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM favorites')) ??
        0;
  }

  // --- Play History ---

  Future<void> addPlayHistory(String songId) async {
    final db = await database;
    await db.insert('play_history', {
      'song_id': songId,
      'played_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Song>> getPlayHistory({int limit = 50}) async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT s.*, ph.played_at FROM songs s
      INNER JOIN (
        SELECT song_id, MAX(played_at) as played_at
        FROM play_history
        GROUP BY song_id
      ) ph ON s.id = ph.song_id
      ORDER BY ph.played_at DESC
      LIMIT ?
    ''', [limit]);
    return maps.map((m) => Song.fromMap(m)).toList();
  }

  Future<void> clearPlayHistory() async {
    final db = await database;
    await db.delete('play_history');
  }
}
