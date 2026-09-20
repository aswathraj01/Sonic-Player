import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sonic_player/core/theme/app_theme.dart';
import 'package:sonic_player/core/constants/app_constants.dart';
import 'package:sonic_player/services/storage/library_provider.dart';
import 'package:sonic_player/presentation/widgets/section_header.dart';
import 'package:sonic_player/presentation/widgets/artwork_widget.dart';


class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final likedSongs = ref.watch(likedSongsProvider);
    final playlists = ref.watch(playlistsProvider);


    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Your Library', style: AppTextStyles.heading1),
                    IconButton(
                      onPressed: () => _showCreatePlaylistDialog(context, ref),
                      icon: const Icon(Icons.add_rounded),
                      color: AppColors.textPrimary,
                      tooltip: 'Create playlist',
                    ),
                  ],
                ),
              ),
            ),

            // Top cards (Liked Songs + Playlists)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    // Liked Songs card
                    Expanded(
                      child: _LibraryTopCard(
                        icon: Icons.favorite_rounded,
                        iconColor: AppColors.heartActive,
                        title: 'Liked Songs',
                        subtitle: '${likedSongs.length} songs',
                        gradientColors: [
                          Colors.pink.shade800,
                          Colors.pink.shade900,
                        ],
                        onTap: () => _showLikedSongs(context, ref),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Playlists card
                    Expanded(
                      child: _LibraryTopCard(
                        icon: Icons.library_music_rounded,
                        iconColor: AppColors.primary,
                        title: 'Playlists',
                        subtitle: '${playlists.length} playlists',
                        gradientColors: [
                          AppColors.primary.withValues(alpha: 0.6),
                          AppColors.card,
                        ],
                        onTap: () {},
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Menu items
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _LibraryMenuItem(
                    icon: Icons.history_rounded,
                    title: 'Recently Played',
                    onTap: () => _showRecentlyPlayed(context, ref),
                  ),
                  _LibraryMenuItem(
                    icon: Icons.video_library_rounded,
                    title: 'Your Videos',
                    onTap: () {},
                  ),
                  _LibraryMenuItem(
                    icon: Icons.download_rounded,
                    title: 'Downloads',
                    onTap: () {},
                  ),
                  _LibraryMenuItem(
                    icon: Icons.person_rounded,
                    title: 'Artists',
                    onTap: () {},
                  ),
                  _LibraryMenuItem(
                    icon: Icons.album_rounded,
                    title: 'Albums',
                    onTap: () {},
                  ),
                  _LibraryMenuItem(
                    icon: Icons.podcasts_rounded,
                    title: 'Podcasts',
                    onTap: () {},
                  ),
                ],
              ),
            ),

            // Your Playlists
            if (playlists.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'Your Playlists',
                  onSeeAll: () {},
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final playlist = playlists[index];
                    return ListTile(
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(8),
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withValues(alpha: 0.5),
                              AppColors.card,
                            ],
                          ),
                        ),
                        child: playlist.displayThumbnail != null
                            ? ArtworkWidget(
                                url: playlist.displayThumbnail,
                                size: 48,
                                borderRadius: 8,
                              )
                            : const Icon(Icons.music_note_rounded,
                                color: AppColors.textTertiary),
                      ),
                      title: Text(playlist.name,
                          style: AppTextStyles.bodyMedium),
                      subtitle: Text('${playlist.songCount} songs',
                          style: AppTextStyles.bodySmall),
                      trailing: const Icon(Icons.chevron_right_rounded,
                          color: AppColors.textTertiary),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      onTap: () =>
                          context.push('/playlist/${playlist.id}'),
                      onLongPress: () =>
                          _showPlaylistOptions(context, ref, playlist.id, playlist.name),
                    );
                  },
                  childCount: playlists.length,
                ),
              ),
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Create Playlist', style: AppTextStyles.heading3),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: AppTextStyles.bodyMedium,
          decoration: const InputDecoration(
            hintText: 'Playlist name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: AppTextStyles.button
                    .copyWith(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                ref.read(playlistsProvider.notifier).createPlaylist(name);
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Create', style: AppTextStyles.button),
          ),
        ],
      ),
    );
  }

  void _showPlaylistOptions(
      BuildContext context, WidgetRef ref, String id, String name) {
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
            ListTile(
              leading: const Icon(Icons.edit_rounded,
                  color: AppColors.textSecondary),
              title: Text('Rename', style: AppTextStyles.bodyMedium),
              onTap: () {
                Navigator.pop(ctx);
                _showRenameDialog(context, ref, id, name);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.error),
              title: Text('Delete',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.error)),
              onTap: () {
                ref.read(playlistsProvider.notifier).deletePlaylist(id);
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(
      BuildContext context, WidgetRef ref, String id, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Rename Playlist', style: AppTextStyles.heading3),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: AppTextStyles.bodyMedium,
          decoration: const InputDecoration(hintText: 'New name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: AppTextStyles.button
                    .copyWith(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                ref
                    .read(playlistsProvider.notifier)
                    .renamePlaylist(id, name);
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Rename', style: AppTextStyles.button),
          ),
        ],
      ),
    );
  }

  void _showLikedSongs(BuildContext context, WidgetRef ref) {
    // TODO: Navigate to full liked songs list screen
  }

  void _showRecentlyPlayed(BuildContext context, WidgetRef ref) {
    // TODO: Navigate to full recently played screen
  }
}

class _LibraryTopCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final List<Color> gradientColors;
  final VoidCallback? onTap;

  const _LibraryTopCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.gradientColors,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 32),
            const SizedBox(height: 12),
            Text(title, style: AppTextStyles.labelLarge),
            const SizedBox(height: 2),
            Text(subtitle, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}

class _LibraryMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  const _LibraryMenuItem({
    required this.icon,
    required this.title,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary, size: 24),
      title: Text(title, style: AppTextStyles.bodyMedium),
      trailing: const Icon(Icons.chevron_right_rounded,
          color: AppColors.textTertiary, size: 22),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      onTap: onTap,
    );
  }
}
