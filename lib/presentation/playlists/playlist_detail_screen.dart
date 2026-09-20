import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sonic_player/core/theme/app_theme.dart';
import 'package:sonic_player/core/constants/app_constants.dart';
import 'package:sonic_player/domain/entities/playlist.dart';
import 'package:sonic_player/services/playback/playback_provider.dart';
import 'package:sonic_player/services/storage/library_provider.dart';
import 'package:sonic_player/presentation/widgets/song_tile.dart';
import 'package:sonic_player/presentation/widgets/artwork_widget.dart';
import 'package:sonic_player/presentation/widgets/state_views.dart';

class PlaylistDetailScreen extends ConsumerWidget {
  final String playlistId;

  const PlaylistDetailScreen({super.key, required this.playlistId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(playlistsProvider);
    final playback = ref.watch(playbackProvider);
    final playlist = playlists.where((p) => p.id == playlistId).firstOrNull;

    if (playlist == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          leading: const BackButton(),
        ),
        body: const ErrorView(message: 'Playlist not found'),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App bar
          SliverAppBar(
            backgroundColor: AppColors.background,
            expandedHeight: 280,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.4),
                      AppColors.background,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      // Artwork
                      ArtworkWidget(
                        url: playlist.displayThumbnail,
                        size: 140,
                        borderRadius: AppConstants.borderRadiusLarge,
                        fallbackIcon: Icons.playlist_play_rounded,
                      ),
                      const SizedBox(height: 16),
                      Text(playlist.name, style: AppTextStyles.heading2),
                      const SizedBox(height: 4),
                      Text(
                        '${playlist.songCount} songs',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                onPressed: () => _showPlaylistMenu(context, ref, playlist),
                icon: const Icon(Icons.more_vert_rounded),
              ),
            ],
          ),

          // Action buttons
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Play all
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: playlist.songs.isNotEmpty
                          ? () {
                              ref
                                  .read(playbackProvider.notifier)
                                  .playSong(playlist.songs.first,
                                      queue: playlist.songs);
                            }
                          : null,
                      icon: const Icon(Icons.play_arrow_rounded, size: 22),
                      label: const Text('Play All'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              AppConstants.borderRadiusRound),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Shuffle
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: playlist.songs.isNotEmpty
                          ? () {
                              final shuffled = [...playlist.songs]..shuffle();
                              ref.read(playbackProvider.notifier).playSong(
                                    shuffled.first,
                                    queue: shuffled,
                                  );
                              ref
                                  .read(playbackProvider.notifier)
                                  .toggleShuffle();
                            }
                          : null,
                      icon: const Icon(Icons.shuffle_rounded, size: 20),
                      label: const Text('Shuffle'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.divider),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              AppConstants.borderRadiusRound),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Songs
          if (playlist.songs.isEmpty)
            const SliverToBoxAdapter(
              child: EmptyStateView(
                message: 'No songs yet',
                subtitle: 'Add songs from search or your library.',
                icon: Icons.music_note_rounded,
              ),
            )
          else
            SliverReorderableList(
              itemCount: playlist.songs.length,
              onReorder: (oldIndex, newIndex) {
                ref
                    .read(playlistsProvider.notifier)
                    .reorderPlaylistSongs(playlistId, oldIndex, newIndex);
              },
              itemBuilder: (context, index) {
                final song = playlist.songs[index];
                return SongTile(
                  key: ValueKey('playlist_${song.id}_$index'),
                  song: song,
                  isPlaying: playback.currentSong?.id == song.id,
                  onTap: () {
                    ref.read(playbackProvider.notifier).playSong(
                          song,
                          queue: playlist.songs,
                        );
                  },
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: AppColors.textTertiary, size: 18),
                        onPressed: () {
                          ref
                              .read(playlistsProvider.notifier)
                              .removeSongFromPlaylist(playlistId, song.id);
                        },
                        tooltip: 'Remove',
                      ),
                      ReorderableDragStartListener(
                        index: index,
                        child: const Icon(Icons.drag_handle_rounded,
                            color: AppColors.textTertiary, size: 20),
                      ),
                    ],
                  ),
                );
              },
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  void _showPlaylistMenu(
      BuildContext context, WidgetRef ref, Playlist playlist) {
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
                _showRenameDialog(context, ref, playlist);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.error),
              title: Text('Delete Playlist',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.error)),
              onTap: () {
                ref
                    .read(playlistsProvider.notifier)
                    .deletePlaylist(playlistId);
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(
      BuildContext context, WidgetRef ref, Playlist playlist) {
    final controller = TextEditingController(text: playlist.name);
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
                    .renamePlaylist(playlistId, name);
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: Text('Rename', style: AppTextStyles.button),
          ),
        ],
      ),
    );
  }
}
