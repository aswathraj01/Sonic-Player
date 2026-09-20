import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:sonic_player/domain/entities/playback_state.dart' as app;
import 'package:sonic_player/services/playback/playback_provider.dart';

/// Provider for the YouTube player controller — singleton across the app.
final youtubePlayerControllerProvider =
    Provider<YoutubePlayerController>((ref) {
  final controller = YoutubePlayerController(
    params: const YoutubePlayerParams(
      showControls: false,
      showFullscreenButton: false,
      mute: false,
      enableCaption: false,
      playsInline: true,
      strictRelatedVideos: true,
    ),
  );

  ref.onDispose(() {
    controller.close();
  });

  return controller;
});

/// Service that bridges YoutubePlayerController ↔ PlaybackNotifier.
///
/// Listens to the YouTube player's state and position changes and
/// forwards them into the Riverpod PlaybackNotifier. Also receives
/// commands from the notifier (play, pause, seek, load) and sends
/// them to the controller.
class YouTubePlayerService {
  final YoutubePlayerController controller;
  final PlaybackNotifier playbackNotifier;
  Timer? _positionTimer;
  bool _isDisposed = false;

  YouTubePlayerService({
    required this.controller,
    required this.playbackNotifier,
  }) {
    _listenToPlayerState();
  }

  /// Start listening to player state changes.
  void _listenToPlayerState() {
    controller.listen((event) {
      if (_isDisposed) return;
      _onPlayerStateChanged(event);
    });
  }

  /// React to YouTube player state changes.
  void _onPlayerStateChanged(YoutubePlayerValue value) {
    switch (value.playerState) {
      case PlayerState.playing:
        playbackNotifier.setStatus(app.PlayStatus.playing);
        _startPositionPolling();
        break;
      case PlayerState.paused:
        playbackNotifier.setStatus(app.PlayStatus.paused);
        _stopPositionPolling();
        break;
      case PlayerState.buffering:
        playbackNotifier.setStatus(app.PlayStatus.buffering);
        break;
      case PlayerState.ended:
        _stopPositionPolling();
        playbackNotifier.onSongCompleted();
        break;
      case PlayerState.cued:
        // Video is cued and ready — update duration
        _updateDuration();
        break;
      case PlayerState.unStarted:
        break;
      default:
        break;
    }
  }

  /// Load and auto-play a YouTube video by its ID.
  Future<void> loadVideo(String videoId) async {
    _stopPositionPolling();
    playbackNotifier.setStatus(app.PlayStatus.loading);
    controller.loadVideoById(videoId: videoId);
    // Duration will be updated once the video starts playing/cues
    _scheduleDurationFetch();
  }

  /// Play the current video.
  void play() {
    controller.playVideo();
  }

  /// Pause the current video.
  void pause() {
    controller.pauseVideo();
  }

  /// Seek to a specific position.
  Future<void> seekTo(Duration position) async {
    controller.seekTo(seconds: position.inSeconds.toDouble(), allowSeekAhead: true);
  }

  /// Start polling for position updates (every 500ms).
  void _startPositionPolling() {
    _stopPositionPolling();
    _positionTimer = Timer.periodic(const Duration(milliseconds: 500), (_) async {
      if (_isDisposed) return;
      try {
        final currentTime = await controller.currentTime;
        final seconds = currentTime;
        playbackNotifier.updatePosition(
          Duration(milliseconds: (seconds * 1000).toInt()),
        );
      } catch (_) {
        // Ignore errors during polling
      }
    });
  }

  /// Stop position polling.
  void _stopPositionPolling() {
    _positionTimer?.cancel();
    _positionTimer = null;
  }

  /// Fetch the video duration after a short delay (for the player to be ready).
  void _scheduleDurationFetch() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!_isDisposed) _updateDuration();
    });
  }

  /// Read the current video duration from the controller.
  Future<void> _updateDuration() async {
    try {
      final dur = await controller.duration;
      if (dur > 0) {
        playbackNotifier.updateDuration(
          Duration(milliseconds: (dur * 1000).toInt()),
        );
      }
    } catch (_) {
      // Ignore — duration may not be available yet
    }
  }

  /// Dispose resources.
  void dispose() {
    _isDisposed = true;
    _stopPositionPolling();
  }
}

/// Provider for the YouTubePlayerService.
final youtubePlayerServiceProvider = Provider<YouTubePlayerService>((ref) {
  final controller = ref.watch(youtubePlayerControllerProvider);
  final playbackNotifier = ref.watch(playbackProvider.notifier);
  final service = YouTubePlayerService(
    controller: controller,
    playbackNotifier: playbackNotifier,
  );

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

/// Provider to control whether the hidden YouTube player is rendered.
/// Set to false in tests to avoid WebView platform requirements.
final enableHiddenPlayerProvider = Provider<bool>((ref) => true);

/// Widget that hosts the hidden YouTube player in the widget tree.
///
/// Must be placed in the AppShell so the player persists across navigations.
/// Renders at 1x1 pixel with no visual presence.
class HiddenYoutubePlayer extends ConsumerWidget {
  const HiddenYoutubePlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // In tests, skip rendering the YouTube player (requires WebView platform)
    if (!ref.watch(enableHiddenPlayerProvider)) {
      return const SizedBox.shrink();
    }

    final controller = ref.watch(youtubePlayerControllerProvider);
    // Eagerly initialize the service so it starts listening
    ref.watch(youtubePlayerServiceProvider);

    return SizedBox(
      width: 1,
      height: 1,
      child: Opacity(
        opacity: 0,
        child: IgnorePointer(
          child: YoutubePlayer(
            controller: controller,
            aspectRatio: 16 / 9,
          ),
        ),
      ),
    );
  }
}
