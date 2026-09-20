# BRAIN.md — Sonic Player Development Memory

## CURRENT STATE

- **Current Phase:** Phase 3 & 4 (YouTube Search + IFrame Playback Integration) - COMPLETE
- **Current Task:** TASK-004 — Trending Data & Git Push — COMPLETE
- **Build Status:** `flutter analyze` — PASS (0 issues)
- **Flutter Version:** 3.32.5 (stable)
- **Dart Version:** 3.8.1
- **Emulator:** Pixel 6 (running, emulator-5554)

### Frontend Status
- All screens implemented (Home, Search, Player, Queue, Library, Playlist Detail, Settings)
- Shell with bottom navigation and persistent mini-player
- GoRouter navigation configured
- Dark theme design system complete

### Backend Status
- SQLite database service created (schema defined, CRUD operations)
- YouTube Data API v3 service created
- Supabase integration NOT YET implemented (Phase 11)

### Playback Status
- PlaybackNotifier (state management) implemented
- YouTube IFrame player dependency added but NOT yet integrated into UI
- No actual audio playback yet — UI state management only

### Testing Status
- `flutter analyze`: PASS
- `flutter test`: PASS (1 test, mock overrides for sqflite)
- Emulator test: PASS (app launched, no crashes)

---

## TASK LOG

### TASK-001 — Project Initialization
**Status:** COMPLETED  
**Date:** 2026-09-20

**Files Created:**
- `pubspec.yaml` — 118 dependencies resolved
- `.env` — YouTube API key + Supabase placeholders
- `.env.example` — Sanitized variable names
- `.gitignore` — Updated with security patterns
- `android/app/src/main/AndroidManifest.xml` — Updated (INTERNET, FOREGROUND_SERVICE, WAKE_LOCK permissions, app label)

**Decisions:**
- DECISION-001: Flutter + Riverpod + GoRouter + SQLite + YouTube Data API v3
- DECISION-002: YouTube IFrame Player for permitted playback
- DECISION-003: Local-only storage (SQLite) with Supabase to be added later
- DECISION-004: Pixel 6 emulator for testing

---

### TASK-002 — Architecture + Core + UI
**Status:** COMPLETED  
**Date:** 2026-09-20

**Files Created:**

Core:
- `lib/core/theme/app_theme.dart` — Colors, text styles, ThemeData
- `lib/core/constants/app_constants.dart` — Spacing, sizes, API config
- `lib/core/errors/app_failure.dart` — Typed error hierarchy
- `lib/core/router/app_router.dart` — GoRouter with shell route

Domain:
- `lib/domain/entities/song.dart` — Song entity
- `lib/domain/entities/artist.dart` — Artist entity
- `lib/domain/entities/album.dart` — Album entity
- `lib/domain/entities/playlist.dart` — Playlist entity
- `lib/domain/entities/search_result.dart` — SearchResult + SearchFilter
- `lib/domain/entities/playback_state.dart` — PlaybackState, PlayStatus, RepeatMode, AudioQuality

Services:
- `lib/services/playback/playback_provider.dart` — Central playback state (Riverpod StateNotifier)
- `lib/services/storage/library_provider.dart` — Liked songs, playlists, recently played providers
- `lib/services/youtube/search_provider.dart` — Search state management with debounce
- `lib/services/youtube/youtube_service.dart` — YouTube Data API v3 client
- `lib/services/database/database_service.dart` — SQLite database with migrations

Presentation:
- `lib/presentation/shell/app_shell.dart` — Bottom nav + mini-player wrapper
- `lib/presentation/widgets/artwork_widget.dart` — Cached image with fallback
- `lib/presentation/widgets/song_tile.dart` — Song list item
- `lib/presentation/widgets/album_card.dart` — AlbumCard + PlaylistCard
- `lib/presentation/widgets/section_header.dart` — Section header with See All
- `lib/presentation/widgets/state_views.dart` — LoadingView, ErrorView, EmptyStateView
- `lib/presentation/widgets/mini_player.dart` — Persistent mini-player
- `lib/presentation/home/home_screen.dart` — Home with greeting, quick picks, recent, liked
- `lib/presentation/search/search_screen.dart` — Search with filters, history, results
- `lib/presentation/player/player_screen.dart` — Full-screen player
- `lib/presentation/queue/queue_screen.dart` — Queue management
- `lib/presentation/library/library_screen.dart` — Library with cards and menus
- `lib/presentation/playlists/playlist_detail_screen.dart` — Playlist detail
- `lib/presentation/settings/settings_screen.dart` — Settings

Entry Point:
- `lib/main.dart` — App entry with dotenv, Riverpod, GoRouter

Tests:
- `test/widget_test.dart` — Smoke test

---

### TASK-003 — Emulator Build + Test
**Status:** COMPLETED
**Date:** 2026-09-20

**Fixes Applied:**
- FIX-001: `_NavItem` Column overflow (6px) — Changed from fixed `SizedBox(height:56)` to `Padding + mainAxisSize.min`, reduced icon to 22 and font to 10
- FIX-002: Widget test `databaseFactory not initialized` — Added Riverpod provider overrides with mock StateNotifiers to bypass sqflite in tests
- FIX-003: NDK version mismatch warning — Changed `ndkVersion = flutter.ndkVersion` to `ndkVersion = "27.0.12077973"` in `android/app/build.gradle.kts`

**Results:**
- `flutter analyze`: PASS (0 issues)
- `flutter test`: PASS (1/1 tests)
- Gradle build: PASS (52.5s, debug APK)
- Emulator install: PASS (832ms)
- App launch: PASS (no crashes, no runtime exceptions)
- EGL/Impeller warnings: Expected on emulator (harmless)

---

## ARCHITECTURE

```
lib/
├── core/
│   ├── constants/app_constants.dart
│   ├── errors/app_failure.dart
│   ├── router/app_router.dart
│   └── theme/app_theme.dart
├── domain/entities/
│   ├── album.dart
│   ├── artist.dart
│   ├── playback_state.dart
│   ├── playlist.dart
│   ├── search_result.dart
│   └── song.dart
├── presentation/
│   ├── home/home_screen.dart
│   ├── library/library_screen.dart
│   ├── player/player_screen.dart
│   ├── playlists/playlist_detail_screen.dart
│   ├── queue/queue_screen.dart
│   ├── search/search_screen.dart
│   ├── settings/settings_screen.dart
│   ├── shell/app_shell.dart
│   └── widgets/ (6 reusable widgets)
├── services/
│   ├── database/database_service.dart
│   ├── playback/playback_provider.dart
│   ├── storage/library_provider.dart
│   └── youtube/
│       ├── search_provider.dart
│       └── youtube_service.dart
└── main.dart
```

**State Management:** Riverpod (StateNotifier)
**Routing:** GoRouter with ShellRoute
**Database:** SQLite via sqflite
**YouTube:** Data API v3 + IFrame Player
**Theme:** Custom dark theme (deep navy/purple)

---

## DECISION LOG

### DECISION-001
**Date:** 2026-09-20  
**Decision:** Use Riverpod for state management  
**Reason:** Production-grade, testable, compile-safe, recommended for Flutter  
**Alternatives:** Bloc, Provider, GetX  

### DECISION-002
**Date:** 2026-09-20  
**Decision:** YouTube IFrame Player for playback  
**Reason:** Only fully permitted YouTube playback mechanism per YouTube ToS  
**Limitation:** Background audio not supported through embedded player  

### DECISION-003
**Date:** 2026-09-20  
**Decision:** Local SQLite + planned Supabase backend  
**Reason:** User requested Supabase; starting with local for stability  

### DECISION-004
**Date:** 2026-09-20  
**Decision:** YouTube API key from user: AIzaSyDtZvdkKwQYtp6wGm28M0XYppaYDugPc2Y  
**Security:** Stored in .env, loaded via flutter_dotenv, never committed  

---

## KNOWN PROBLEMS
- RESOLVED: _NavItem bottom nav overflow (6px) → Fixed with flexible layout
- RESOLVED: Widget test crash (sqflite databaseFactory) → Fixed with mock provider overrides
- RESOLVED: NDK version mismatch → Fixed by pinning to 27.0.12077973

---

## FAILED APPROACHES
(None yet)

---

## DEPENDENCY MAP

| Package | Version | Purpose |
|---------|---------|---------|
| flutter_riverpod | ^2.6.1 | State management |
| go_router | ^14.8.1 | Routing |
| youtube_player_iframe | ^5.2.0 | YouTube playback |
| dio | ^5.7.0 | HTTP client |
| sqflite | ^2.4.2 | SQLite database |
| shared_preferences | ^2.3.5 | Key-value storage |
| cached_network_image | ^3.4.1 | Image caching |
| flutter_dotenv | ^5.2.1 | Environment variables |
| google_fonts | ^6.2.1 | Typography |
| shimmer | ^3.0.0 | Loading skeletons |
| uuid | ^4.5.1 | Unique IDs |
| supabase_flutter | ^2.9.0 | Backend (planned) |
| audio_service | ^0.18.17 | MediaSession (planned) |
| just_audio | ^0.9.43 | Audio playback (planned) |
| flutter_animate | ^4.5.2 | Animations |
| connectivity_plus | ^6.1.3 | Network checks |
| palette_generator | ^0.3.3+4 | Color extraction |
| intl | ^0.19.0 | Internationalization |

---

## TESTING MEMORY

| Test | Result | Date |
|------|--------|------|
| flutter analyze | PASS (0 issues) | 2026-09-20 |
| flutter pub get | PASS (118 deps) | 2026-09-20 |
| flutter test | PASS (1 test) | 2026-09-20 |
| Emulator launch | PASS | 2026-09-20 |
| Emulator app run | PASS (no crashes) | 2026-09-20 |
| Release APK | PENDING | - |
