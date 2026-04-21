import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client.dart';
import 'package:path/path.dart' as p;
import 'dart:convert';

class AuthService {
  final SupabaseClient _supabase = supabaseClient;

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

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

  Future<void> updateUsername(String username) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _supabase.from('profiles').update({
      'username': username,
    }).eq('id', user.id);
  }

  Future<UserResponse> updateEmail(String newEmail) async {
    return await _supabase.auth.updateUser(
      UserAttributes(email: newEmail),
    );
  }

  Future<UserResponse> updatePassword(String newPassword) async {
    return await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  Future<void> sendPasswordResetOTP() async {
    final user = _supabase.auth.currentUser;
    if (user == null || user.email == null) return;
    await _supabase.auth.resetPasswordForEmail(user.email!);
  }

  Future<String?> uploadAvatar(File imageFile) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final bytes = await imageFile.readAsBytes();
      final String base64String = base64Encode(bytes);

      final String dataUrl = 'data:image/jpeg;base64,$base64String';

      await _supabase.from('profiles').update({
        'avatar_url': dataUrl,
      }).eq('id', user.id);

      return dataUrl;
    } catch (_) {
      return null;
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  User? get currentUser => _supabase.auth.currentUser;
}
