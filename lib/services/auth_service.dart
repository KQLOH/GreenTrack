import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

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
    // Step 1: Create auth user
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
    );

    // Step 2: Wait a moment for trigger to create the profile row
    await Future.delayed(const Duration(milliseconds: 500));

    // Step 3: Update the profile row with username and password
    if (response.user != null) {
      await _supabase.from('profiles').update({
        'username': username,
        'password': password,
      }).eq('id', response.user!.id);
    }

    return response;
  }

  /// Get current user profile from profiles table
  Future<Map<String, dynamic>?> getProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final response = await _supabase
        .from('profiles')
        .select()
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