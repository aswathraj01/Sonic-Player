import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sonic_player/core/theme/app_theme.dart';
import 'package:sonic_player/core/constants/app_constants.dart';
import 'package:sonic_player/domain/entities/playback_state.dart';
import 'package:sonic_player/services/playback/playback_provider.dart';
import 'package:sonic_player/services/storage/library_provider.dart';
import 'package:sonic_player/presentation/widgets/artwork_widget.dart';

class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playback = ref.watch(playbackProvider);
    final song = playback.currentSong;
    final likedSongs = ref.watch(likedSongsProvider);

    if (song == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.music_off_rounded,
                  color: AppColors.textTertiary, size: 64),
              const SizedBox(height: 16),
              Text('No song selected',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
    }

    final isLiked = likedSongs.any((s) => s.id == song.id);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.playerGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      color: AppColors.textPrimary,
                      iconSize: 30,
                      tooltip: 'Close player',
                    ),
                    Column(
                      children: [
                        Text('Now Playing',
                            style: AppTextStyles.labelMedium
                                .copyWith(color: AppColors.textSecondary)),
                        Text('PLAYING FROM SEARCH',
                            style: AppTextStyles.caption),
                      ],
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.more_vert_rounded),
                      color: AppColors.textPrimary,
                      tooltip: 'More options',
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 1),

              // Artwork
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                          AppConstants.borderRadiusXLarge),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 40,
                          spreadRadius: 5,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ArtworkWidget(
                      url: song.highResThumbnailUrl ?? song.thumbnailUrl,
                      size: double.infinity,
                      borderRadius: AppConstants.borderRadiusXLarge,
                    ),
                  ),
                ),
              ),

              const Spacer(flex: 1),

              // Song info + Like
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.title,
                            style: AppTextStyles.playerTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            song.artist,
                            style: AppTextStyles.playerArtist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        ref
                            .read(likedSongsProvider.notifier)
                            .toggleLike(song);
                      },
                      icon: Icon(
                        isLiked
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: isLiked
                            ? AppColors.heartActive
                            : AppColors.textSecondary,
                      ),
                      iconSize: 28,
                      tooltip: isLiked ? 'Unlike' : 'Like',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Progress bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6),
                        overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 14),
                      ),
                      child: Slider(
                        value: playback.progress,
                        onChanged: (value) {
                          final position = Duration(
                            milliseconds:
                                (value * playback.duration.inMilliseconds)
                                    .toInt(),
                          );
                          ref
                              .read(playbackProvider.notifier)
                              .seekTo(position);
                        },
                        activeColor: AppColors.primary,
                        inactiveColor: AppColors.progressBackground,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(playback.position),
                            style: AppTextStyles.playerTime,
                          ),
                          Text(
                            _formatDuration(playback.duration),
                            style: AppTextStyles.playerTime,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Transport controls
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Shuffle
                    IconButton(
                      onPressed: () {
                        ref
                            .read(playbackProvider.notifier)
                            .toggleShuffle();
                      },
                      icon: Icon(
                        Icons.shuffle_rounded,
                        color: playback.shuffleEnabled
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                      iconSize: 24,
                      tooltip: 'Shuffle',
                    ),
                    // Previous
                    IconButton(
                      onPressed: () {
                        ref.read(playbackProvider.notifier).skipPrevious();
                      },
                      icon: const Icon(Icons.skip_previous_rounded),
                      color: AppColors.textPrimary,
                      iconSize: 36,
                      tooltip: 'Previous',
                    ),
                    // Play/Pause
                    GestureDetector(
                      onTap: () {
                        ref
                            .read(playbackProvider.notifier)
                            .togglePlayPause();
                      },
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.textPrimary,
                        ),
                        child: Icon(
                          playback.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: AppColors.background,
                          size: 36,
                        ),
                      ),
                    ),
                    // Next
                    IconButton(
                      onPressed: () {
                        ref.read(playbackProvider.notifier).skipNext();
                      },
                      icon: const Icon(Icons.skip_next_rounded),
                      color: AppColors.textPrimary,
                      iconSize: 36,
                      tooltip: 'Next',
                    ),
                    // Repeat
                    IconButton(
                      onPressed: () {
                        ref
                            .read(playbackProvider.notifier)
                            .cycleRepeatMode();
                      },
                      icon: Icon(
                        playback.repeatMode == RepeatMode.one
                            ? Icons.repeat_one_rounded
                            : Icons.repeat_rounded,
                        color: playback.repeatMode != RepeatMode.off
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                      iconSize: 24,
                      tooltip: 'Repeat',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Bottom actions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Quality
                    IconButton(
                      onPressed: () => _showQualityPicker(context, ref),
                      icon: const Icon(Icons.high_quality_rounded),
                      color: AppColors.textSecondary,
                      tooltip: 'Audio quality',
                    ),
                    // Lyrics
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.lyrics_rounded,
                          color: AppColors.textSecondary, size: 20),
                      label: Text('Lyrics',
                          style: AppTextStyles.labelMedium),
                    ),
                    // Queue
                    IconButton(
                      onPressed: () => context.push('/queue'),
                      icon: const Icon(Icons.queue_music_rounded),
                      color: AppColors.textSecondary,
                      tooltip: 'Queue',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void _showQualityPicker(BuildContext context, WidgetRef ref) {
    final current = ref.read(playbackProvider).quality;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('Audio Quality', style: AppTextStyles.heading3),
            ),
            ...AudioQuality.values.map((q) => ListTile(
                  leading: Icon(
                    current == q
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    color:
                        current == q ? AppColors.primary : AppColors.textTertiary,
                  ),
                  title: Text(q.label, style: AppTextStyles.bodyMedium),
                  onTap: () {
                    ref.read(playbackProvider.notifier).setQuality(q);
                    Navigator.pop(ctx);
                  },
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
