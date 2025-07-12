import 'dart:io';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:spost_frontend/providers/user_provider.dart';
import 'package:spost_frontend/services/upload_service.dart';
import 'package:spost_frontend/services/user_service.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _uploadService = UploadService();
  final _imagePicker = ImagePicker();
  bool _isLoading = false;
  String? _selectedImagePath;
  html.File? _selectedWebFile;

  @override
  void initState() {
    super.initState();
    // 現在のユーザー名を取得してテキストフィールドに設定
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userAsync = ref.read(userProfileProvider);
      userAsync.whenData((user) {
        if (user != null && user.name != null) {
          setState(() {
            _nameController.text = user.name!;
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
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

        ImageProvider? _getAvatarImage() {
    final userAsync = ref.read(userProfileProvider);
    final user = userAsync.value;

    print('=== アバター画像デバッグ ===');
    print('Web: $kIsWeb');
    print('選択された画像パス: $_selectedImagePath');
    print('選択されたWebファイル: ${_selectedWebFile?.name}');
    print('ユーザーアバター: ${user?.avatar}');

    if (!kIsWeb && _selectedImagePath != null) {
      // モバイルで選択された画像を表示
      print('モバイル画像を使用');
      return FileImage(File(_selectedImagePath!));
    } else if (user?.avatar != null) {
      // 保存済みのアバター画像を表示
      final avatarUrl = 'http://localhost:3000${user!.avatar!}';
      print('ネットワーク画像を使用: $avatarUrl');
      return NetworkImage(avatarUrl);
    }
    print('画像なし - 文字を表示');
    return null;
  }

  Widget _buildAvatarContent(User? user) {
    print('=== アバターコンテンツデバッグ ===');

    // 1. Webで選択された画像を優先
    if (kIsWeb && _selectedWebFile != null) {
      print('Web選択画像を表示');
      return Image.network(
        html.Url.createObjectUrl(_selectedWebFile!),
        width: 100,
        height: 100,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('Web画像読み込みエラー: $error');
          return _buildFallbackText(user);
        },
      );
    }

    // 2. モバイルで選択された画像
    if (!kIsWeb && _selectedImagePath != null) {
      print('モバイル選択画像を表示');
      return Image.file(
        File(_selectedImagePath!),
        width: 100,
        height: 100,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('モバイル画像読み込みエラー: $error');
          return _buildFallbackText(user);
        },
      );
    }

    // 3. 保存済みのアバター画像
    final userAsync = ref.read(userProfileProvider);
    final currentUser = userAsync.value;
    if (currentUser?.avatar != null) {
      print('保存済みアバター画像を表示: ${currentUser!.avatar}');
      return Image.network(
        'http://localhost:3000${currentUser.avatar!}',
        width: 100,
        height: 100,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('ネットワーク画像読み込みエラー: $error');
          return _buildFallbackText(user);
        },
      );
    }

    // 4. フォールバック: 文字を表示
    print('フォールバック: 文字を表示');
    return _buildFallbackText(user);
  }

  Widget _buildFallbackText(User? user) {
    return Container(
      width: 100,
      height: 100,
      color: Theme.of(context).colorScheme.primary,
      child: Center(
        child: Text(
          user?.name?.substring(0, 1).toUpperCase() ?? 'U',
          style: const TextStyle(
            fontSize: 32,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }



  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? avatarUrl;

      // 画像が選択されている場合はアップロード
      if (kIsWeb && _selectedWebFile != null) {
        // Web用のアップロード
        avatarUrl = await _uploadService.uploadImageWeb(_selectedWebFile!);
      } else if (!kIsWeb && _selectedImagePath != null) {
        // モバイル用のアップロード
        final file = File(_selectedImagePath!);
        avatarUrl = await _uploadService.uploadImage(file);
      }

      // プロフィール更新
      await ref.read(updateUserProfileProvider({
        'name': _nameController.text.trim(),
        if (avatarUrl != null) 'avatar': avatarUrl,
      }).future);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('プロフィールを更新しました')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新に失敗しました: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('プロフィール編集'),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(
              child: Text('ユーザー情報を取得できませんでした'),
            );
          }

          // ここでコントローラに初期値をセット（初回のみ）
          if (_nameController.text.isEmpty) {
            _nameController.text = user.name ?? '';
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // アバター表示・選択
                  Center(
                    child: Stack(
                      children: [
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            child: ClipOval(
                              child: _buildAvatarContent(user),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // 画像選択ボタン
                  Center(
                    child: TextButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('画像を選択'),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // メールアドレス表示（編集不可）
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'メールアドレス',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            user.email,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ユーザー名入力
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'ユーザー名',
                      hintText: 'ユーザー名を入力してください',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'ユーザー名を入力してください';
                      }
                      if (value.trim().length > 20) {
                        return 'ユーザー名は20文字以内で入力してください';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 32),

                  // 更新ボタン
                  ElevatedButton(
                    onPressed: _isLoading ? null : _updateProfile,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'プロフィールを更新',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
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
                  ref.invalidate(userProfileProvider);
                },
                child: const Text('再試行'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
