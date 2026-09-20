import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:sonic_player/core/constants/app_constants.dart';
import 'package:sonic_player/domain/entities/song.dart';
import 'package:sonic_player/domain/entities/playlist.dart';

/// SQLite database service for local persistence.
class DatabaseService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.dbName);

    return openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE liked_songs (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        artist TEXT NOT NULL,
        album TEXT,
        thumbnailUrl TEXT NOT NULL,
        highResThumbnailUrl TEXT,
        duration INTEGER NOT NULL DEFAULT 0,
        youtubeId TEXT NOT NULL,
        addedAt TEXT NOT NULL,
        isLiked INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE playlists (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        thumbnailUrl TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE playlist_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        playlistId TEXT NOT NULL,
        songId TEXT NOT NULL,
        title TEXT NOT NULL,
        artist TEXT NOT NULL,
        album TEXT,
        thumbnailUrl TEXT NOT NULL,
        highResThumbnailUrl TEXT,
        duration INTEGER NOT NULL DEFAULT 0,
        youtubeId TEXT NOT NULL,
        sortOrder INTEGER NOT NULL DEFAULT 0,
        addedAt TEXT NOT NULL,
        FOREIGN KEY (playlistId) REFERENCES playlists(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE recently_played (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        artist TEXT NOT NULL,
        album TEXT,
        thumbnailUrl TEXT NOT NULL,
        highResThumbnailUrl TEXT,
        duration INTEGER NOT NULL DEFAULT 0,
        youtubeId TEXT NOT NULL,
        addedAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE search_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        query TEXT NOT NULL UNIQUE,
        searchedAt TEXT NOT NULL
      )
    ''');

    // Indexes
    await db.execute(
        'CREATE INDEX idx_playlist_items_playlist ON playlist_items(playlistId)');
    await db.execute(
        'CREATE INDEX idx_recently_played_added ON recently_played(addedAt DESC)');
    await db.execute(
        'CREATE INDEX idx_liked_songs_added ON liked_songs(addedAt DESC)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle future migrations here
  }

  // ──────────────────────────── LIKED SONGS ────────────────────────────

  Future<List<Song>> getLikedSongs() async {
    final db = await database;
    final maps = await db.query('liked_songs', orderBy: 'addedAt DESC');
    return maps.map((m) => Song.fromJson(m)).toList();
  }

  Future<void> likeSong(Song song) async {
    final db = await database;
    await db.insert('liked_songs', song.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> unlikeSong(String id) async {
    final db = await database;
    await db.delete('liked_songs', where: 'id = ?', whereArgs: [id]);
  }

  Future<bool> isSongLiked(String id) async {
    final db = await database;
    final result =
        await db.query('liked_songs', where: 'id = ?', whereArgs: [id]);
    return result.isNotEmpty;
  }

  // ──────────────────────────── PLAYLISTS ────────────────────────────

  Future<List<Playlist>> getPlaylists() async {
    final db = await database;
    final playlistMaps = await db.query('playlists', orderBy: 'updatedAt DESC');

    final playlists = <Playlist>[];
    for (final pMap in playlistMaps) {
      final songMaps = await db.query(
        'playlist_items',
        where: 'playlistId = ?',
        whereArgs: [pMap['id']],
        orderBy: 'sortOrder ASC',
      );
      final songs = songMaps
          .map((m) => Song(
                id: m['songId'] as String,
                title: m['title'] as String,
                artist: m['artist'] as String,
                album: m['album'] as String?,
                thumbnailUrl: m['thumbnailUrl'] as String,
                highResThumbnailUrl: m['highResThumbnailUrl'] as String?,
                duration: Duration(seconds: m['duration'] as int? ?? 0),
                youtubeId: m['youtubeId'] as String,
              ))
          .toList();
      playlists.add(Playlist.fromJson(pMap, songs: songs));
    }
    return playlists;
  }

  Future<void> insertPlaylist(Playlist playlist) async {
    final db = await database;
    await db.insert('playlists', playlist.toJson());
  }

  Future<void> updatePlaylistName(String id, String newName) async {
    final db = await database;
    await db.update(
      'playlists',
      {'name': newName, 'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deletePlaylist(String id) async {
    final db = await database;
    await db.delete('playlist_items',
        where: 'playlistId = ?', whereArgs: [id]);
    await db.delete('playlists', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> addSongToPlaylist(String playlistId, Song song) async {
    final db = await database;
    final count = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM playlist_items WHERE playlistId = ?',
        [playlistId])) ?? 0;
    await db.insert('playlist_items', {
      'playlistId': playlistId,
      'songId': song.id,
      'title': song.title,
      'artist': song.artist,
      'album': song.album,
      'thumbnailUrl': song.thumbnailUrl,
      'highResThumbnailUrl': song.highResThumbnailUrl,
      'duration': song.duration.inSeconds,
      'youtubeId': song.youtubeId,
      'sortOrder': count,
      'addedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> removeSongFromPlaylist(
      String playlistId, String songId) async {
    final db = await database;
    await db.delete('playlist_items',
        where: 'playlistId = ? AND songId = ?',
        whereArgs: [playlistId, songId]);
  }

  Future<void> reorderPlaylistSongs(
      String playlistId, List<Song> songs) async {
    final db = await database;
    final batch = db.batch();
    for (int i = 0; i < songs.length; i++) {
      batch.update(
        'playlist_items',
        {'sortOrder': i},
        where: 'playlistId = ? AND songId = ?',
        whereArgs: [playlistId, songs[i].id],
      );
    }
    await batch.commit(noResult: true);
  }

  // ──────────────────────────── RECENTLY PLAYED ────────────────────────────

  Future<List<Song>> getRecentlyPlayed() async {
    final db = await database;
    final maps = await db.query('recently_played',
        orderBy: 'addedAt DESC', limit: AppConstants.recentlyPlayedLimit);
    return maps.map((m) => Song.fromJson(m)).toList();
  }

  Future<void> addRecentlyPlayed(Song song) async {
    final db = await database;
    // Remove existing entry first
    await db.delete('recently_played',
        where: 'id = ?', whereArgs: [song.id]);
    await db.insert('recently_played', song.toJson());

    // Trim old entries
    await db.rawDelete('''
      DELETE FROM recently_played WHERE id NOT IN (
        SELECT id FROM recently_played ORDER BY addedAt DESC LIMIT ?
      )
    ''', [AppConstants.recentlyPlayedLimit]);
  }

  Future<void> clearRecentlyPlayed() async {
    final db = await database;
    await db.delete('recently_played');
  }

  // ──────────────────────────── SEARCH HISTORY ────────────────────────────

  Future<List<String>> getSearchHistory() async {
    final db = await database;
    final maps = await db.query('search_history',
        orderBy: 'searchedAt DESC', limit: AppConstants.searchHistoryLimit);
    return maps.map((m) => m['query'] as String).toList();
  }

  Future<void> addSearchQuery(String query) async {
    final db = await database;
    await db.insert(
      'search_history',
      {'query': query, 'searchedAt': DateTime.now().toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removeSearchQuery(String query) async {
    final db = await database;
    await db.delete('search_history',
        where: 'query = ?', whereArgs: [query]);
  }

  Future<void> clearSearchHistory() async {
    final db = await database;
    await db.delete('search_history');
  }

  /// Close the database.
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
