import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'User/login_screen.dart';
import 'User/main_navigation_screen.dart';
import 'services/supabase_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://thctyiijpgdeclqyflrr.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRoY3R5aWlqcGdkZWNscXlmbHJyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQwNjU3NTAsImV4cCI6MjA4OTY0MTc1MH0.hc9h7ikvRJtrtzZf1rTN1ty6GGDvFOYiZfusj3DVk3U',
  );

  await _verifySupabaseConnection();

  runApp(const MyApp());
}

Future<void> _verifySupabaseConnection() async {
  try {
    await supabaseClient.from('profiles').select('id').limit(1);
    debugPrint('Supabase connected successfully.');
  } catch (error) {
    debugPrint('Supabase connectivity check failed: $error');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    supabaseClient.auth.onAuthStateChange.listen((data) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = supabaseClient.auth.currentSession;
    if (session != null) {
      return const MainNavigationScreen();
    }
    return const LoginScreen();
  }
}
