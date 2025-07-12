import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spost_frontend/services/posts_service.dart';

// PostsServiceのプロバイダー
final postsServiceProvider = Provider<PostsService>((ref) {
  return PostsService();
});

// 投稿一覧のプロバイダー
final postsProvider = FutureProvider<List<Post>>((ref) async {
  final postsService = ref.read(postsServiceProvider);
  return await postsService.getNearbyPosts();
});

// 投稿を再取得するためのプロバイダー
final postsRefreshProvider = FutureProvider.family<List<Post>, void>((ref, _) async {
  final postsService = ref.read(postsServiceProvider);
  return await postsService.getNearbyPosts();
});
