/// Base class for application failures.
sealed class AppFailure {
  final String message;
  final String? technicalDetails;

  const AppFailure(this.message, {this.technicalDetails});

  @override
  String toString() => 'AppFailure: $message';
}

class NetworkFailure extends AppFailure {
  const NetworkFailure([super.message = 'Unable to connect. Please check your internet connection.']);
}

class ServerFailure extends AppFailure {
  final int? statusCode;
  const ServerFailure([super.message = 'Something went wrong. Please try again.', this.statusCode]);
}

class YouTubeApiFailure extends AppFailure {
  const YouTubeApiFailure([super.message = 'Unable to fetch content from YouTube.']);
}

class YouTubeQuotaExhausted extends AppFailure {
  const YouTubeQuotaExhausted([super.message = 'YouTube API quota exceeded. Please try again later.']);
}

class ContentUnavailable extends AppFailure {
  const ContentUnavailable([super.message = 'This content is unavailable.']);
}

class RegionRestricted extends AppFailure {
  const RegionRestricted([super.message = 'This content is not available in your region.']);
}

class AgeRestricted extends AppFailure {
  const AgeRestricted([super.message = 'This content requires age verification.']);
}

class PlaybackFailure extends AppFailure {
  const PlaybackFailure([super.message = 'Playback failed. Please try another song.']);
}

class StorageFailure extends AppFailure {
  const StorageFailure([super.message = 'Unable to save data locally.']);
}

class AuthFailure extends AppFailure {
  const AuthFailure([super.message = 'Authentication failed. Please try again.']);
}

class ValidationFailure extends AppFailure {
  const ValidationFailure([super.message = 'Invalid input. Please check and try again.']);
}

class CacheFailure extends AppFailure {
  const CacheFailure([super.message = 'Unable to load cached data.']);
}

class UnknownFailure extends AppFailure {
  const UnknownFailure([super.message = 'An unexpected error occurred.']);
}
