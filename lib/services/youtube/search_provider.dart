import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sonic_player/domain/entities/search_result.dart';

import 'package:sonic_player/services/youtube/youtube_service.dart';

/// Search state.
class SearchState {
  final String query;
  final SearchResult? results;
  final bool isLoading;
  final String? error;
  final SearchFilter filter;
  final List<String> searchHistory;

  const SearchState({
    this.query = '',
    this.results,
    this.isLoading = false,
    this.error,
    this.filter = SearchFilter.all,
    this.searchHistory = const [],
  });

  bool get hasResults => results != null && results!.isNotEmpty;
  bool get isEmpty => results != null && results!.isEmpty;
  bool get hasError => error != null;

  SearchState copyWith({
    String? query,
    SearchResult? results,
    bool? isLoading,
    String? error,
    SearchFilter? filter,
    List<String>? searchHistory,
  }) {
    return SearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      filter: filter ?? this.filter,
      searchHistory: searchHistory ?? this.searchHistory,
    );
  }
}

/// Provider for search state.
final searchProvider =
    StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  final youtube = ref.watch(youtubeServiceProvider);
  return SearchNotifier(youtube);
});

class SearchNotifier extends StateNotifier<SearchState> {
  final YouTubeService _youtube;
  Timer? _debounceTimer;

  SearchNotifier(this._youtube) : super(const SearchState()) {
    _loadSearchHistory();
  }

  Future<void> _loadSearchHistory() async {
    // Will be loaded from database in Phase 9
    state = state.copyWith(searchHistory: []);
  }

  /// Search with debounce.
  void onQueryChanged(String query) {
    state = state.copyWith(query: query);
    _debounceTimer?.cancel();

    if (query.trim().isEmpty) {
      state = state.copyWith(results: null, isLoading: false, error: null);
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  /// Immediately search (for submit).
  Future<void> search(String query) async {
    _debounceTimer?.cancel();
    state = state.copyWith(query: query);

    if (query.trim().isEmpty) return;

    // Add to history
    _addToHistory(query);
    await _performSearch(query);
  }

  Future<void> _performSearch(String query) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final results = await _youtube.search(query);
      if (mounted) {
        state = state.copyWith(results: results, isLoading: false);
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          error: 'Unable to search. Please try again.',
        );
      }
    }
  }

  void setFilter(SearchFilter filter) {
    state = state.copyWith(filter: filter);
  }

  void _addToHistory(String query) {
    final history = [
      query,
      ...state.searchHistory.where((h) => h != query),
    ].take(20).toList();
    state = state.copyWith(searchHistory: history);
  }

  void removeFromHistory(String query) {
    state = state.copyWith(
      searchHistory: state.searchHistory.where((h) => h != query).toList(),
    );
  }

  void clearHistory() {
    state = state.copyWith(searchHistory: []);
  }

  void clearResults() {
    state = state.copyWith(query: '', results: null, error: null);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
