import 'package:sonic_player/domain/entities/song.dart';

/// Represents a user-created playlist.
class Playlist {
  final String id;
  final String name;
  final List<Song> songs;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? thumbnailUrl;

  const Playlist({
    required this.id,
    required this.name,
    required this.songs,
    required this.createdAt,
    required this.updatedAt,
    this.thumbnailUrl,
  });

  Playlist copyWith({
    String? id,
    String? name,
    List<Song>? songs,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? thumbnailUrl,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      songs: songs ?? this.songs,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
    );
  }

  int get songCount => songs.length;

  /// Gets a display thumbnail from the first song if no explicit thumbnail.
  String? get displayThumbnail =>
      thumbnailUrl ?? (songs.isNotEmpty ? songs.first.thumbnailUrl : null);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'thumbnailUrl': thumbnailUrl,
    };
  }

  factory Playlist.fromJson(Map<String, dynamic> json, {List<Song>? songs}) {
    return Playlist(
      id: json['id'] as String,
      name: json['name'] as String,
      songs: songs ?? [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      thumbnailUrl: json['thumbnailUrl'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Playlist && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
