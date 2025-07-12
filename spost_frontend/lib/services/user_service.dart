import 'package:dio/dio.dart';

class User {
  final String id;
  final String firebaseUid;
  final String email;
  final String? name;
  final String? avatar;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.firebaseUid,
    required this.email,
    this.name,
    this.avatar,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      firebaseUid: json['firebaseUid'],
      email: json['email'],
      name: json['name'],
      avatar: json['avatar'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

class UserService {
  final Dio _dio = Dio();
  static const String baseUrl = 'http://localhost:3000';

  UserService() {
    _dio.options.baseUrl = baseUrl;
  }

  // ユーザープロフィール取得
  Future<User?> getProfile(String token) async {
    try {
      final response = await _dio.get(
        '/users/profile',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        return User.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  // ユーザープロフィール更新
  Future<User?> updateProfile(String token, {String? name, String? avatar}) async {
    try {
      final response = await _dio.put(
        '/users/profile',
        data: {
          if (name != null) 'name': name,
          if (avatar != null) 'avatar': avatar,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        return User.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print('Error updating user profile: $e');
      return null;
    }
  }
}
