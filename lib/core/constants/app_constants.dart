class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'Sonic Player';
  static const String appTagline = 'Feel Every Beat';
  static const String appVersion = '1.0.0';

  // YouTube API
  static const String youtubeBaseUrl = 'https://www.googleapis.com/youtube/v3';
  static const String youtubeSearchEndpoint = '$youtubeBaseUrl/search';
  static const String youtubeVideoEndpoint = '$youtubeBaseUrl/videos';

  // Search
  static const int searchResultLimit = 20;
  static const int searchHistoryLimit = 20;
  static const int searchDebounceMs = 500;

  // Playback
  static const int maxQueueSize = 500;
  static const int recentlyPlayedLimit = 50;

  // UI
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;
  static const double borderRadiusXLarge = 20.0;
  static const double borderRadiusRound = 100.0;

  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;

  static const double iconSizeSmall = 20.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 28.0;
  static const double iconSizeXLarge = 36.0;

  // Animation Durations
  static const Duration animFast = Duration(milliseconds: 150);
  static const Duration animNormal = Duration(milliseconds: 300);
  static const Duration animSlow = Duration(milliseconds: 500);
  static const Duration animVerySlow = Duration(milliseconds: 800);

  // Artwork sizes
  static const double artworkTiny = 40.0;
  static const double artworkSmall = 48.0;
  static const double artworkMedium = 56.0;
  static const double artworkLarge = 120.0;
  static const double artworkXLarge = 280.0;

  // Mini Player
  static const double miniPlayerHeight = 64.0;

  // Bottom Nav
  static const double bottomNavHeight = 60.0;

  // Database
  static const String dbName = 'sonic_player.db';
  static const int dbVersion = 1;

  // Storage Keys
  static const String keyThemeMode = 'theme_mode';
  static const String keyPlaybackQuality = 'playback_quality';
  static const String keyShuffleEnabled = 'shuffle_enabled';
  static const String keyRepeatMode = 'repeat_mode';
  static const String keyLastPlayedSong = 'last_played_song';
  static const String keySearchHistory = 'search_history';
  static const String keyNotificationsEnabled = 'notifications_enabled';
}
