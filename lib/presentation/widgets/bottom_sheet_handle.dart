import 'package:flutter/material.dart';
import 'package:sonic_player/core/theme/app_theme.dart';

/// Drag handle decoration displayed at the top of every bottom sheet.
///
/// Consolidates the repeated `Container(width:40, height:4)` pattern.
class BottomSheetHandle extends StatelessWidget {
  const BottomSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Sheet handle',
      excludeSemantics: true,
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.divider,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
