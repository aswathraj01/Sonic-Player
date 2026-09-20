import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sonic_player/core/theme/app_theme.dart';
import 'package:sonic_player/presentation/widgets/mini_player.dart';
import 'package:sonic_player/services/playback/youtube_player_service.dart';
import 'package:sonic_player/services/playback/playback_provider.dart';

/// Shell wrapper that provides bottom navigation and the persistent mini-player.
/// Also hosts the hidden YouTube IFrame player so playback persists across screens.
class AppShell extends ConsumerWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/search')) return 1;
    if (location.startsWith('/library')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Wire up the YouTube player service ↔ PlaybackNotifier.
    // This ensures play/pause/seek/load commands reach the real YouTube player.
    final playerService = ref.watch(youtubePlayerServiceProvider);
    ref.read(playbackProvider.notifier).attachPlayerService(playerService);

    final currentIndex = _currentIndex(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          child,
          // Hidden 1x1px YouTube IFrame player — always in the widget tree
          const HiddenYoutubePlayer(),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mini player
          const MiniPlayer(),
          // Bottom navigation
          Container(
            decoration: BoxDecoration(
              color: AppColors.navBackground,
              border: Border(
                top: BorderSide(
                  color: AppColors.divider.withValues(alpha: 0.3),
                  width: 0.5,
                ),
              ),
            ),
            child: SafeArea(
              child: SizedBox(
                height: 60,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NavItem(
                      icon: Icons.home_rounded,
                      label: 'Home',
                      isActive: currentIndex == 0,
                      onTap: () => context.go('/home'),
                    ),
                    _NavItem(
                      icon: Icons.search_rounded,
                      label: 'Search',
                      isActive: currentIndex == 1,
                      onTap: () => context.go('/search'),
                    ),
                    _NavItem(
                      icon: Icons.library_music_rounded,
                      label: 'Library',
                      isActive: currentIndex == 2,
                      onTap: () => context.go('/library'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      selected: isActive,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 72,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isActive ? AppColors.navActive : AppColors.navInactive,
                  size: 22,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color:
                        isActive ? AppColors.navActive : AppColors.navInactive,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
