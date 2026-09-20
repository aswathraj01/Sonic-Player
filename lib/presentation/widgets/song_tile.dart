import 'package:flutter/material.dart';
import 'package:sonic_player/core/theme/app_theme.dart';
import 'package:sonic_player/core/constants/app_constants.dart';
import 'package:sonic_player/domain/entities/song.dart';
import 'package:sonic_player/presentation/widgets/artwork_widget.dart';

/// A list tile for displaying a song, matching the reference design.
class SongTile extends StatelessWidget {
  final Song song;
  final VoidCallback? onTap;
  final VoidCallback? onMoreTap;
  final bool isPlaying;
  final bool showDuration;
  final Widget? trailing;

  const SongTile({
    super.key,
    required this.song,
    this.onTap,
    this.onMoreTap,
    this.isPlaying = false,
    this.showDuration = true,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingMedium,
            vertical: 10,
          ),
          child: Row(
            children: [
              // Artwork
              ArtworkWidget(
                url: song.thumbnailUrl,
                size: AppConstants.artworkSmall,
                borderRadius: AppConstants.borderRadiusSmall,
              ),
              const SizedBox(width: 12),
              // Title + Artist
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      song.title,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isPlaying
                            ? AppColors.primary
                            : AppColors.textPrimary,
                        fontWeight:
                            isPlaying ? FontWeight.w600 : FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      showDuration && song.duration.inSeconds > 0
                          ? '${song.artist} • ${song.formattedDuration}'
                          : song.artist,
                      style: AppTextStyles.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Play indicator
              if (isPlaying) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.equalizer_rounded,
                  color: AppColors.primary,
                  size: AppConstants.iconSizeSmall,
                  semanticLabel: 'Now playing',
                ),
              ],
              // Trailing widget or more button
              if (trailing != null) ...[
                const SizedBox(width: 4),
                trailing!,
              ] else if (onMoreTap != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  onPressed: onMoreTap,
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: AppColors.textTertiary,
                    size: AppConstants.iconSizeSmall,
                  ),
                  splashRadius: 20,
                  tooltip: 'More options',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
