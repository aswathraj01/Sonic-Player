/// Represents a song/track in the application.
class Song {
  final String id;
  final String title;
  final String artist;
  final String? album;
  final String thumbnailUrl;
  final String? highResThumbnailUrl;
  final Duration duration;
  final String youtubeId;
  final DateTime? addedAt;
  final bool isLiked;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    required this.thumbnailUrl,
    this.highResThumbnailUrl,
    required this.duration,
    required this.youtubeId,
    this.addedAt,
    this.isLiked = false,
  });

  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    String? thumbnailUrl,
    String? highResThumbnailUrl,
    Duration? duration,
    String? youtubeId,
    DateTime? addedAt,
    bool? isLiked,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      highResThumbnailUrl: highResThumbnailUrl ?? this.highResThumbnailUrl,
      duration: duration ?? this.duration,
      youtubeId: youtubeId ?? this.youtubeId,
      addedAt: addedAt ?? this.addedAt,
      isLiked: isLiked ?? this.isLiked,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'thumbnailUrl': thumbnailUrl,
      'highResThumbnailUrl': highResThumbnailUrl,
      'duration': duration.inSeconds,
      'youtubeId': youtubeId,
      'addedAt': addedAt?.toIso8601String(),
      'isLiked': isLiked ? 1 : 0,
    };
  }

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      album: json['album'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String,
      highResThumbnailUrl: json['highResThumbnailUrl'] as String?,
      duration: Duration(seconds: json['duration'] as int? ?? 0),
      youtubeId: json['youtubeId'] as String,
      addedAt: json['addedAt'] != null
          ? DateTime.parse(json['addedAt'] as String)
          : null,
      isLiked: json['isLiked'] == 1 || json['isLiked'] == true,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Song && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Song(id: $id, title: $title, artist: $artist)';

  /// Formatted duration string (e.g. "3:45")
  String get formattedDuration {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
