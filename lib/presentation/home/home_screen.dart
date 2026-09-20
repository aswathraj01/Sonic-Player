import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sonic_player/core/theme/app_theme.dart';
import 'package:sonic_player/core/constants/app_constants.dart';
import 'package:sonic_player/domain/entities/song.dart';

import 'package:sonic_player/services/playback/playback_provider.dart';
import 'package:sonic_player/services/storage/library_provider.dart';
import 'package:sonic_player/presentation/widgets/section_header.dart';
import 'package:sonic_player/presentation/widgets/song_tile.dart';
import 'package:sonic_player/presentation/widgets/album_card.dart';
import 'package:sonic_player/presentation/widgets/state_views.dart';

import 'package:sonic_player/services/youtube/trending_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    if (hour < 21) return 'Good evening';
    return 'Good night';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentlyPlayed = ref.watch(recentlyPlayedProvider);
    final likedSongs = ref.watch(likedSongsProvider);
    final playback = ref.watch(playbackProvider);
    final trendingAsync = ref.watch(trendingProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_getGreeting()},',
                          style: AppTextStyles.greeting,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Music always sounds better here 🎵',
                          style: AppTextStyles.greetingSub,
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.notifications_outlined),
                          color: AppColors.textPrimary,
                          tooltip: 'Notifications',
                        ),
                        IconButton(
                          onPressed: () => context.push('/settings'),
                          icon: const Icon(Icons.settings_outlined),
                          color: AppColors.textPrimary,
                          tooltip: 'Settings',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Search bar
            SliverToBoxAdapter(
              child: GestureDetector(
                onTap: () => context.go('/search'),
                child: Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius:
                        BorderRadius.circular(AppConstants.borderRadiusMedium),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded,
                          color: AppColors.textTertiary, size: 22),
                      const SizedBox(width: 12),
                      Text(
                        'Search songs, artists, or playlists...',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Quick Picks
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'Quick picks', onSeeAll: null),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 155,
                    child: trendingAsync.when(
                      data: (songs) {
                        return ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: songs.length,
                          separatorBuilder: (context, _) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final song = songs[index];
                            return SizedBox(
                              width: 140, // Match typical card width
                              child: AlbumCard(
                                imageUrl: song.highResThumbnailUrl ?? song.thumbnailUrl,
                                title: song.title,
                                subtitle: song.artist,
                                onTap: () {
                                  ref.read(playbackProvider.notifier).playSong(
                                        song,
                                        queue: songs,
                                      );
                                  ref
                                      .read(recentlyPlayedProvider.notifier)
                                      .addSong(song);
                                },
                              ),
                            );
                          },
                        );
                      },
                      loading: () => const Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                      error: (err, stack) => Center(
                        child: Text(
                          'Could not load trending music',
                          style: AppTextStyles.caption.copyWith(color: AppColors.error),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Recently Played
            if (recentlyPlayed.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'Recently played',
                  onSeeAll: () {},
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final song = recentlyPlayed[index];
                    return SongTile(
                      song: song,
                      isPlaying: playback.currentSong?.id == song.id,
                      onTap: () {
                        ref.read(playbackProvider.notifier).playSong(
                              song,
                              queue: recentlyPlayed,
                            );
                        ref
                            .read(recentlyPlayedProvider.notifier)
                            .addSong(song);
                      },
                      onMoreTap: () => _showSongOptions(context, ref, song),
                    );
                  },
                  childCount: recentlyPlayed.length.clamp(0, 5),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],

            // Liked Songs Preview
            if (likedSongs.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'Liked songs',
                  onSeeAll: () => context.go('/library'),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final song = likedSongs[index];
                    return SongTile(
                      song: song,
                      isPlaying: playback.currentSong?.id == song.id,
                      onTap: () {
                        ref.read(playbackProvider.notifier).playSong(
                              song,
                              queue: likedSongs,
                            );
                        ref
                            .read(recentlyPlayedProvider.notifier)
                            .addSong(song);
                      },
                      onMoreTap: () => _showSongOptions(context, ref, song),
                    );
                  },
                  childCount: likedSongs.length.clamp(0, 5),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],

            // Empty state when nothing exists yet
            if (recentlyPlayed.isEmpty && likedSongs.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: EmptyStateView(
                    message: 'Start exploring music',
                    subtitle:
                        'Search for your favorite songs and artists to get started.',
                    icon: Icons.music_note_rounded,
                  ),
                ),
              ),

            // Bottom padding for mini player
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
          ],
        ),
      ),
    );
  }

  void _showSongOptions(BuildContext context, WidgetRef ref, Song song) {
    final likedNotifier = ref.read(likedSongsProvider.notifier);
    final isLiked = likedNotifier.isLiked(song.id);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
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
              leading: Icon(
                isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: isLiked ? AppColors.heartActive : AppColors.textSecondary,
              ),
              title: Text(
                isLiked ? 'Remove from Liked Songs' : 'Add to Liked Songs',
                style: AppTextStyles.bodyMedium,
              ),
              onTap: () {
                likedNotifier.toggleLike(song);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.queue_music_rounded,
                  color: AppColors.textSecondary),
              title: Text('Add to Queue', style: AppTextStyles.bodyMedium),
              onTap: () {
                ref.read(playbackProvider.notifier).addToQueue(song);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Added to queue'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.playlist_add_rounded,
                  color: AppColors.textSecondary),
              title:
                  Text('Add to Playlist', style: AppTextStyles.bodyMedium),
              onTap: () {
                Navigator.pop(context);
                _showPlaylistPicker(context, ref, song);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showPlaylistPicker(BuildContext context, WidgetRef ref, Song song) {
    final playlists = ref.read(playlistsProvider);
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('Add to playlist',
                  style: AppTextStyles.heading3),
            ),
            if (playlists.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text('No playlists yet',
                    style: AppTextStyles.bodySmall),
              ),
            ...playlists.map((p) => ListTile(
                  leading: const Icon(Icons.playlist_play_rounded,
                      color: AppColors.primary),
                  title:
                      Text(p.name, style: AppTextStyles.bodyMedium),
                  subtitle: Text('${p.songCount} songs',
                      style: AppTextStyles.caption),
                  onTap: () {
                    ref
                        .read(playlistsProvider.notifier)
                        .addSongToPlaylist(p.id, song);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Added to ${p.name}')),
                    );
                  },
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
