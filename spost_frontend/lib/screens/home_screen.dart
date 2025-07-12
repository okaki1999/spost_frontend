import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spost_frontend/providers/auth_provider.dart';
import 'package:spost_frontend/providers/posts_provider.dart';
import 'package:spost_frontend/services/posts_service.dart';
import 'package:spost_frontend/screens/login_screen.dart';
import 'package:spost_frontend/screens/create_post_screen.dart';
import 'package:spost_frontend/screens/profile_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(postsProvider);
        },
        child: CustomScrollView(
        slivers: [
          // モダンなAppBar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Spost',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withOpacity(0.8),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              if (user != null) ...[
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.person),
                ),
                IconButton(
                  onPressed: () async {
                    final authService = ref.read(authServiceProvider);
                    await authService.signOut();
                  },
                  icon: const Icon(Icons.logout),
                ),
              ] else
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.login),
                ),
            ],
          ),

          // 投稿一覧
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: Consumer(
              builder: (context, ref, child) {
                final postsAsync = ref.watch(postsProvider);

                return postsAsync.when(
                  data: (posts) {
                    if (posts.isEmpty) {
                      return const SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.location_off,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  '近くに投稿がありません',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '100m以内の投稿が表示されます',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return _buildPostCard(context, posts[index]);
                        },
                        childCount: posts.length,
                      ),
                    );
                  },
                  loading: () => const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),
                  error: (error, stack) => SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'エラーが発生しました',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.red[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              error.toString(),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                ref.invalidate(postsProvider);
                              },
                              child: const Text('再試行'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (user != null) {
            // ログイン済みの場合、投稿作成画面へ
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CreatePostScreen(),
              ),
            );
          } else {
            // 未ログインの場合、ログイン画面へ
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const LoginScreen(),
              ),
            );
          }
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(user != null ? '投稿する' : 'ログインして投稿'),
      ),
    );
  }

  Widget _buildPostCard(BuildContext context, Post post) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  backgroundImage: post.userAvatar != null
                      ? NetworkImage('http://localhost:3000${post.userAvatar}')
                      : null,
                  child: post.userAvatar == null
                      ? Text(
                          post.userName?.substring(0, 1).toUpperCase() ??
                          post.userId.substring(0, 2).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.userName ??
                        (post.userId.length > 8
                            ? 'ユーザー ${post.userId.substring(0, 8)}'
                            : 'ユーザー ${post.userId}'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _formatDateTime(post.createdAt),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.location_on,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              post.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              post.body,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
                height: 1.4,
              ),
            ),
            // 画像表示
            if (post.imageUrl != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  'http://localhost:3000${post.imageUrl}',
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: double.infinity,
                      height: 200,
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(
                          Icons.broken_image,
                          size: 64,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 12),
            // Row(
            //   children: [
            //     Icon(
            //       Icons.favorite_border,
            //       size: 20,
            //       color: Colors.grey[600],
            //     ),
            //     const SizedBox(width: 4),
            //     Text(
            //       '0',
            //       style: TextStyle(
            //         color: Colors.grey[600],
            //         fontSize: 12,
            //       ),
            //     ),
            //     const SizedBox(width: 16),
            //     Icon(
            //       Icons.comment_outlined,
            //       size: 20,
            //       color: Colors.grey[600],
            //     ),
            //     const SizedBox(width: 4),
            //     Text(
            //       '0',
            //       style: TextStyle(
            //         color: Colors.grey[600],
            //         fontSize: 12,
            //       ),
            //     ),
            //   ],
            // ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}日前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}時間前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分前';
    } else {
      return '今';
    }
  }
}
