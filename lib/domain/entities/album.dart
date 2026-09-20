/// Represents a music album.
class Album {
  final String id;
  final String title;
  final String artist;
  final String thumbnailUrl;
  final int? year;
  final int? trackCount;

  const Album({
    required this.id,
    required this.title,
    required this.artist,
    required this.thumbnailUrl,
    this.year,
    this.trackCount,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'thumbnailUrl': thumbnailUrl,
      'year': year,
      'trackCount': trackCount,
    };
  }

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String,
      year: json['year'] as int?,
      trackCount: json['trackCount'] as int?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Album && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
