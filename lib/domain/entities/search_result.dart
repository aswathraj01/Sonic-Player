import 'package:sonic_player/domain/entities/song.dart';
import 'package:sonic_player/domain/entities/artist.dart';
import 'package:sonic_player/domain/entities/album.dart';

/// Aggregated search results from YouTube.
class SearchResult {
  final String query;
  final List<Song> songs;
  final List<Artist> artists;
  final List<Album> albums;
  final String? nextPageToken;

  const SearchResult({
    required this.query,
    required this.songs,
    required this.artists,
    required this.albums,
    this.nextPageToken,
  });

  bool get isEmpty => songs.isEmpty && artists.isEmpty && albums.isEmpty;
  bool get isNotEmpty => !isEmpty;

  int get totalResults => songs.length + artists.length + albums.length;

  const SearchResult.empty({this.query = ''})
      : songs = const [],
        artists = const [],
        albums = const [],
        nextPageToken = null;
}

/// Filter type for search results display.
enum SearchFilter {
  all('All'),
  songs('Songs'),
  artists('Artists'),
  albums('Albums'),
  playlists('Playlists');

  const SearchFilter(this.label);
  final String label;
}
