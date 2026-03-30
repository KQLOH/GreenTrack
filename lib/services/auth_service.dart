import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client.dart';

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
    // Create auth user in Supabase Auth (password stays in Auth, not profiles).
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
    );

    // Ensure a profile row exists/updates in a single idempotent call.
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
        .select('id, email, username, created_at, total_points')
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

  /// Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Get current user
  User? get currentUser => _supabase.auth.currentUser;
}