import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sonic_player/domain/entities/song.dart';
import 'package:sonic_player/domain/entities/playlist.dart';
import 'package:sonic_player/services/database/database_service.dart';
import 'package:uuid/uuid.dart';

/// Provider for the database service.
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

/// Provider for liked songs.
final likedSongsProvider =
    StateNotifierProvider<LikedSongsNotifier, List<Song>>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return LikedSongsNotifier(db);
});

/// Provider for playlists.
final playlistsProvider =
    StateNotifierProvider<PlaylistsNotifier, List<Playlist>>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return PlaylistsNotifier(db);
});

/// Provider for recently played songs.
final recentlyPlayedProvider =
    StateNotifierProvider<RecentlyPlayedNotifier, List<Song>>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return RecentlyPlayedNotifier(db);
});

/// Manages liked songs.
class LikedSongsNotifier extends StateNotifier<List<Song>> {
  final DatabaseService _db;

  LikedSongsNotifier(this._db) : super([]) {
    _loadLikedSongs();
  }

  Future<void> _loadLikedSongs() async {
    final songs = await _db.getLikedSongs();
    if (mounted) state = songs;
  }

  Future<void> toggleLike(Song song) async {
    final isLiked = state.any((s) => s.id == song.id);
    if (isLiked) {
      await _db.unlikeSong(song.id);
      state = state.where((s) => s.id != song.id).toList();
    } else {
      final likedSong = song.copyWith(isLiked: true, addedAt: DateTime.now());
      await _db.likeSong(likedSong);
      state = [likedSong, ...state];
    }
  }

  bool isLiked(String songId) {
    return state.any((s) => s.id == songId);
  }

  Future<void> refresh() async => _loadLikedSongs();
}

/// Manages user playlists.
class PlaylistsNotifier extends StateNotifier<List<Playlist>> {
  final DatabaseService _db;
  final _uuid = const Uuid();

  PlaylistsNotifier(this._db) : super([]) {
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    final playlists = await _db.getPlaylists();
    if (mounted) state = playlists;
  }

  Future<Playlist> createPlaylist(String name) async {
    final now = DateTime.now();
    final playlist = Playlist(
      id: _uuid.v4(),
      name: name,
      songs: [],
      createdAt: now,
      updatedAt: now,
    );
    await _db.insertPlaylist(playlist);
    state = [playlist, ...state];
    return playlist;
  }

  Future<void> renamePlaylist(String id, String newName) async {
    await _db.updatePlaylistName(id, newName);
    state = state.map((p) {
      if (p.id == id) return p.copyWith(name: newName, updatedAt: DateTime.now());
      return p;
    }).toList();
  }

  Future<void> deletePlaylist(String id) async {
    await _db.deletePlaylist(id);
    state = state.where((p) => p.id != id).toList();
  }

  Future<void> addSongToPlaylist(String playlistId, Song song) async {
    await _db.addSongToPlaylist(playlistId, song);
    state = state.map((p) {
      if (p.id == playlistId) {
        return p.copyWith(
          songs: [...p.songs, song],
          updatedAt: DateTime.now(),
        );
      }
      return p;
    }).toList();
  }

  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    await _db.removeSongFromPlaylist(playlistId, songId);
    state = state.map((p) {
      if (p.id == playlistId) {
        return p.copyWith(
          songs: p.songs.where((s) => s.id != songId).toList(),
          updatedAt: DateTime.now(),
        );
      }
      return p;
    }).toList();
  }

  Future<void> reorderPlaylistSongs(
      String playlistId, int oldIndex, int newIndex) async {
    state = state.map((p) {
      if (p.id == playlistId) {
        final songs = [...p.songs];
        final song = songs.removeAt(oldIndex);
        if (newIndex > oldIndex) newIndex--;
        songs.insert(newIndex, song);
        return p.copyWith(songs: songs, updatedAt: DateTime.now());
      }
      return p;
    }).toList();
    // Persist reorder
    final playlist = state.firstWhere((p) => p.id == playlistId);
    await _db.reorderPlaylistSongs(playlistId, playlist.songs);
  }

  Playlist? getPlaylist(String id) {
    try {
      return state.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> refresh() async => _loadPlaylists();
}

/// Manages recently played songs.
class RecentlyPlayedNotifier extends StateNotifier<List<Song>> {
  final DatabaseService _db;
  static const int _maxRecent = 50;

  RecentlyPlayedNotifier(this._db) : super([]) {
    _loadRecentlyPlayed();
  }

  Future<void> _loadRecentlyPlayed() async {
    final songs = await _db.getRecentlyPlayed();
    if (mounted) state = songs;
  }

  Future<void> addSong(Song song) async {
    // Remove duplicate if exists
    final filtered = state.where((s) => s.id != song.id).toList();
    final updatedSong = song.copyWith(addedAt: DateTime.now());
    final newList = [updatedSong, ...filtered].take(_maxRecent).toList();
    state = newList;
    await _db.addRecentlyPlayed(updatedSong);
  }

  Future<void> clear() async {
    await _db.clearRecentlyPlayed();
    state = [];
  }

  Future<void> refresh() async => _loadRecentlyPlayed();
}
