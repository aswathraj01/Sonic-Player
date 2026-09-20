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
///
/// Includes a **ready-guard**: if [loadVideo] is called before the
/// IFrame has fully initialised, the video ID is queued and replayed
/// the moment the player becomes ready.
class YouTubePlayerService {
  final YoutubePlayerController controller;
  final PlaybackNotifier playbackNotifier;
  Timer? _positionTimer;
  bool _isDisposed = false;

  /// True once the player has fired at least one non-unStarted state.
  bool _isPlayerReady = false;

  /// Video ID waiting to be loaded once the player becomes ready.
  String? _pendingVideoId;

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
        _markReady();
        playbackNotifier.setStatus(app.PlayStatus.playing);
        _startPositionPolling();
        break;
      case PlayerState.paused:
        _markReady();
        playbackNotifier.setStatus(app.PlayStatus.paused);
        _stopPositionPolling();
        break;
      case PlayerState.buffering:
        _markReady();
        playbackNotifier.setStatus(app.PlayStatus.buffering);
        break;
      case PlayerState.ended:
        _stopPositionPolling();
        playbackNotifier.onSongCompleted();
        break;
      case PlayerState.cued:
        _markReady();
        _updateDuration();
        break;
      case PlayerState.unStarted:
        // Not yet ready — do nothing
        break;
      default:
        break;
    }
  }

  /// Mark the player as ready and flush any queued video load.
  void _markReady() {
    if (_isPlayerReady) return;
    _isPlayerReady = true;
    final pending = _pendingVideoId;
    if (pending != null) {
      _pendingVideoId = null;
      // Small delay so the IFrame settles before we issue loadVideoById
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!_isDisposed) {
          controller.loadVideoById(videoId: pending);
        }
      });
    }
  }

  /// Load and auto-play a YouTube video by its ID.
  ///
  /// If the player is not yet ready, the video ID is queued and will
  /// be loaded automatically once the player fires its first state event.
  Future<void> loadVideo(String videoId) async {
    _stopPositionPolling();
    playbackNotifier.setStatus(app.PlayStatus.loading);

    if (!_isPlayerReady) {
      // Queue it — will be replayed in _markReady()
      _pendingVideoId = videoId;
      // Also schedule a fallback in case the player never fires a state change
      Future.delayed(const Duration(seconds: 2), () {
        if (!_isDisposed && !_isPlayerReady) {
          _isPlayerReady = true;
          _pendingVideoId = null;
          controller.loadVideoById(videoId: videoId);
        }
      });
      return;
    }

    // Player is ready — load immediately
    _pendingVideoId = null;
    controller.loadVideoById(videoId: videoId);
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
    controller.seekTo(
        seconds: position.inSeconds.toDouble(), allowSeekAhead: true);
  }

  /// Start polling for position updates (every 500ms).
  void _startPositionPolling() {
    _stopPositionPolling();
    _positionTimer =
        Timer.periodic(const Duration(milliseconds: 500), (_) async {
      if (_isDisposed) return;
      try {
        final currentTime = await controller.currentTime;
        playbackNotifier.updatePosition(
          Duration(milliseconds: (currentTime * 1000).toInt()),
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
/// Renders at 1x1 pixel with zero opacity — audio still plays.
class HiddenYoutubePlayer extends ConsumerWidget {
  const HiddenYoutubePlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // In tests, skip rendering the YouTube player (requires WebView platform)
    if (!ref.watch(enableHiddenPlayerProvider)) {
      return const SizedBox.shrink();
    }

    final controller = ref.watch(youtubePlayerControllerProvider);
    // Eagerly initialise the service so it starts listening immediately
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
