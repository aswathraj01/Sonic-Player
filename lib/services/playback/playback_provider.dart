import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sonic_player/domain/entities/playback_state.dart';
import 'package:sonic_player/domain/entities/song.dart';
import 'package:sonic_player/services/playback/youtube_player_service.dart';

/// Central playback state provider.
final playbackProvider =
    StateNotifierProvider<PlaybackNotifier, PlaybackState>((ref) {
  return PlaybackNotifier();
});

/// Manages all playback state transitions.
///
/// When a [YouTubePlayerService] is attached via [attachPlayerService],
/// commands are forwarded to the real YouTube player. Otherwise, state
/// transitions happen locally (useful for tests and initial UI development).
class PlaybackNotifier extends StateNotifier<PlaybackState> {
  PlaybackNotifier() : super(const PlaybackState());

  List<int>? _shuffledIndices;
  YouTubePlayerService? _playerService;

  /// Attach the YouTube player service for real playback.
  void attachPlayerService(YouTubePlayerService service) {
    _playerService = service;
  }

  /// Play a song, optionally replacing the entire queue.
  void playSong(Song song, {List<Song>? queue}) {
    final newQueue = queue ?? [song];
    final index = queue != null ? newQueue.indexOf(song) : 0;
    state = state.copyWith(
      currentSong: song,
      queue: newQueue,
      currentIndex: index < 0 ? 0 : index,
      status: PlayStatus.loading,
      position: Duration.zero,
      duration: song.duration,
      errorMessage: null,
    );
    _regenerateShuffleIfNeeded();

    // Forward to YouTube player
    _playerService?.loadVideo(song.youtubeId);
  }

  /// Resume or start playing.
  void play() {
    if (state.currentSong != null) {
      state = state.copyWith(status: PlayStatus.playing);
      _playerService?.play();
    }
  }

  /// Pause playback.
  void pause() {
    state = state.copyWith(status: PlayStatus.paused);
    _playerService?.pause();
  }

  /// Toggle play/pause.
  void togglePlayPause() {
    if (state.isPlaying) {
      pause();
    } else {
      play();
    }
  }

  /// Seek to position.
  void seekTo(Duration position) {
    state = state.copyWith(position: position);
    _playerService?.seekTo(position);
  }

  /// Update position (called periodically by the player service).
  void updatePosition(Duration position) {
    state = state.copyWith(position: position);
  }

  /// Update duration (when media is loaded).
  void updateDuration(Duration duration) {
    state = state.copyWith(duration: duration);
  }

  /// Update buffered position.
  void updateBufferedPosition(Duration position) {
    state = state.copyWith(bufferedPosition: position);
  }

  /// Set status (loading, buffering, playing, etc.)
  void setStatus(PlayStatus status) {
    state = state.copyWith(status: status);
  }

  /// Set error state.
  void setError(String message) {
    state = state.copyWith(
      status: PlayStatus.error,
      errorMessage: message,
    );
  }

  /// Skip to next song.
  void skipNext() {
    if (state.queue.isEmpty) return;

    int nextIndex;
    if (state.shuffleEnabled && _shuffledIndices != null) {
      final currentShufflePos = _shuffledIndices!.indexOf(state.currentIndex);
      if (currentShufflePos < _shuffledIndices!.length - 1) {
        nextIndex = _shuffledIndices![currentShufflePos + 1];
      } else if (state.repeatMode == RepeatMode.all) {
        _regenerateShuffleIfNeeded();
        nextIndex = _shuffledIndices!.first;
      } else {
        return;
      }
    } else {
      if (state.currentIndex < state.queue.length - 1) {
        nextIndex = state.currentIndex + 1;
      } else if (state.repeatMode == RepeatMode.all) {
        nextIndex = 0;
      } else {
        state = state.copyWith(status: PlayStatus.completed);
        return;
      }
    }

    final nextSong = state.queue[nextIndex];
    state = state.copyWith(
      currentSong: nextSong,
      currentIndex: nextIndex,
      status: PlayStatus.loading,
      position: Duration.zero,
      duration: nextSong.duration,
      errorMessage: null,
    );

    // Forward to YouTube player
    _playerService?.loadVideo(nextSong.youtubeId);
  }

  /// Skip to previous song. If past 3s, restart current song.
  void skipPrevious() {
    if (state.position.inSeconds > 3) {
      seekTo(Duration.zero);
      return;
    }
    if (state.queue.isEmpty) return;

    int prevIndex;
    if (state.shuffleEnabled && _shuffledIndices != null) {
      final currentShufflePos = _shuffledIndices!.indexOf(state.currentIndex);
      if (currentShufflePos > 0) {
        prevIndex = _shuffledIndices![currentShufflePos - 1];
      } else if (state.repeatMode == RepeatMode.all) {
        prevIndex = _shuffledIndices!.last;
      } else {
        seekTo(Duration.zero);
        return;
      }
    } else {
      if (state.currentIndex > 0) {
        prevIndex = state.currentIndex - 1;
      } else if (state.repeatMode == RepeatMode.all) {
        prevIndex = state.queue.length - 1;
      } else {
        seekTo(Duration.zero);
        return;
      }
    }

    final prevSong = state.queue[prevIndex];
    state = state.copyWith(
      currentSong: prevSong,
      currentIndex: prevIndex,
      status: PlayStatus.loading,
      position: Duration.zero,
      duration: prevSong.duration,
      errorMessage: null,
    );

    // Forward to YouTube player
    _playerService?.loadVideo(prevSong.youtubeId);
  }

  /// Toggle shuffle mode.
  void toggleShuffle() {
    final newShuffle = !state.shuffleEnabled;
    state = state.copyWith(shuffleEnabled: newShuffle);
    if (newShuffle) {
      _regenerateShuffleIfNeeded();
    } else {
      _shuffledIndices = null;
    }
  }

  /// Cycle repeat mode: off → all → one → off.
  void cycleRepeatMode() {
    final nextMode = switch (state.repeatMode) {
      RepeatMode.off => RepeatMode.all,
      RepeatMode.all => RepeatMode.one,
      RepeatMode.one => RepeatMode.off,
    };
    state = state.copyWith(repeatMode: nextMode);
  }

  /// Set audio quality.
  void setQuality(AudioQuality quality) {
    state = state.copyWith(quality: quality);
  }

  /// Add a song to the end of the queue.
  void addToQueue(Song song) {
    final newQueue = [...state.queue, song];
    state = state.copyWith(queue: newQueue);
    _regenerateShuffleIfNeeded();
  }

  /// Remove a song from the queue by index.
  void removeFromQueue(int index) {
    if (index < 0 || index >= state.queue.length) return;
    final newQueue = [...state.queue]..removeAt(index);
    var newIndex = state.currentIndex;
    if (index < state.currentIndex) {
      newIndex--;
    } else if (index == state.currentIndex) {
      // Removing current song - play next
      if (newQueue.isNotEmpty) {
        newIndex = newIndex.clamp(0, newQueue.length - 1);
        final nextSong = newQueue[newIndex];
        state = state.copyWith(
          queue: newQueue,
          currentIndex: newIndex,
          currentSong: nextSong,
          status: PlayStatus.loading,
          position: Duration.zero,
        );
        _playerService?.loadVideo(nextSong.youtubeId);
        return;
      } else {
        state = const PlaybackState();
        return;
      }
    }
    state = state.copyWith(queue: newQueue, currentIndex: newIndex);
    _regenerateShuffleIfNeeded();
  }

  /// Reorder queue item.
  void reorderQueue(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;
    final newQueue = [...state.queue];
    final item = newQueue.removeAt(oldIndex);
    if (newIndex > oldIndex) newIndex--;
    newQueue.insert(newIndex, item);

    // Adjust current index
    var newCurrentIndex = state.currentIndex;
    if (oldIndex == state.currentIndex) {
      newCurrentIndex = newIndex;
    } else {
      if (oldIndex < state.currentIndex && newIndex >= state.currentIndex) {
        newCurrentIndex--;
      } else if (oldIndex > state.currentIndex &&
          newIndex <= state.currentIndex) {
        newCurrentIndex++;
      }
    }

    state = state.copyWith(queue: newQueue, currentIndex: newCurrentIndex);
    _regenerateShuffleIfNeeded();
  }

  /// Clear the entire queue except current.
  void clearQueue() {
    if (state.currentSong == null) {
      state = const PlaybackState();
      return;
    }
    state = state.copyWith(
      queue: [state.currentSong!],
      currentIndex: 0,
    );
    _regenerateShuffleIfNeeded();
  }

  /// Play a specific song in the queue by index.
  void playQueueItem(int index) {
    if (index < 0 || index >= state.queue.length) return;
    final song = state.queue[index];
    state = state.copyWith(
      currentSong: song,
      currentIndex: index,
      status: PlayStatus.loading,
      position: Duration.zero,
      duration: song.duration,
      errorMessage: null,
    );
    _playerService?.loadVideo(song.youtubeId);
  }

  /// Called when current song finishes.
  void onSongCompleted() {
    if (state.repeatMode == RepeatMode.one) {
      seekTo(Duration.zero);
      play();
    } else {
      skipNext();
    }
  }

  /// Stop playback and clear state.
  void stop() {
    _playerService?.pause();
    state = const PlaybackState();
    _shuffledIndices = null;
  }

  void _regenerateShuffleIfNeeded() {
    if (!state.shuffleEnabled || state.queue.length <= 1) {
      _shuffledIndices = null;
      return;
    }
    final indices = List.generate(state.queue.length, (i) => i);
    // Keep current song first
    indices.remove(state.currentIndex);
    indices.shuffle(Random());
    _shuffledIndices = [state.currentIndex, ...indices];
  }
}
