import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client.dart';
import 'package:path/path.dart' as p;
import 'dart:convert';

class AuthService {
  final SupabaseClient _supabase = supabaseClient;

  /// Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign up with email, password and username
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
    );

    if (response.user != null) {
      await _supabase.from('profiles').upsert({
        'id': response.user!.id,
        'email': email,
        'username': username,
      }, onConflict: 'id');
    }

    return response;
  }

  /// Get current user profile from profiles table
  Future<Map<String, dynamic>?> getProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final response = await _supabase
        .from('profiles')
        .select('id, email, username, created_at, total_points, avatar_url')
        .eq('id', user.id)
        .single();

    return response;
  }

  /// Update username in profiles table
  Future<void> updateUsername(String username) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _supabase.from('profiles').update({
      'username': username,
    }).eq('id', user.id);
  }

  /// Update email using the standard confirmation link flow
  Future<UserResponse> updateEmail(String newEmail) async {
    return await _supabase.auth.updateUser(
      UserAttributes(email: newEmail),
    );
  }

  /// Update password (this will work if user is signed in)
  Future<UserResponse> updatePassword(String newPassword) async {
    return await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  /// Send password reset OTP to current email
  Future<void> sendPasswordResetOTP() async {
    final user = _supabase.auth.currentUser;
    if (user == null || user.email == null) return;
    await _supabase.auth.resetPasswordForEmail(user.email!);
  }


  Future<String?> uploadAvatar(File imageFile) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('❌ 找不到用戶');
        return null;
      }

      print('🚀 正在轉換圖片為 Base64 格式...');

      // 1. 讀取圖片並轉成 Base64 字串
      final bytes = await imageFile.readAsBytes();
      final String base64String = base64Encode(bytes);

      // 2. 加上 Data URL 前綴，讓 App 知道這是一張圖片文字
      final String dataUrl = 'data:image/jpeg;base64,$base64String';

      print('✅ 轉換完成，準備存入 Table...');

      // 3. 直接更新 Profiles Table，不再去碰 Storage
      await _supabase.from('profiles').update({
        'avatar_url': dataUrl, // 直接把這串超長文字存進去
      }).eq('id', user.id);

      print('🎉 太棒了！頭像已直接存入資料庫，繞過 Storage 成功！');
      return dataUrl;

    } catch (e) {
      print('❌ 這次連存 Table 都失敗了: $e');
      return null;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Get current user
  User? get currentUser => _supabase.auth.currentUser;
}
