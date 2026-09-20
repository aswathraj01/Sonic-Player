/// Represents a music artist.
class Artist {
  final String id;
  final String name;
  final String thumbnailUrl;
  final String? description;
  final int? subscriberCount;

  const Artist({
    required this.id,
    required this.name,
    required this.thumbnailUrl,
    this.description,
    this.subscriberCount,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'thumbnailUrl': thumbnailUrl,
      'description': description,
      'subscriberCount': subscriberCount,
    };
  }

  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      id: json['id'] as String,
      name: json['name'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String,
      description: json['description'] as String?,
      subscriberCount: json['subscriberCount'] as int?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Artist && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
