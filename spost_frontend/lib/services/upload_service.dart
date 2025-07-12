import 'dart:io';
import 'dart:html' as html;
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'package:http_parser/http_parser.dart';

class UploadService {
  final Dio _dio = Dio();
  static const String baseUrl = 'http://localhost:3000';

  UploadService() {
    _dio.options.baseUrl = baseUrl;
  }

  Future<String?> uploadImage(File imageFile) async {
    try {
      print('=== モバイルアップロード開始 ===');
      print('ファイルパス: ${imageFile.path}');
      print('ファイルサイズ: ${await imageFile.length()} bytes');

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('認証トークンが取得できませんでした');
      }
      final idToken = await user.getIdToken();
      print('認証トークン取得: OK');

      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
      });
      print('FormData作成: OK');

      print('リクエスト送信中...');
      final response = await _dio.post(
        '/upload/image',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $idToken',
          },
        ),
      );

      print('レスポンス受信: ${response.statusCode}');
      print('レスポンスデータ: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final url = response.data['url'];
        print('アップロード成功: $url');
        return url;
      } else {
        print('ステータスコードエラー: ${response.statusCode}');
        throw Exception('画像のアップロードに失敗しました');
      }
    } catch (e) {
      print('エラー発生: $e');
      throw Exception('画像のアップロードに失敗しました: $e');
    }
  }

  Future<String?> uploadImageWeb(html.File imageFile) async {
    try {
      print('=== アップロード開始 ===');
      print('ファイル名: ${imageFile.name}');
      print('ファイルタイプ: ${imageFile.type}');
      print('ファイルサイズ: ${imageFile.size} bytes');

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('認証トークンが取得できませんでした');
      }
      final idToken = await user.getIdToken();
      print('認証トークン取得: OK');

      // Use FileReader to read the file data
      final reader = html.FileReader();
      reader.readAsArrayBuffer(imageFile);

      // Wait for the file to be read
      await reader.onLoad.first;
      print('ファイル読み込み: OK');

      final bytes = reader.result as Uint8List;
      print('バイト数: ${bytes.length}');

      final mimeType = imageFile.type.split('/'); // 例: ['image', 'png']
      print('MIMEタイプ: ${mimeType[0]}/${mimeType[1]}');

      final formData = FormData.fromMap({
        'image': MultipartFile.fromBytes(
          bytes.toList(),
          filename: imageFile.name,
          contentType: MediaType(mimeType[0], mimeType[1]), // ここでMIMEタイプを明示
        ),
      });
      print('FormData作成: OK');

      print('リクエスト送信中...');
      final response = await _dio.post(
        '/upload/image',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $idToken',
          },
        ),
      );

      print('レスポンス受信: ${response.statusCode}');
      print('レスポンスデータ: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final url = response.data['url'];
        print('アップロード成功: $url');
        return url;
      } else {
        print('ステータスコードエラー: ${response.statusCode}');
        throw Exception('画像のアップロードに失敗しました');
      }
    } catch (e) {
      print('エラー発生: $e');
      throw Exception('画像のアップロードに失敗しました: $e');
    }
  }
}
