import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import 'recycle_screen.dart';
import 'dashboard_screen.dart';
import 'profile_screen.dart';
import 'recycle_map_screen.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  final _usernameController = TextEditingController();

  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _authService.getProfile();
      if (mounted) {
        setState(() {
          _profile = profile;
          _usernameController.text = profile?['username'] ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveUsername() async {
    if (_usernameController.text.trim().isEmpty) return;
    setState(() => _isSaving = true);
    try {
      await _authService.updateUsername(_usernameController.text.trim());
      await _loadProfile();
      if (mounted) {
        setState(() => _isEditing = false);
        _showSuccess('用户名已更新！');
      }
    } catch (e) {
      if (mounted) _showError('更新失败，请重试');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: GoogleFonts.dmSans(color: Colors.white)),
      backgroundColor: const Color(0xFFFF6B6B),
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

  void _goToDashboard() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DashboardScreen(),
      ),
    );
  }

  void _goToProfileScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProfileScreen(),
      ),
    );
  }

  void _goToRecycleMap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RecycleMapScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: SafeArea(
        child: _isLoading
            ? const Center(
            child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
            : SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Avatar + greeting
              Row(
                children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF9C88FF)],
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Center(
                      child: Text(
                        (_profile?['username'] ?? 'U')
                            .toString()
                            .substring(0, 1)
                            .toUpperCase(),
                        style: GoogleFonts.dmSerifDisplay(
                            color: Colors.white, fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('欢迎回来 👋',
                          style: GoogleFonts.dmSans(
                              color: Colors.white38, fontSize: 13)),
                      Text(
                        _profile?['username'] ?? 'User',
                        style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 40),

              Text('Profile',
                  style: GoogleFonts.dmSerifDisplay(
                      color: Colors.white, fontSize: 36)),

              const SizedBox(height: 32),

              // Email card
              _infoCard(
                icon: Icons.mail_outline_rounded,
                label: 'EMAIL',
                value: _profile?['email'] ?? '-',
              ),

              const SizedBox(height: 16),

              // Username card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E2E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isEditing
                        ? const Color(0xFF6C63FF)
                        : const Color(0xFF2A2A3E),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person_outline_rounded,
                            color: _isEditing
                                ? const Color(0xFF6C63FF)
                                : Colors.white38,
                            size: 18),
                        const SizedBox(width: 8),
                        Text('USERNAME',
                            style: GoogleFonts.dmSans(
                                color: Colors.white38,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1)),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            if (_isEditing) {
                              setState(() {
                                _isEditing = false;
                                _usernameController.text =
                                    _profile?['username'] ?? '';
                              });
                            } else {
                              setState(() => _isEditing = true);
                            }
                          },
                          child: Text(
                            _isEditing ? '取消' : '修改',
                            style: GoogleFonts.dmSans(
                              color: _isEditing
                                  ? Colors.white38
                                  : const Color(0xFF9C88FF),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_isEditing) ...[
                      TextField(
                        controller: _usernameController,
                        style: GoogleFonts.dmSans(
                            color: Colors.white, fontSize: 16),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: '输入新用户名',
                          hintStyle: GoogleFonts.dmSans(
                              color: Colors.white24),
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveUsername,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6C63FF),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: _isSaving
                              ? const SizedBox(width: 18, height: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2))
                              : Text('保存',
                              style: GoogleFonts.dmSans(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ] else
                      Text(
                        _profile?['username'] ?? '-',
                        style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Joined date card
              _infoCard(
                icon: Icons.calendar_today_outlined,
                label: 'JOINED',
                value: _profile?['created_at'] != null
                    ? DateTime.parse(_profile!['created_at'])
                    .toLocal()
                    .toString()
                    .substring(0, 10)
                    : '-',
              ),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RecycleScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.recycling_rounded, color: Colors.white),
                  label: Text(
                    'Go to Recycle Center',
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF82),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),


              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _goToDashboard,
                  icon: const Icon(Icons.dashboard_rounded, color: Colors.white),
                  label: Text(
                    'Go to Dashboard',
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),



              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _goToProfileScreen,
                  icon: const Icon(Icons.person_rounded, color: Colors.white),
                  label: Text(
                    'Go to Profile',
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9C88FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),



              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _goToRecycleMap,
                  icon: const Icon(Icons.map_rounded, color: Colors.white),
                  label: Text(
                    'Go to Recycle Map',
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A8E8), // 蓝色区分地图功能
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),




              // Sign out
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: () => _authService.signOut(),
                  icon: const Icon(Icons.logout_rounded,
                      color: Color(0xFFFF6B6B), size: 20),
                  label: Text('退出登录',
                      style: GoogleFonts.dmSans(
                          color: const Color(0xFFFF6B6B),
                          fontSize: 16,
                          fontWeight: FontWeight.w500)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                        color: Color(0xFF2A2A3E), width: 1.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A3E), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: Colors.white38, size: 18),
            const SizedBox(width: 8),
            Text(label,
                style: GoogleFonts.dmSans(
                    color: Colors.white38,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1)),
          ]),
          const SizedBox(height: 10),
          Text(value,
              style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}