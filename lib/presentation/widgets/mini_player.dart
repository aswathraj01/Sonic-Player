import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sonic_player/core/theme/app_theme.dart';
import 'package:sonic_player/core/constants/app_constants.dart';
import 'package:sonic_player/services/playback/playback_provider.dart';
import 'package:sonic_player/presentation/widgets/artwork_widget.dart';

/// Persistent mini-player displayed above the bottom navigation bar.
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playback = ref.watch(playbackProvider);

    if (!playback.hasSong) return const SizedBox.shrink();

    final song = playback.currentSong!;

    return GestureDetector(
      onTap: () => context.push('/player'),
      child: Container(
        height: AppConstants.miniPlayerHeight,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.miniPlayerBg,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress bar
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppConstants.borderRadiusMedium),
              ),
              child: LinearProgressIndicator(
                value: playback.progress,
                backgroundColor: AppColors.progressBackground,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 2,
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    // Artwork
                    ArtworkWidget(
                      url: song.thumbnailUrl,
                      size: AppConstants.artworkTiny,
                      borderRadius: AppConstants.borderRadiusSmall,
                    ),
                    const SizedBox(width: 12),
                    // Song info
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.title,
                            style: AppTextStyles.miniPlayerTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            song.artist,
                            style: AppTextStyles.miniPlayerArtist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Play/Pause
                    _MiniPlayerButton(
                      icon: playback.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      onTap: () {
                        ref.read(playbackProvider.notifier).togglePlayPause();
                      },
                      tooltip: playback.isPlaying ? 'Pause' : 'Play',
                      size: 36,
                    ),
                    const SizedBox(width: 4),
                    // Next
                    _MiniPlayerButton(
                      icon: Icons.skip_next_rounded,
                      onTap: playback.canPlayNext
                          ? () {
                              ref.read(playbackProvider.notifier).skipNext();
                            }
                          : null,
                      tooltip: 'Next',
                      size: 32,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniPlayerButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String tooltip;
  final double size;

  const _MiniPlayerButton({
    required this.icon,
    this.onTap,
    required this.tooltip,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: tooltip,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(
            icon,
            color: onTap != null
                ? AppColors.textPrimary
                : AppColors.textDisabled,
            size: size,
          ),
        ),
      ),
    );
  }
}
