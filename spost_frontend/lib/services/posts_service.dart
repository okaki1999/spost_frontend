import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';

class Post {
  final String id;
  final String title;
  final String body;
  final String? imageUrl;
  final String userId;
  final DateTime createdAt;
  final String location;
  final String? userName;
  final String? userEmail;
  final String? userAvatar;

  Post({
    required this.id,
    required this.title,
    required this.body,
    this.imageUrl,
    required this.userId,
    required this.createdAt,
    required this.location,
    this.userName,
    this.userEmail,
    this.userAvatar,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      imageUrl: json['imageUrl'],
      userId: json['userId'],
      createdAt: DateTime.parse(json['createdAt']),
      location: json['location'],
      userName: json['userName'],
      userEmail: json['userEmail'],
      userAvatar: json['userAvatar'],
    );
  }
}

class PostsService {
  final Dio _dio = Dio();
  static const String baseUrl = 'http://localhost:3000';

  PostsService() {
    _dio.options.baseUrl = baseUrl;
  }

  // 現在地の近くの投稿を取得
  Future<List<Post>> getNearbyPosts() async {
    try {
      // 現在地を取得
      final position = await _getCurrentPosition();

      final response = await _dio.get(
        '/posts',
        queryParameters: {
          'lat': position.latitude.toString(),
          'lng': position.longitude.toString(),
        },
      );

      if (response.statusCode == 200) {
        // レスポンスが文字列の場合はJSONとして解析
        final data = response.data;
        List<dynamic> postsList;

        if (data is String) {
          postsList = jsonDecode(data) as List<dynamic>;
        } else if (data is List) {
          postsList = data;
        } else {
          throw Exception('Unexpected response format');
        }

        return postsList.map((json) => Post.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load posts');
      }
    } catch (e) {
      print('Error fetching posts: $e');
      return [];
    }
  }

  // 現在地を取得
  Future<Position> _getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 位置情報サービスが有効かチェック
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    // 位置情報の権限をチェック
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    // 現在地を取得
    return await Geolocator.getCurrentPosition();
  }
}
