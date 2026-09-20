
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sonic_player/core/constants/app_constants.dart';
import 'package:sonic_player/domain/entities/song.dart';
import 'package:sonic_player/domain/entities/artist.dart';
import 'package:sonic_player/domain/entities/album.dart';
import 'package:sonic_player/domain/entities/search_result.dart';
import 'package:sonic_player/core/errors/app_failure.dart';

final youtubeServiceProvider = Provider<YouTubeService>((ref) {
  return YouTubeService();
});

/// Service for interacting with YouTube Data API v3.
///
/// Uses only the official YouTube Data API for search and metadata.
/// Playback is handled via the YouTube IFrame Player (separate widget).
class YouTubeService {
  late final Dio _dio;
  late final String _apiKey;

  YouTubeService() {
    _apiKey = dotenv.env['YOUTUBE_API_KEY'] ?? '';
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.youtubeBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
  }

  /// Search YouTube for music content.
  Future<SearchResult> search(String query, {String? pageToken}) async {
    if (_apiKey.isEmpty) {
      throw const YouTubeApiFailure('YouTube API key not configured.');
    }

    try {
      // Search for videos (music)
      final videoResponse = await _dio.get('/search', queryParameters: {
        'part': 'snippet',
        'q': '$query music',
        'type': 'video',
        'videoCategoryId': '10', // Music category
        'maxResults': AppConstants.searchResultLimit,
        'key': _apiKey,
        if (pageToken != null) 'pageToken': pageToken,
      });

      // Search for channels (artists)
      final channelResponse = await _dio.get('/search', queryParameters: {
        'part': 'snippet',
        'q': '$query artist',
        'type': 'channel',
        'maxResults': 5,
        'key': _apiKey,
      });

      final songs = _parseVideoResults(videoResponse.data);
      final artists = _parseChannelResults(channelResponse.data);
      final nextToken = videoResponse.data['nextPageToken'] as String?;

      // Get video durations
      if (songs.isNotEmpty) {
        final videoIds = songs.map((s) => s.youtubeId).join(',');
        final detailsResponse = await _dio.get('/videos', queryParameters: {
          'part': 'contentDetails,statistics',
          'id': videoIds,
          'key': _apiKey,
        });
        return SearchResult(
          query: query,
          songs: _enrichSongsWithDuration(songs, detailsResponse.data),
          artists: artists,
          albums: _extractAlbumsFromSnippets(videoResponse.data),
          nextPageToken: nextToken,
        );
      }

      return SearchResult(
        query: query,
        songs: songs,
        artists: artists,
        albums: [],
        nextPageToken: nextToken,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        final errorMessage = e.response?.data?['error']?['errors']?[0]?['reason'];
        if (errorMessage == 'quotaExceeded') {
          throw const YouTubeQuotaExhausted();
        }
        throw const YouTubeApiFailure('Access denied. Please check your API key.');
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw const NetworkFailure('Connection timed out.');
      }
      if (e.type == DioExceptionType.connectionError) {
        throw const NetworkFailure();
      }
      throw const YouTubeApiFailure();
    } catch (e) {
      if (e is AppFailure) rethrow;
      throw const UnknownFailure();
    }
  }

  /// Get video details by ID.
  Future<Song?> getVideoDetails(String videoId) async {
    try {
      final response = await _dio.get('/videos', queryParameters: {
        'part': 'snippet,contentDetails,statistics',
        'id': videoId,
        'key': _apiKey,
      });

      final items = response.data['items'] as List?;
      if (items == null || items.isEmpty) return null;

      final item = items[0];
      final snippet = item['snippet'];
      final contentDetails = item['contentDetails'];

      return Song(
        id: videoId,
        title: _cleanTitle(snippet['title'] ?? ''),
        artist: snippet['channelTitle'] ?? 'Unknown Artist',
        thumbnailUrl: _getBestThumbnail(snippet['thumbnails']),
        highResThumbnailUrl: _getHighResThumbnail(snippet['thumbnails']),
        duration: _parseDuration(contentDetails['duration'] ?? 'PT0S'),
        youtubeId: videoId,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get trending music videos.
  Future<List<Song>> getTrendingMusic() async {
    if (_apiKey.isEmpty) {
      throw const YouTubeApiFailure('YouTube API key not configured.');
    }

    try {
      final response = await _dio.get('/videos', queryParameters: {
        'part': 'snippet,contentDetails,statistics',
        'chart': 'mostPopular',
        'videoCategoryId': '10', // Music
        'maxResults': 20, // Enough for quick picks
        'key': _apiKey,
      });

      final items = response.data['items'] as List? ?? [];

      return items.map<Song>((item) {
        final snippet = item['snippet'];
        final contentDetails = item['contentDetails'];
        final videoId = item['id'] as String;

        return Song(
          id: videoId,
          title: _cleanTitle(snippet['title'] ?? ''),
          artist: snippet['channelTitle'] ?? 'Unknown Artist',
          thumbnailUrl: _getBestThumbnail(snippet['thumbnails']),
          highResThumbnailUrl: _getHighResThumbnail(snippet['thumbnails']),
          duration: _parseDuration(contentDetails['duration'] ?? 'PT0S'),
          youtubeId: videoId,
        );
      }).toList();
    } catch (e) {
      if (e is AppFailure) rethrow;
      throw const YouTubeApiFailure('Failed to fetch trending music.');
    }
  }

  List<Song> _parseVideoResults(Map<String, dynamic> data) {
    final items = data['items'] as List? ?? [];
    return items.map<Song>((item) {
      final snippet = item['snippet'];
      final videoId = item['id']?['videoId'] ?? '';
      return Song(
        id: videoId,
        title: _cleanTitle(snippet['title'] ?? ''),
        artist: snippet['channelTitle'] ?? 'Unknown Artist',
        thumbnailUrl: _getBestThumbnail(snippet['thumbnails']),
        highResThumbnailUrl: _getHighResThumbnail(snippet['thumbnails']),
        duration: Duration.zero, // Will be enriched
        youtubeId: videoId,
      );
    }).where((s) => s.id.isNotEmpty).toList();
  }

  List<Artist> _parseChannelResults(Map<String, dynamic> data) {
    final items = data['items'] as List? ?? [];
    return items.map<Artist>((item) {
      final snippet = item['snippet'];
      final channelId = item['id']?['channelId'] ?? item['snippet']?['channelId'] ?? '';
      return Artist(
        id: channelId,
        name: snippet['title'] ?? 'Unknown',
        thumbnailUrl: _getBestThumbnail(snippet['thumbnails']),
        description: snippet['description'],
      );
    }).where((a) => a.id.isNotEmpty).toList();
  }

  List<Song> _enrichSongsWithDuration(
      List<Song> songs, Map<String, dynamic> data) {
    final items = data['items'] as List? ?? [];
    final durationMap = <String, Duration>{};
    for (final item in items) {
      final id = item['id'] as String;
      final duration = _parseDuration(
          item['contentDetails']?['duration'] ?? 'PT0S');
      durationMap[id] = duration;
    }
    return songs.map((song) {
      return song.copyWith(
        duration: durationMap[song.youtubeId] ?? Duration.zero,
      );
    }).toList();
  }

  List<Album> _extractAlbumsFromSnippets(Map<String, dynamic> data) {
    // YouTube search doesn't directly return albums, but we can infer from video descriptions
    // For now, return empty - albums will be a future enhancement
    return [];
  }

  Duration _parseDuration(String isoDuration) {
    final regex = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?');
    final match = regex.firstMatch(isoDuration);
    if (match == null) return Duration.zero;
    final hours = int.tryParse(match.group(1) ?? '0') ?? 0;
    final minutes = int.tryParse(match.group(2) ?? '0') ?? 0;
    final seconds = int.tryParse(match.group(3) ?? '0') ?? 0;
    return Duration(hours: hours, minutes: minutes, seconds: seconds);
  }

  String _getBestThumbnail(Map<String, dynamic>? thumbnails) {
    if (thumbnails == null) return '';
    return thumbnails['high']?['url'] ??
        thumbnails['medium']?['url'] ??
        thumbnails['default']?['url'] ??
        '';
  }

  String _getHighResThumbnail(Map<String, dynamic>? thumbnails) {
    if (thumbnails == null) return '';
    return thumbnails['maxres']?['url'] ??
        thumbnails['high']?['url'] ??
        thumbnails['medium']?['url'] ??
        '';
  }

  /// Clean up YouTube video titles (remove common artifacts).
  String _cleanTitle(String title) {
    return title
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .trim();
  }
}
