import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

final postProvider = Provider<PostService>((ref) => PostService(ref));

class PostService {
  final Ref ref;
  final Dio _dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));

  PostService(this.ref);

  Future<void> createPost({
    required String title,
    required String body,
    required double latitude,
    required double longitude,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('ログインが必要です');
    final idToken = await user.getIdToken();

    final response = await _dio.post(
      '/posts',
      data: {
        'title': title,
        'body': body,
        'latitude': latitude,
        'longitude': longitude,
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer $idToken',
        },
      ),
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('投稿に失敗しました');
    }
  }
}
