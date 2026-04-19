import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  String? _loginErrorMessage;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    ));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _loginErrorMessage = null; // 每次點擊登錄時先清空之前的錯誤
    });

    try {
      await _authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // 登錄成功後的邏輯...
    } on AuthException {
      setState(() {
        // 這裡可以自定義顯示的文字，例如 "Invalid email or password"
        _loginErrorMessage = "Invalid email or password. Please try again.";
      });
    } catch (_) {
      setState(() {
        _loginErrorMessage = "An unexpected error occurred.";
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1A4731), // deep forest green
              Color(0xFF2D7A4F), // mid green
              Color(0xFF3DAB6A), // bright green
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 50),

                      // App Icon
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4CD787), Color(0xFF2DB86A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2DB86A)
                                  .withValues(alpha: 0.5),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.eco_rounded,
                            color: Colors.white,
                            size: 38,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // App name
                      Text(
                        'GreenTrack',
                        style: GoogleFonts.dmSerifDisplay(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Smart Recycling & Carbon Tracker',
                        style: GoogleFonts.dmSans(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 13,
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Card container
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // --- 新增：顯示在 EMAIL 字樣樓上的 Error Message ---
                            if (_loginErrorMessage != null)
                              Padding(
                                padding: const EdgeInsets.only(
                                    bottom: 16, left: 4), // 加一點左邊距對齊 Label
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start, // 如果訊息很長可以對齊頂部
                                  children: [
                                    // 亮紅色的圖標，起到警示作用
                                    const Icon(Icons.error_outline_rounded,
                                        color: Color(0xFFFF5252), size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _loginErrorMessage!,
                                        style: GoogleFonts.dmSans(
                                          color: Colors.white, // 依照你的要求使用純白色字
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          height: 1.4, // 增加行高，閱讀起來更舒服
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            // Email field
                            _GreenTextField(
                              label: 'EMAIL',
                              hint: 'your@email.com',
                              icon: Icons.mail_outline_rounded,
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              validator: (val) {
                                if (val == null || val.isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!val.contains('@')) {
                                  return 'Please enter a valid email address';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 18),

                            // Password field
                            _GreenTextField(
                              label: 'PASSWORD',
                              hint: 'Enter your password',
                              icon: Icons.lock_outline_rounded,
                              controller: _passwordController,
                              isPassword: true,
                              validator: (val) {
                                if (val == null || val.isEmpty) {
                                  return 'Please enter a password';
                                }
                                if (val.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 2),
                            //f0rgot pwrd
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const ForgotPasswordScreen()),
                                  );
                                },
                                child: Text(
                                  'Forgot Password?',
                                  style: GoogleFonts.dmSans(
                                    color: const Color(0xFF7EEDB0),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 1),

                            // Login button
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4CD787),
                                  disabledBackgroundColor:
                                      const Color(0xFF4CD787)
                                          .withValues(alpha: 0.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : Text(
                                        'Login',
                                        style: GoogleFonts.dmSans(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // OR divider
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                      color:
                                          Colors.white.withValues(alpha: 0.25)),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14),
                                  child: Text(
                                    'or',
                                    style: GoogleFonts.dmSans(
                                      color:
                                          Colors.white.withValues(alpha: 0.5),
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                      color:
                                          Colors.white.withValues(alpha: 0.25)),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Continue with Google
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const HomeScreen(),
                                    ),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    width: 1.5,
                                  ),
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.08),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.person_outline_rounded,
                                      color:
                                          Colors.white.withValues(alpha: 0.8),
                                      size: 22,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Continue as Guest',
                                      style: GoogleFonts.dmSans(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Register link
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterScreen(),
                            ),
                          );
                        },
                        child: RichText(
                          text: TextSpan(
                            style: GoogleFonts.dmSans(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 14,
                            ),
                            children: [
                              const TextSpan(text: "Don't have an account? "),
                              TextSpan(
                                text: 'Register',
                                style: GoogleFonts.dmSans(
                                  color: const Color(0xFF7EEDB0),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// â”€â”€â”€ Green-themed text field â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _GreenTextField extends StatefulWidget {
  final String label;
  final String hint;
  final IconData icon;
  final bool isPassword;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;

  const _GreenTextField({
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    this.isPassword = false,
    this.validator,
    this.keyboardType = TextInputType.text,
  });

  @override
  State<_GreenTextField> createState() => _GreenTextFieldState();
}

class _GreenTextFieldState extends State<_GreenTextField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: GoogleFonts.dmSans(
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          obscureText: widget.isPassword && _obscure,
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          style: GoogleFonts.dmSans(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: GoogleFonts.dmSans(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 15,
            ),
            prefixIcon: Icon(widget.icon,
                color: Colors.white.withValues(alpha: 0.6), size: 20),
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.white.withValues(alpha: 0.5),
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  )
                : null,
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.15),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFF4CD787),
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFFFF6B6B),
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFFFF6B6B),
                width: 1.5,
              ),
            ),
            errorStyle: GoogleFonts.dmSans(
                color: const Color(0xFFFF8F8F), fontSize: 12),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}
