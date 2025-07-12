import 'dart:io';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:spost_frontend/providers/post_provider.dart';
import 'package:spost_frontend/providers/posts_provider.dart';
import 'package:spost_frontend/services/upload_service.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _uploadService = UploadService();
  final _imagePicker = ImagePicker();
  bool _isLoading = false;
  Position? _currentPosition;
  String? _selectedImagePath;
  html.File? _selectedWebFile;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() => _isLoading = true);

      // 位置情報の権限を確認
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('位置情報の権限が拒否されました');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('位置情報の権限が永続的に拒否されています');
      }

      // 現在位置を取得
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('位置情報の取得に失敗しました: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      if (kIsWeb) {
        // Web用の画像選択
        await _pickImageWeb();
      } else {
        // モバイル用の画像選択
        await _pickImageMobile();
      }
    } catch (e) {
      print('Image picker error: $e'); // デバッグ用ログ
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('画像の選択に失敗しました: $e'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _pickImageWeb() async {
    final input = html.FileUploadInputElement()..accept = 'image/*';
    input.click();

    await input.onChange.first;
    if (input.files?.isNotEmpty == true) {
      final file = input.files!.first;
      setState(() {
        _selectedWebFile = file;
      });
    }
  }

  Future<void> _pickImageMobile() async {
    // 画像ソースを選択するダイアログを表示
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('画像を選択'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('ギャラリーから選択'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('カメラで撮影'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return;

    final XFile? image = await _imagePicker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        _selectedImagePath = image.path;
      });
    }
  }

  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) return;
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('位置情報を取得できませんでした')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? imageUrl;

      // 画像が選択されている場合はアップロード
      if (kIsWeb && _selectedWebFile != null) {
        // Web用のアップロード
        imageUrl = await _uploadService.uploadImageWeb(_selectedWebFile!);
      } else if (!kIsWeb && _selectedImagePath != null) {
        // モバイル用のアップロード
        final file = File(_selectedImagePath!);
        imageUrl = await _uploadService.uploadImage(file);
      }

      // APIに投稿を送信
      final postService = ref.read(postProvider);
      await postService.createPost(
        title: _titleController.text,
        body: _contentController.text,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        imageUrl: imageUrl,
      );
      if (mounted) {
        // 投稿一覧を更新
        ref.invalidate(postsProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('投稿が完了しました！')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('投稿に失敗しました: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('投稿を作成'),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: _isLoading && _currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 位置情報表示
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '現在地',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (_currentPosition != null)
                                    Text(
                                      '緯度: ${_currentPosition!.latitude.toStringAsFixed(6)}\n経度: ${_currentPosition!.longitude.toStringAsFixed(6)}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    )
                                  else
                                    Text(
                                      '位置情報を取得中...',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: _getCurrentLocation,
                              icon: const Icon(Icons.refresh),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 画像選択
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.photo,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  '画像',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (kIsWeb && _selectedWebFile != null) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  html.Url.createObjectUrl(_selectedWebFile!),
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(height: 8),
                            ] else if (!kIsWeb && _selectedImagePath != null) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(_selectedImagePath!),
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _pickImage,
                                    icon: const Icon(Icons.photo_library),
                                    label: Text((kIsWeb && _selectedWebFile != null) || (!kIsWeb && _selectedImagePath != null) ? '画像を変更' : '画像を選択'),
                                  ),
                                ),
                                if ((kIsWeb && _selectedWebFile != null) || (!kIsWeb && _selectedImagePath != null)) ...[
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _selectedImagePath = null;
                                        _selectedWebFile = null;
                                      });
                                    },
                                    icon: const Icon(Icons.delete),
                                    label: const Text('削除'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // タイトル入力
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'タイトル',
                        hintText: '投稿のタイトルを入力してください',
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'タイトルを入力してください';
                        }
                        if (value.length > 50) {
                          return 'タイトルは50文字以内で入力してください';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // 内容入力
                    TextFormField(
                      controller: _contentController,
                      decoration: const InputDecoration(
                        labelText: '内容',
                        hintText: '投稿の内容を入力してください',
                        prefixIcon: Icon(Icons.edit),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 5,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '内容を入力してください';
                        }
                        if (value.length > 500) {
                          return '内容は500文字以内で入力してください';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 32),

                    // 投稿ボタン
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitPost,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              '投稿する',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}
