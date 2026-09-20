import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sonic_player/core/theme/app_theme.dart';
import 'package:sonic_player/core/constants/app_constants.dart';

/// Cached artwork widget with placeholder and error fallback.
class ArtworkWidget extends StatelessWidget {
  final String? url;
  final double size;
  final double borderRadius;
  final IconData fallbackIcon;
  final BoxFit fit;

  const ArtworkWidget({
    super.key,
    this.url,
    this.size = AppConstants.artworkMedium,
    this.borderRadius = AppConstants.borderRadiusMedium,
    this.fallbackIcon = Icons.music_note_rounded,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: size,
        height: size,
        child: url != null && url!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: url!,
                fit: fit,
                placeholder: (context, url) => _placeholder(),
                errorWidget: (context, url, error) => _fallback(),
              )
            : _fallback(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.card,
      child: Center(
        child: SizedBox(
          width: size * 0.3,
          height: size * 0.3,
          child: const CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      color: AppColors.card,
      child: Icon(
        fallbackIcon,
        color: AppColors.textTertiary,
        size: size * 0.4,
      ),
    );
  }
}
