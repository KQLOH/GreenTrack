import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  int _step = 1;
  bool _isLoading = false;

  // Resend OTP 相關
  int _resendCountdown = 0;
  Timer? _timer;

  void _startCountdown() {
    setState(() => _resendCountdown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // 1. 發送 OTP
  Future<void> _sendOTP({bool isResend = false}) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(_emailController.text.trim());

      _showSuccess(isResend ? 'Verification code resent!' : '8-digit code sent to your email');

      if (_step == 1) setState(() => _step = 2);
      _startCountdown();
    } catch (e) {
      _showError('Failed to send code. Please try again.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 2. 驗證 OTP
  Future<void> _verifyOTP() async {
    if (_otpController.text.length < 8) {
      _showError('Please enter the full 8-digit code');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.verifyOTP(
        email: _emailController.text.trim(),
        token: _otpController.text.trim(),
        type: OtpType.recovery,
      );
      setState(() => _step = 3);
    } catch (e) {
      _showError('Invalid or expired code');
    } finally {
      setState(() => _isLoading = false);
    }
  }

// 3. 更新密碼
  Future<void> _resetPassword() async {
    // 觸發輸入框樓下的 Validation
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      // 1. 調用 Supabase 更新密碼
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _newPasswordController.text.trim()),
      );

      // 2. 顯示成功提示（白色字體）
      _showSuccess('Password reset successful! Please login with your new password.');

      // 3. 強制登出（確保當前 Session 清除，讓用戶必須重新手動登錄）
      await Supabase.instance.client.auth.signOut();

      // 4. 延遲 2 秒讓用戶看清提示，然後退回到 Login Page
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          // 返回上一頁 (也就是 Login 頁面)
          Navigator.pop(context);
        }
      });
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('Could not update password. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w500)),
      backgroundColor: Colors.red.shade600,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w500)),
      backgroundColor: const Color(0xFF4CAF82),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A4731), Color(0xFF2D7A4F), Color(0xFF3DAB6A)],
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Form(
              key: _formKey, // 加入 Form Key 用於驗證
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Align(alignment: Alignment.centerLeft, child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                  )),
                  const SizedBox(height: 30),
                  _buildHeader(),
                  const SizedBox(height: 40),

                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
                    ),
                    child: Column(
                      children: [
                        if (_step == 1) _stepEmail(),
                        if (_step == 2) _stepOTP(),
                        if (_step == 3) _stepNewPassword(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    IconData icon = _step == 1 ? Icons.mark_email_read_outlined : (_step == 2 ? Icons.pin_outlined : Icons.lock_open_rounded);
    String title = _step == 1 ? 'Reset Password' : (_step == 2 ? 'Verify Code' : 'New Password');
    return Column(
      children: [
        Container(
          width: 70, height: 70,
          decoration: BoxDecoration(color: const Color(0xFF4CD787), borderRadius: BorderRadius.circular(20)),
          child: Icon(icon, color: Colors.white, size: 35),
        ),
        const SizedBox(height: 20),
        Text(title, style: GoogleFonts.dmSerifDisplay(color: Colors.white, fontSize: 30)),
      ],
    );
  }

  Widget _stepEmail() {
    return Column(
      children: [
        _buildInputField(
            _emailController,
            'EMAIL ADDRESS',
            Icons.email_outlined,
            validator: (val) {
              if (val == null || val.isEmpty) return 'Please enter email';
              if (!val.contains('@')) return 'Enter a valid email address';
              return null;
            }
        ),
        const SizedBox(height: 24),
        _buildButton('Send Verification Code', _sendOTP),
      ],
    );
  }

  Widget _stepOTP() {
    return Column(
      children: [
        Text('Enter the 8-digit code', style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 20),
        Stack(
          alignment: Alignment.center,
          children: [
            Opacity(
              opacity: 0,
              child: TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 8,
                autofocus: true,
                onChanged: (val) => setState(() {}),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(8, (index) {
                bool isFilled = _otpController.text.length > index;
                return Container(
                  width: 32, height: 45,
                  decoration: BoxDecoration(
                    color: isFilled ? const Color(0xFF4CD787).withOpacity(0.2) : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isFilled ? const Color(0xFF4CD787) : Colors.white24),
                  ),
                  child: Center(
                    child: Text(
                      isFilled ? _otpController.text[index] : "",
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
        const SizedBox(height: 30),
        _buildButton('Verify Code', _verifyOTP),
        const SizedBox(height: 15),
        TextButton(
          onPressed: _resendCountdown > 0 ? null : () => _sendOTP(isResend: true),
          child: Text(
            _resendCountdown > 0 ? 'Resend in ${_resendCountdown}s' : 'Resend OTP',
            style: GoogleFonts.dmSans(color: _resendCountdown > 0 ? Colors.white38 : const Color(0xFF7EEDB0), fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _stepNewPassword() {
    return Column(
      children: [
        _buildInputField(
            _newPasswordController,
            'NEW PASSWORD',
            Icons.lock_outline,
            isPsw: true,
            validator: (val) {
              if (val == null || val.isEmpty) return 'Please enter a password';
              if (val.length < 6) return 'At least 6 characters';
              // 密碼規則：字母、數字、符號
              if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[@$!%*#?&])[A-Za-z\d@$!%*#?&]').hasMatch(val)) {
                return 'Must include letters, numbers & symbols';
              }
              return null;
            }
        ),
        const SizedBox(height: 18),
        _buildInputField(
            _confirmPasswordController,
            'CONFIRM PASSWORD',
            Icons.lock_reset,
            isPsw: true,
            validator: (val) {
              if (val != _newPasswordController.text) return 'Passwords do not match';
              return null;
            }
        ),
        const SizedBox(height: 24),
        _buildButton('Update Password', _resetPassword),
      ],
    );
  }

  Widget _buildInputField(
      TextEditingController ctrl,
      String label,
      IconData icon,
      {bool isPsw = false, String? Function(String?)? validator}
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(label, style: GoogleFonts.dmSans(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
        ),
        TextFormField( // 改為 TextFormField 支援樓下顯示錯誤
          controller: ctrl,
          obscureText: isPsw,
          validator: validator,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.white60, size: 20),
            filled: true,
            fillColor: Colors.white.withOpacity(0.08),
            errorStyle: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 12), // 錯誤提示顏色
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF4CD787))),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFF6B6B))),
            focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFF6B6B))),
          ),
        ),
      ],
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity, height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4CD787),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))
        ),
        child: _isLoading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(text, style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
      ),
    );
  }
}