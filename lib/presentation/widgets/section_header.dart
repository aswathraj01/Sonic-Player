import 'package:flutter/material.dart';
import 'package:sonic_player/core/theme/app_theme.dart';
import 'package:sonic_player/core/constants/app_constants.dart';

/// Section header with title and optional "See all" action.
class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  final EdgeInsetsGeometry padding;

  const SectionHeader({
    super.key,
    required this.title,
    this.onSeeAll,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppConstants.paddingMedium,
    ),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTextStyles.sectionTitle),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(48, 36),
              ),
              child: Text('See all', style: AppTextStyles.seeAll),
            ),
        ],
      ),
    );
  }
}
