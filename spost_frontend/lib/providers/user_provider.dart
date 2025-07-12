import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spost_frontend/services/user_service.dart';
import 'package:spost_frontend/providers/auth_provider.dart';

// UserServiceのプロバイダー
final userServiceProvider = Provider<UserService>((ref) {
  return UserService();
});

// 現在のユーザープロフィールのプロバイダー
final userProfileProvider = FutureProvider<User?>((ref) async {
  final authState = ref.watch(authStateProvider);
  final userService = ref.read(userServiceProvider);

  final user = authState.value;
  if (user == null) return null;

  final token = await user.getIdToken();
  if (token == null) return null;

  return await userService.getProfile(token);
});

// ユーザープロフィール更新のプロバイダー
final updateUserProfileProvider = FutureProvider.family<User?, Map<String, String?>>((ref, data) async {
  final authState = ref.read(authStateProvider);
  final userService = ref.read(userServiceProvider);

  final user = authState.value;
  if (user == null) return null;

  final token = await user.getIdToken();
  if (token == null) return null;

  final updatedUser = await userService.updateProfile(
    token,
    name: data['name'],
    avatar: data['avatar'],
  );

  // プロフィールを再取得
  ref.invalidate(userProfileProvider);

  return updatedUser;
});
