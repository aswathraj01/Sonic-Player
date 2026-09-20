import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sonic_player/domain/entities/song.dart';
import 'package:sonic_player/services/youtube/youtube_service.dart';

final trendingProvider = FutureProvider<List<Song>>((ref) async {
  final youtubeService = ref.watch(youtubeServiceProvider);
  return youtubeService.getTrendingMusic();
});
