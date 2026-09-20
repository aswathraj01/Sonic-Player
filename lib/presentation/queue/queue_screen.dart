import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sonic_player/core/theme/app_theme.dart';
import 'package:sonic_player/core/constants/app_constants.dart';
import 'package:sonic_player/services/playback/playback_provider.dart';
import 'package:sonic_player/presentation/widgets/song_tile.dart';
import 'package:sonic_player/presentation/widgets/state_views.dart';

class QueueScreen extends ConsumerWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playback = ref.watch(playbackProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('Queue', style: AppTextStyles.heading2),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        actions: [
          if (playback.queue.length > 1)
            TextButton(
              onPressed: () {
                ref.read(playbackProvider.notifier).clearQueue();
              },
              child: Text('Clear', style: AppTextStyles.seeAll),
            ),
        ],
      ),
      body: playback.queue.isEmpty
          ? const EmptyStateView(
              message: 'Queue is empty',
              subtitle: 'Add songs to start playing.',
              icon: Icons.queue_music_rounded,
            )
          : ListView(
              children: [
                // Now Playing
                if (playback.currentSong != null) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Text('Now Playing',
                        style: AppTextStyles.heading3),
                  ),
                  SongTile(
                    song: playback.currentSong!,
                    isPlaying: true,
                    onMoreTap: () {},
                  ),
                  const Divider(
                    color: AppColors.divider,
                    height: 24,
                    indent: 16,
                    endIndent: 16,
                  ),
                ],

                // Up Next
                if (_getUpNext(playback).isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Text('Up Next', style: AppTextStyles.heading3),
                  ),
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _getUpNext(playback).length,
                    onReorder: (oldIndex, newIndex) {
                      // Convert to absolute queue indices
                      final startIndex = playback.currentIndex + 1;
                      ref.read(playbackProvider.notifier).reorderQueue(
                            startIndex + oldIndex,
                            startIndex + newIndex,
                          );
                    },
                    proxyDecorator: (child, index, animation) {
                      return AnimatedBuilder(
                        animation: animation,
                        builder: (context, child) {
                          return Material(
                            color: AppColors.card.withValues(alpha: 0.9),
                            elevation: 4,
                            borderRadius: BorderRadius.circular(
                                AppConstants.borderRadiusMedium),
                            child: child,
                          );
                        },
                        child: child,
                      );
                    },
                    itemBuilder: (context, index) {
                      final queueIndex = playback.currentIndex + 1 + index;
                      final song = playback.queue[queueIndex];
                      return SongTile(
                        key: ValueKey('queue_${song.id}_$queueIndex'),
                        song: song,
                        onTap: () {
                          ref
                              .read(playbackProvider.notifier)
                              .playQueueItem(queueIndex);
                        },
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.close_rounded,
                                  color: AppColors.textTertiary, size: 20),
                              onPressed: () {
                                ref
                                    .read(playbackProvider.notifier)
                                    .removeFromQueue(queueIndex);
                              },
                              tooltip: 'Remove from queue',
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
                ],

                const SizedBox(height: 80),
              ],
            ),
    );
  }

  List<dynamic> _getUpNext(dynamic playback) {
    if (playback.currentIndex < 0 ||
        playback.currentIndex >= playback.queue.length - 1) {
      return [];
    }
    return playback.queue.sublist(playback.currentIndex + 1);
  }
}
