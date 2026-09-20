import 'package:sonic_player/domain/entities/song.dart';

/// Represents the current playback state of the player.
enum PlayStatus {
  idle,
  loading,
  buffering,
  playing,
  paused,
  completed,
  error,
}

/// Repeat mode for playback.
enum RepeatMode {
  off,
  all,
  one,
}

/// Audio quality preference.
enum AudioQuality {
  auto('Auto'),
  high('High'),
  medium('Medium'),
  low('Low');

  const AudioQuality(this.label);
  final String label;
}

/// Central playback state object.
class PlaybackState {
  final Song? currentSong;
  final PlayStatus status;
  final Duration position;
  final Duration duration;
  final Duration bufferedPosition;
  final List<Song> queue;
  final int currentIndex;
  final bool shuffleEnabled;
  final RepeatMode repeatMode;
  final AudioQuality quality;
  final String? errorMessage;
  final double volume;

  const PlaybackState({
    this.currentSong,
    this.status = PlayStatus.idle,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.bufferedPosition = Duration.zero,
    this.queue = const [],
    this.currentIndex = -1,
    this.shuffleEnabled = false,
    this.repeatMode = RepeatMode.off,
    this.quality = AudioQuality.auto,
    this.errorMessage,
    this.volume = 1.0,
  });

  bool get isPlaying => status == PlayStatus.playing;
  bool get isPaused => status == PlayStatus.paused;
  bool get isLoading =>
      status == PlayStatus.loading || status == PlayStatus.buffering;
  bool get hasError => status == PlayStatus.error;
  bool get isIdle => status == PlayStatus.idle;
  bool get hasSong => currentSong != null;
  bool get hasQueue => queue.isNotEmpty;
  bool get canPlayNext => currentIndex < queue.length - 1 || repeatMode == RepeatMode.all;
  bool get canPlayPrevious => currentIndex > 0 || repeatMode == RepeatMode.all;

  /// Progress as a value between 0.0 and 1.0.
  double get progress {
    if (duration.inMilliseconds == 0) return 0.0;
    return (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
  }

  PlaybackState copyWith({
    Song? currentSong,
    PlayStatus? status,
    Duration? position,
    Duration? duration,
    Duration? bufferedPosition,
    List<Song>? queue,
    int? currentIndex,
    bool? shuffleEnabled,
    RepeatMode? repeatMode,
    AudioQuality? quality,
    String? errorMessage,
    double? volume,
  }) {
    return PlaybackState(
      currentSong: currentSong ?? this.currentSong,
      status: status ?? this.status,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      bufferedPosition: bufferedPosition ?? this.bufferedPosition,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      shuffleEnabled: shuffleEnabled ?? this.shuffleEnabled,
      repeatMode: repeatMode ?? this.repeatMode,
      quality: quality ?? this.quality,
      errorMessage: errorMessage ?? this.errorMessage,
      volume: volume ?? this.volume,
    );
  }
}
