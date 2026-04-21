import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
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
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final response = await _authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        username: _usernameController.text.trim(),
      );


      if (response.user != null) {
        await Supabase.instance.client.from('user').insert({
          'name': _usernameController.text.trim(),
          'email': _emailController.text.trim(),
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      await Supabase.instance.client.auth.signOut();

      if (mounted) {
        _showSuccess(
            'Account created! Please login with your email and password.');

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      }
    } on AuthException catch (e) {
      if (mounted) _showError(e.message);
    } catch (e) {
      if (mounted)
        _showError(
            'Account created but failed to save profile: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: GoogleFonts.dmSans(color: Colors.white)),
      backgroundColor: Colors.red.shade600,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: GoogleFonts.dmSans(color: Colors.white)),
      backgroundColor: const Color(0xFF4CAF82),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1A4731),
              Color(0xFF2D7A4F),
              Color(0xFF3DAB6A),
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
                    children: [
                      const SizedBox(height: 30),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: Colors.white, size: 20),
                        ),
                      ),

                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [Color(0xFF4CD787), Color(0xFF2DB86A)]),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2DB86A).withOpacity(0.5),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.person_add_rounded,
                            color: Colors.white, size: 38),
                      ),

                      const SizedBox(height: 20),
                      Text('Join GreenTrack',
                          style: GoogleFonts.dmSerifDisplay(
                              color: Colors.white, fontSize: 30)),
                      const SizedBox(height: 6),
                      Text('Start your eco-friendly journey',
                          style: GoogleFonts.dmSans(
                              color: Colors.white.withOpacity(0.65),
                              fontSize: 13)),

                      const SizedBox(height: 32),

                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.15),
                              width: 1.5),
                        ),
                        child: Column(
                          children: [
                            _GreenTextField(
                              label: 'USERNAME',
                              hint: 'Your cool username',
                              icon: Icons.person_outline_rounded,
                              controller: _usernameController,
                              validator: (val) {
                                if (val == null || val.isEmpty)
                                  return 'Please enter a username';
                                if (val.length < 6)
                                  return 'Username must be at least 6 characters';

                                final hasLetter =
                                    RegExp(r'[a-zA-Z]').hasMatch(val);
                                final hasDigit = RegExp(r'[0-9]').hasMatch(val);

                                if (!hasLetter || !hasDigit) {
                                  return 'Must contain both letters and numbers';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 18),
                            _GreenTextField(
                              label: 'EMAIL',
                              hint: 'your@email.com',
                              icon: Icons.mail_outline_rounded,
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              validator: (val) =>
                                  (val == null || !val.contains('@'))
                                      ? 'Invalid email'
                                      : null,
                            ),
                            const SizedBox(height: 18),
                            _GreenTextField(
                              label: 'PASSWORD',
                              hint: 'Min 6 characters',
                              icon: Icons.lock_outline_rounded,
                              controller: _passwordController,
                              isPassword: true,
                              validator: (val) {
                                if (val == null || val.isEmpty)
                                  return 'Please enter a password';
                                if (val.length < 6)
                                  return 'Password must be at least 6 characters';

                                final hasLetter =
                                    RegExp(r'[a-zA-Z]').hasMatch(val);
                                final hasDigit = RegExp(r'[0-9]').hasMatch(val);
                                final hasSymbol =
                                    RegExp(r'[!@#$%^&*(),.?":{}|<>]')
                                        .hasMatch(val);

                                if (!hasLetter || !hasDigit || !hasSymbol) {
                                  return 'Must include letters, numbers, and symbols';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 18),
                            _GreenTextField(
                              label: 'CONFIRM PASSWORD',
                              hint: 'Re-enter password',
                              icon: Icons.lock_person_outlined,
                              controller: _confirmPasswordController,
                              isPassword: true,
                              validator: (val) =>
                                  (val != _passwordController.text)
                                      ? 'Passwords do not match'
                                      : null,
                            ),
                            const SizedBox(height: 28),

                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _register,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4CD787),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                  elevation: 0,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5))
                                    : Text('Create Account',
                                        style: GoogleFonts.dmSans(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: RichText(
                          text: TextSpan(
                            style: GoogleFonts.dmSans(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 14),
                            children: [
                              const TextSpan(text: 'Already have an account? '),
                              TextSpan(
                                text: 'Login',
                                style: GoogleFonts.dmSans(
                                    color: const Color(0xFF7EEDB0),
                                    fontWeight: FontWeight.w600),
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
        Text(widget.label,
            style: GoogleFonts.dmSans(
                color: Colors.white.withOpacity(0.75),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8)),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          obscureText: widget.isPassword && _obscure,
          keyboardType: widget.keyboardType,
          textCapitalization: TextCapitalization.none,
          autocorrect: false,
          enableSuggestions: false,
          validator: widget.validator,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle:
                TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 15),
            prefixIcon: Icon(widget.icon,
                color: Colors.white.withOpacity(0.6), size: 20),
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
                        color: Colors.white38,
                        size: 20),
                    onPressed: () => setState(() => _obscure = !_obscure))
                : null,
            filled: true,
            fillColor: Colors.white.withOpacity(0.10),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.15))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF4CD787))),
          ),
        ),
      ],
    );
  }
}
