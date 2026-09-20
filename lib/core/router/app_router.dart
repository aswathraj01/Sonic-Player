import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sonic_player/presentation/home/home_screen.dart';
import 'package:sonic_player/presentation/search/search_screen.dart';
import 'package:sonic_player/presentation/library/library_screen.dart';
import 'package:sonic_player/presentation/player/player_screen.dart';
import 'package:sonic_player/presentation/queue/queue_screen.dart';
import 'package:sonic_player/presentation/playlists/playlist_detail_screen.dart';
import 'package:sonic_player/presentation/settings/settings_screen.dart';
import 'package:sonic_player/presentation/shell/app_shell.dart';

/// Shared fade+scale page transition for shell tab switches.
CustomTransitionPage<void> _fadeTabPage({
  required Widget child,
  required GoRouterState state,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 200),
    reverseTransitionDuration: const Duration(milliseconds: 150),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOut,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.97, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Shared slide-from-right page transition for full-screen pushes.
CustomTransitionPage<void> _slideRightPage({
  required Widget child,
  required GoRouterState state,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      );
    },
  );
}

class AppRouter {
  AppRouter._();

  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    routes: [
      // Shell route wraps bottom nav + mini player
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            pageBuilder: (context, state) =>
                _fadeTabPage(child: const HomeScreen(), state: state),
          ),
          GoRoute(
            path: '/search',
            name: 'search',
            pageBuilder: (context, state) =>
                _fadeTabPage(child: const SearchScreen(), state: state),
          ),
          GoRoute(
            path: '/library',
            name: 'library',
            pageBuilder: (context, state) =>
                _fadeTabPage(child: const LibraryScreen(), state: state),
          ),
        ],
      ),
      // Full-screen player — slides up from bottom
      GoRoute(
        path: '/player',
        name: 'player',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const PlayerScreen(),
          transitionDuration: const Duration(milliseconds: 350),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(curved),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0.8, end: 1.0).animate(curved),
                child: child,
              ),
            );
          },
        ),
      ),
      // Queue — slides in from right
      GoRoute(
        path: '/queue',
        name: 'queue',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
            _slideRightPage(child: const QueueScreen(), state: state),
      ),
      // Playlist detail — slides in from right
      GoRoute(
        path: '/playlist/:id',
        name: 'playlist-detail',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _slideRightPage(
          child: PlaylistDetailScreen(
            playlistId: state.pathParameters['id']!,
          ),
          state: state,
        ),
      ),
      // Settings — slides in from right
      GoRoute(
        path: '/settings',
        name: 'settings',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
            _slideRightPage(child: const SettingsScreen(), state: state),
      ),
    ],
  );
}
