import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sonic_player/main.dart';
import 'package:sonic_player/services/storage/library_provider.dart';
import 'package:sonic_player/services/playback/youtube_player_service.dart';
import 'package:sonic_player/services/playback/playback_provider.dart';
import 'package:sonic_player/domain/entities/song.dart';
import 'package:sonic_player/domain/entities/playlist.dart';
import 'package:sonic_player/domain/entities/playback_state.dart';

void main() {
  testWidgets('App smoke test - app starts and shows home screen',
      (WidgetTester tester) async {
    // Override database-dependent and platform-dependent providers.
    // We must override the playbackProvider too since AppShell now reads
    // youtubePlayerServiceProvider and attaches it to the PlaybackNotifier.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Storage layer mocks (avoid sqflite)
          likedSongsProvider.overrideWith(
            (ref) => _MockLikedSongsNotifier(),
          ),
          playlistsProvider.overrideWith(
            (ref) => _MockPlaylistsNotifier(),
          ),
          recentlyPlayedProvider.overrideWith(
            (ref) => _MockRecentlyPlayedNotifier(),
          ),
          // YouTube player mocks (avoid WebView platform)
          youtubePlayerServiceProvider.overrideWith(
            (ref) => _MockYouTubePlayerService(),
          ),
          youtubePlayerControllerProvider.overrideWithValue(
            _MockYoutubePlayerController(),
          ),
        ],
        child: const SonicPlayerApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify the home screen is displayed
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

/// Mock notifiers that don't touch the database.
class _MockLikedSongsNotifier extends StateNotifier<List<Song>>
    implements LikedSongsNotifier {
  _MockLikedSongsNotifier() : super([]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockPlaylistsNotifier extends StateNotifier<List<Playlist>>
    implements PlaylistsNotifier {
  _MockPlaylistsNotifier() : super([]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockRecentlyPlayedNotifier extends StateNotifier<List<Song>>
    implements RecentlyPlayedNotifier {
  _MockRecentlyPlayedNotifier() : super([]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Mock YouTube player service that does nothing (no WebView needed).
class _MockYouTubePlayerService implements YouTubePlayerService {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// Fake YoutubePlayerController to avoid WebView platform requirement.
/// We use dynamic dispatch (noSuchMethod) since we never call real methods in tests.
class _MockYoutubePlayerController {
  dynamic noSuchMethod(Invocation invocation) => null;
}
