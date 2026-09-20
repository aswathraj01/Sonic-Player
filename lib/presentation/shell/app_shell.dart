import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sonic_player/core/theme/app_theme.dart';
import 'package:sonic_player/presentation/widgets/mini_player.dart';
import 'package:sonic_player/services/playback/youtube_player_service.dart';
import 'package:sonic_player/services/playback/playback_provider.dart';

/// Shell wrapper that provides bottom navigation and the persistent mini-player.
/// Also hosts the hidden YouTube IFrame player so playback persists across screens.
class AppShell extends ConsumerStatefulWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  @override
  void initState() {
    super.initState();
    // Attach the player service once on init so the notifier can forward
    // commands to the real YouTube player from the very first interaction.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final service = ref.read(youtubePlayerServiceProvider);
        ref.read(playbackProvider.notifier).attachPlayerService(service);
      }
    });
  }

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/search')) return 1;
    if (location.startsWith('/library')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          widget.child,
          // Hidden 1×1 px YouTube IFrame player — always in the widget tree
          const HiddenYoutubePlayer(),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mini player (visible only when a song is loaded)
          const MiniPlayer(),
          // Bottom navigation bar
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
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color:
                        isActive ? AppColors.navActive : AppColors.navInactive,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 2),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight:
                        isActive ? FontWeight.w600 : FontWeight.w400,
                    color:
                        isActive ? AppColors.navActive : AppColors.navInactive,
                    height: 1.0,
                  ),
                  child: Text(label),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
