import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sonic_player/core/theme/app_theme.dart';
import 'package:sonic_player/core/constants/app_constants.dart';
import 'package:sonic_player/domain/entities/search_result.dart';
import 'package:sonic_player/domain/entities/song.dart';
import 'package:sonic_player/domain/entities/playback_state.dart';
import 'package:sonic_player/services/youtube/search_provider.dart';
import 'package:sonic_player/services/playback/playback_provider.dart';
import 'package:sonic_player/services/storage/library_provider.dart';
import 'package:sonic_player/presentation/widgets/song_tile.dart';
import 'package:sonic_player/presentation/widgets/artwork_widget.dart';
import 'package:sonic_player/presentation/widgets/state_views.dart';
import 'package:sonic_player/presentation/widgets/bottom_sheet_handle.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);
    final playback = ref.watch(playbackProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header + Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Search', style: AppTextStyles.heading1),
                  const SizedBox(height: 16),
                  // Search input
                  TextField(
                    controller: _searchController,
                    focusNode: _focusNode,
                    style: AppTextStyles.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Search songs, artists, or playlists...',
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: AppColors.textTertiary),
                      suffixIcon: searchState.query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded,
                                  color: AppColors.textTertiary),
                              onPressed: () {
                                _searchController.clear();
                                ref
                                    .read(searchProvider.notifier)
                                    .clearResults();
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      ref.read(searchProvider.notifier).onQueryChanged(value);
                    },
                    onSubmitted: (value) {
                      ref.read(searchProvider.notifier).search(value);
                    },
                    textInputAction: TextInputAction.search,
                  ),
                ],
              ),
            ),

            // Filter chips
            if (searchState.hasResults)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: SearchFilter.values.map((filter) {
                      final isSelected = searchState.filter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(filter.label),
                          selected: isSelected,
                          onSelected: (_) {
                            ref
                                .read(searchProvider.notifier)
                                .setFilter(filter);
                          },
                          backgroundColor: AppColors.card,
                          selectedColor: AppColors.primary,
                          labelStyle: AppTextStyles.labelMedium.copyWith(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                          showCheckmark: false,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          side: BorderSide.none,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

            const SizedBox(height: 8),

            // Content
            Expanded(
              child: _buildContent(searchState, playback),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(SearchState searchState, PlaybackState playback) {
    // Loading
    if (searchState.isLoading) {
      return const LoadingView(itemCount: 8);
    }

    // Error
    if (searchState.hasError) {
      return ErrorView(
        message: searchState.error!,
        onRetry: () {
          ref.read(searchProvider.notifier).search(searchState.query);
        },
      );
    }

    // Empty search - show history
    if (!searchState.hasResults && searchState.query.isEmpty) {
      return _buildSearchHistory(searchState);
    }

    // No results
    if (searchState.isEmpty) {
      return const EmptyStateView(
        message: 'No results found',
        subtitle: 'Try a different search term.',
        icon: Icons.search_off_rounded,
      );
    }

    // Results
    return _buildResults(searchState, playback);
  }

  Widget _buildSearchHistory(SearchState searchState) {
    if (searchState.searchHistory.isEmpty) {
      return const EmptyStateView(
        message: 'Search for music',
        subtitle: 'Find your favorite songs, artists, and albums.',
        icon: Icons.search_rounded,
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent searches', style: AppTextStyles.labelLarge),
            TextButton(
              onPressed: () {
                ref.read(searchProvider.notifier).clearHistory();
              },
              child: Text('Clear all', style: AppTextStyles.seeAll),
            ),
          ],
        ),
        ...searchState.searchHistory.map((query) => ListTile(
              leading: const Icon(Icons.history_rounded,
                  color: AppColors.textTertiary, size: 20),
              title: Text(query, style: AppTextStyles.bodyMedium),
              trailing: IconButton(
                icon: const Icon(Icons.close_rounded,
                    color: AppColors.textTertiary, size: 18),
                onPressed: () {
                  ref
                      .read(searchProvider.notifier)
                      .removeFromHistory(query);
                },
              ),
              contentPadding: EdgeInsets.zero,
              onTap: () {
                _searchController.text = query;
                ref.read(searchProvider.notifier).search(query);
              },
            )),
      ],
    );
  }

  Widget _buildResults(SearchState searchState, PlaybackState playback) {
    final results = searchState.results!;
    final filter = searchState.filter;

    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        // Top result (when filter is 'All' and there are songs)
        if (filter == SearchFilter.all && results.songs.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('Top result', style: AppTextStyles.heading3),
          ),
          _buildTopResult(results.songs.first, playback),
          const SizedBox(height: 16),
        ],

        // Songs
        if ((filter == SearchFilter.all || filter == SearchFilter.songs) &&
            results.songs.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('Songs', style: AppTextStyles.heading3),
          ),
          ...results.songs
              .take(filter == SearchFilter.all ? 6 : results.songs.length)
              .map((song) => SongTile(
                    song: song,
                    isPlaying: playback.currentSong?.id == song.id,
                    onTap: () => _playSong(song, results.songs),
                    onMoreTap: () => _showSongOptions(song),
                  )),
          const SizedBox(height: 16),
        ],

        // Artists
        if ((filter == SearchFilter.all || filter == SearchFilter.artists) &&
            results.artists.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('Artists', style: AppTextStyles.heading3),
          ),
          ...results.artists.map((artist) => ListTile(
                leading: CircleAvatar(
                  backgroundImage: artist.thumbnailUrl.isNotEmpty
                      ? NetworkImage(artist.thumbnailUrl)
                      : null,
                  backgroundColor: AppColors.card,
                  child: artist.thumbnailUrl.isEmpty
                      ? const Icon(Icons.person_rounded,
                          color: AppColors.textTertiary)
                      : null,
                ),
                title: Text(artist.name, style: AppTextStyles.bodyMedium),
                subtitle: Text('Artist', style: AppTextStyles.bodySmall),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16),
              )),
          const SizedBox(height: 16),
        ],

        // Albums
        if ((filter == SearchFilter.all || filter == SearchFilter.albums) &&
            results.albums.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('Albums', style: AppTextStyles.heading3),
          ),
          ...results.albums.map((album) => ListTile(
                leading: ArtworkWidget(
                  url: album.thumbnailUrl,
                  size: 48,
                  borderRadius: 8,
                ),
                title: Text(album.title, style: AppTextStyles.bodyMedium),
                subtitle: Text(
                  '${album.artist}${album.year != null ? ' • ${album.year}' : ''}',
                  style: AppTextStyles.bodySmall,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.play_arrow_rounded,
                      color: AppColors.textSecondary),
                  onPressed: () {},
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16),
              )),
        ],
      ],
    );
  }

  Widget _buildTopResult(Song song, PlaybackState playback) {
    return GestureDetector(
      onTap: () => _playSong(song, [song]),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        ),
        child: Row(
          children: [
            ArtworkWidget(
              url: song.thumbnailUrl,
              size: 64,
              borderRadius: AppConstants.borderRadiusMedium,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(song.title,
                      style: AppTextStyles.heading3,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(
                    'Song • ${song.formattedDuration}',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
              ),
              child: const Icon(Icons.play_arrow_rounded,
                  color: Colors.white, size: 24),
            ),
          ],
        ),
      ),
    );
  }

  void _playSong(Song song, List<Song> queue) {
    ref.read(playbackProvider.notifier).playSong(song, queue: queue);
    ref.read(recentlyPlayedProvider.notifier).addSong(song);
  }

  void _showSongOptions(Song song) {
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
            const BottomSheetHandle(),
            ListTile(
              leading: Icon(
                isLiked
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: isLiked
                    ? AppColors.heartActive
                    : AppColors.textSecondary,
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
              title:
                  Text('Add to Queue', style: AppTextStyles.bodyMedium),
              onTap: () {
                ref.read(playbackProvider.notifier).addToQueue(song);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.playlist_add_rounded,
                  color: AppColors.textSecondary),
              title: Text('Add to Playlist',
                  style: AppTextStyles.bodyMedium),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
