import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../admin/admin_module_screen.dart';
import '../services/auth_service.dart';
import '../services/supabase_client.dart';
import 'recycle_map_screen.dart';
import 'impact_history_screen.dart';
import 'about_greentrack_screen.dart';
final _supabase = supabaseClient;
final _authService = AuthService();

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  bool _isAdmin = false;
  Map<String, dynamic>? _profile;
  double _totalWeight = 0;
  double _co2Saved = 0;
  int _totalPoints = 0;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    if (_profile == null) {
      setState(() => _isLoading = true);
    }

    try {
      final sessionRes = await _supabase.auth.refreshSession();
      final user = sessionRes.user;

      if (user == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final profile =
      await _supabase.from('profiles').select().eq('id', user.id).single();

      if (user.email != null && profile['email'] != user.email) {
        await _supabase
            .from('profiles')
            .update({'email': user.email}).eq('id', user.id);
        profile['email'] = user.email;
      }

      final records = await _supabase
          .from('recycle_records')
          .select('weight_kg, points')
          .eq('user_id', user.id);

      double totalWeight = 0;
      int totalPoints = 0;

      for (final r in records as List) {
        totalWeight += (r['weight_kg'] as num).toDouble();
        totalPoints += (r['points'] as num?)?.toInt() ?? 0;
      }

      final role = (profile['role'] ?? '').toString().toLowerCase();
      final isAdminFlag = profile['is_admin'] == true;

      int unreadCount = 0;
      try {
        final unread = await _supabase
            .from('notifications')
            .select('id')
            .eq('user_id', user.id)
            .eq('is_read', false);
        unreadCount = (unread as List).length;
      } catch (_) {}

      if (mounted) {
        setState(() {
          _profile = Map<String, dynamic>.from(profile);
          _profile!['email'] = user.email ?? profile['email'] ?? '';
          _isAdmin = isAdminFlag || role == 'admin';
          _totalWeight = totalWeight;
          _co2Saved = totalWeight * 2.5;
          _totalPoints = totalPoints;
          _unreadCount = unreadCount;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic> _ecoLevel() {
    if (_totalPoints >= 500) return {'label': 'Eco Master', 'level': 20};
    if (_totalPoints >= 300) return {'label': 'Eco Champion', 'level': 15};
    if (_totalPoints >= 150) return {'label': 'Eco Warrior', 'level': 12};
    if (_totalPoints >= 50) return {'label': 'Eco Starter', 'level': 5};
    return {'label': 'Newcomer', 'level': 1};
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Logout',
          style: GoogleFonts.dmSans(
            color: const Color(0xFF1A4731),
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: GoogleFonts.dmSans(color: Colors.grey.shade600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.dmSans(color: Colors.grey.shade500),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE05454),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: Text(
              'Logout',
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _supabase.auth.signOut();
    }
  }

  void _showEditProfileSheet() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditProfileSheet(
        currentUsername: _profile?['username'] ?? '',
        currentEmail: _profile?['email'] ?? '',
      ),
    );

    if (result == true) {
      await _loadData();
    }
  }

  void _showChangePasswordSheet() async {
    final authEmail = _supabase.auth.currentUser?.email ?? '';
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangePasswordSheet(email: authEmail),
    );
  }

  void _showMonthlyGoalSheet() async {
    final currentGoal =
        ((_profile?['monthly_goal_kg'] as num?)?.toDouble()) ?? 25.0;

    final result = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MonthlyGoalSheet(currentGoal: currentGoal),
    );

    if (result != null) {
      setState(() {
        _profile ??= {};
        _profile!['monthly_goal_kg'] = result;
      });

      try {
        final user = _supabase.auth.currentUser;
        if (user != null) {
          await _supabase
              .from('profiles')
              .update({'monthly_goal_kg': result}).eq('id', user.id);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Monthly goal updated successfully!',
                style: GoogleFonts.dmSans(color: Colors.white),
              ),
              backgroundColor: const Color(0xFF2D7A4F),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to save goal. Please try again.',
                style: GoogleFonts.dmSans(color: Colors.white),
              ),
              backgroundColor: const Color(0xFFE05454),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
          await _loadData();
        }
      }
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 512,
    );

    if (image == null) return;

    setState(() => _isLoading = true);

    try {
      await _authService.uploadAvatar(File(image.path));
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Avatar updated successfully!'),
            backgroundColor: Color(0xFF2D7A4F),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload avatar: $e'),
            backgroundColor: const Color(0xFFE05454),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openNotifications() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NotificationsSheet(
        userId: _supabase.auth.currentUser?.id ?? '',
      ),
    );
    await _loadData();
  }

  void _openAdminModule() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminModuleScreen()),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$feature – coming soon!',
          style: GoogleFonts.dmSans(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF2D7A4F),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final level = _ecoLevel();
    final username = _profile?['username'] ?? 'User';
    final email = _profile?['email'] ?? '';
    final avatarUrl = _profile?['avatar_url'];
    final joinedRaw = _profile?['created_at'];
    final joined = joinedRaw != null
        ? DateTime.parse(joinedRaw).toLocal().toString().substring(0, 10)
        : '-';

    // ── Read current goal for display ────────────────────────────────────
    final monthlyGoal =
        ((_profile?['monthly_goal_kg'] as num?)?.toDouble()) ?? 25.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F6F2),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(color: Color(0xFF2D7A4F)),
      )
          : RefreshIndicator(
        color: const Color(0xFF2D7A4F),
        onRefresh: _loadData,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A4731), Color(0xFF2D7A4F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius:
                                  BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'Profile',
                              style: GoogleFonts.dmSans(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: _showEditProfileSheet,
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius:
                                  BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.edit_outlined,
                                  color: Colors.white,
                                  size: 17,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Stack(
                          children: [
                            GestureDetector(
                              onTap: _pickAndUploadAvatar,
                              child: Container(
                                width: 84,
                                height: 84,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7EEDB0),
                                  borderRadius:
                                  BorderRadius.circular(26),
                                  image: avatarUrl != null
                                      ? DecorationImage(
                                    image: avatarUrl
                                        .startsWith(
                                        'data:image')
                                        ? MemoryImage(
                                      base64Decode(
                                        avatarUrl
                                            .split(',')
                                            .last,
                                      ),
                                    ) as ImageProvider
                                        : NetworkImage(avatarUrl),
                                    fit: BoxFit.cover,
                                  )
                                      : null,
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                      Colors.black.withOpacity(0.15),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: avatarUrl == null
                                    ? Center(
                                  child: Text(
                                    username.isNotEmpty
                                        ? username[0].toUpperCase()
                                        : 'U',
                                    style:
                                    GoogleFonts.dmSerifDisplay(
                                      color:
                                      const Color(0xFF1A4731),
                                      fontSize: 34,
                                    ),
                                  ),
                                )
                                    : null,
                              ),
                            ),
                            Positioned(
                              right: -2,
                              bottom: -2,
                              child: GestureDetector(
                                onTap: _pickAndUploadAvatar,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF3DAB6A),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          username,
                          style: GoogleFonts.dmSerifDisplay(
                            color: Colors.white,
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: GoogleFonts.dmSans(
                            color: Colors.white60,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2D7A4F),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF7EEDB0)
                                  .withOpacity(0.4),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.eco_rounded,
                                color: Color(0xFF7EEDB0),
                                size: 15,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${level['label']} · Lv. ${level['level']}',
                                style: GoogleFonts.dmSans(
                                  color: const Color(0xFF7EEDB0),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 40),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  [
                    // Stats row
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 20,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          _statItem(
                            '${_totalWeight.toStringAsFixed(1)} kg',
                            'Recycled',
                          ),
                          _divider(),
                          _statItem(
                            _co2Saved.toStringAsFixed(1),
                            'CO2 Saved',
                          ),
                          _divider(),
                          _statItem(
                            _totalPoints.toString(),
                            'Points',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Monthly Goal Card ─────────────────────────
                    _sectionLabel('Monthly Goal'),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: _showMonthlyGoalSheet,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5EE),
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: const Icon(
                                Icons.flag_rounded,
                                color: Color(0xFF3DAB6A),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Monthly Recycling Goal',
                                    style: GoogleFonts.dmSans(
                                      color: const Color(0xFF1A4731),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Tap to update your target',
                                    style: GoogleFonts.dmSans(
                                      color: Colors.grey.shade400,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Current goal badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5EE),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFF3DAB6A)
                                      .withOpacity(0.3),
                                  width: 1.2,
                                ),
                              ),
                              child: Text(
                                '${monthlyGoal % 1 == 0 ? monthlyGoal.toInt() : monthlyGoal.toStringAsFixed(1)} kg',
                                style: GoogleFonts.dmSans(
                                  color: const Color(0xFF2D7A4F),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.grey.shade300,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),
                    _sectionLabel('Account'),
                    const SizedBox(height: 10),
                    _menuGroup(
                      [
                        _MenuItem(
                          icon: Icons.edit_outlined,
                          iconColor: const Color(0xFFCC8A2E),
                          emojiColor: const Color(0xFFFFF3E3),
                          title: 'Edit Profile',
                          onTap: _showEditProfileSheet,
                        ),
                        _MenuItem(
                          icon: Icons.lock_outline_rounded,
                          iconColor: const Color(0xFFE8A020),
                          emojiColor: const Color(0xFFFBF3E3),
                          title: 'Change Password',
                          onTap: _showChangePasswordSheet,
                        ),


                      ],
                    ),
                    const SizedBox(height: 24),
                    _sectionLabel('Achievements'),
                    const SizedBox(height: 10),
                    _menuGroup(
                      [
                        _MenuItem(
                          icon: Icons.star_rounded,
                          iconColor: const Color(0xFFE8A020),
                          emojiColor: const Color(0xFFFFF3CD),
                          title: 'Favourite Stations',
                          subtitle: 'Your saved recycling spots',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                              const FavoriteStationsScreen(),
                            ),
                          ),
                        ),
                        _MenuItem(
                          icon: Icons.history_rounded,
                          iconColor: const Color(0xFF3DAB6A),
                          emojiColor: const Color(0xFFE8F5EE),
                          title: 'Impact History',
                          subtitle: 'Joined $joined',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ImpactHistoryScreen(),
                            ),
                          ),

                          isLast: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _sectionLabel('App'),
                    const SizedBox(height: 10),
                    _menuGroup(
                      [
                       _MenuItem(
                        icon: Icons.info_outline_rounded,
                        iconColor: const Color(0xFF4A90D9),
                        emojiColor: const Color(0xFFE8F0FA),
                        title: 'About GreenTrack',
                        subtitle: 'Version 1.0.0',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AboutGreenTrackScreen(),
                          ),
                        ),
                        isLast: true,
                      ),
                      ],
                    ),
                    if (_isAdmin) ...[
                      const SizedBox(height: 24),
                      _sectionLabel('Administration'),
                      const SizedBox(height: 10),
                      _menuGroup(
                        [
                          _MenuItem(
                            icon: Icons.admin_panel_settings_rounded,
                            iconColor: const Color(0xFF2D7A4F),
                            emojiColor: const Color(0xFFE8F5EE),
                            title: 'Admin Control Center',
                            subtitle:
                            'Manage users, records, and stations',
                            onTap: _openAdminModule,
                            isLast: true,
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 28),
                    GestureDetector(
                      onTap: _signOut,
                      child: Container(
                        width: double.infinity,
                        padding:
                        const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF0F0),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFFFD0D0),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.logout_rounded,
                              color: Color(0xFFE05454),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Logout',
                              style: GoogleFonts.dmSans(
                                color: const Color(0xFFE05454),
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.dmSans(
              color: const Color(0xFF1A4731),
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.dmSans(
              color: Colors.grey.shade400,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() =>
      Container(width: 1, height: 36, color: Colors.grey.shade100);

  Widget _sectionLabel(String title) {
    return Text(
      title,
      style: GoogleFonts.dmSans(
        color: const Color(0xFF1A4731),
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _menuGroup(List<_MenuItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(children: items),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Monthly Goal Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class MonthlyGoalSheet extends StatefulWidget {
  final double currentGoal;

  const MonthlyGoalSheet({super.key, required this.currentGoal});

  @override
  State<MonthlyGoalSheet> createState() => _MonthlyGoalSheetState();
}

class _MonthlyGoalSheetState extends State<MonthlyGoalSheet> {
  late TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  String? _errorText;

  // Quick preset options
  final List<double> _presets = [5, 10, 15, 20, 25, 30, 50, 100];

  @override
  void initState() {
    super.initState();
    final initial = widget.currentGoal;
    _controller = TextEditingController(
      text: initial % 1 == 0
          ? initial.toInt().toString()
          : initial.toStringAsFixed(1),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _selectPreset(double value) {
    setState(() {
      _controller.text =
      value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(1);
      _errorText = null;
    });
  }

  void _save() {
    final raw = _controller.text.trim();
    final value = double.tryParse(raw);

    if (value == null) {
      setState(() => _errorText = 'Please enter a valid number');
      return;
    }

    if (value < 1 || value > 500) {
      setState(() => _errorText = 'Goal must be between 1 and 500 kg');
      return;
    }

    setState(() => _isSaving = true);
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
      EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5EE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.flag_rounded,
                    color: Color(0xFF3DAB6A),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monthly Recycling Goal',
                      style: GoogleFonts.dmSans(
                        color: const Color(0xFF1A4731),
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Set your target kg per month',
                      style: GoogleFonts.dmSans(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Quick presets
            Text(
              'QUICK SELECT',
              style: GoogleFonts.dmSans(
                color: Colors.grey.shade500,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _presets.map((p) {
                final currentVal =
                    double.tryParse(_controller.text.trim()) ?? -1;
                final isSelected = currentVal == p;
                return GestureDetector(
                  onTap: () => _selectPreset(p),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF2D7A4F)
                          : const Color(0xFFF0F6F2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF2D7A4F)
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      '${p.toInt()} kg',
                      style: GoogleFonts.dmSans(
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF1A4731),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 22),

            // Custom input
            Text(
              'OR ENTER CUSTOM (KG)',
              style: GoogleFonts.dmSans(
                color: Colors.grey.shade500,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _controller,
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              onChanged: (_) => setState(() => _errorText = null),
              style: GoogleFonts.dmSans(
                color: const Color(0xFF1A4731),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: '25',
                hintStyle: GoogleFonts.dmSans(color: Colors.grey.shade300),
                suffixText: 'kg',
                suffixStyle: GoogleFonts.dmSans(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                ),
                filled: true,
                fillColor: const Color(0xFFF7F9F8),
                errorText: _errorText,
                errorStyle: GoogleFonts.dmSans(
                  color: const Color(0xFFE05454),
                  fontSize: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                  BorderSide(color: Colors.grey.shade200, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Color(0xFF3DAB6A), width: 1.5),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Color(0xFFE05454), width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D7A4F),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                )
                    : Text(
                  'Save Goal',
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// dashboard_screen.dart helper — call this to get the goal
// Add this static method or use it directly in DashboardScreen._loadData()
// ─────────────────────────────────────────────────────────────────────────────
//
// In dashboard_screen.dart, replace:
//   final double _monthlyGoal = 25.0;
//
// With:
//   double _monthlyGoal = 25.0;
//
// And inside _loadData(), after loading the profile, add:
//   _monthlyGoal = ((profile['monthly_goal_kg'] as num?)?.toDouble()) ?? 25.0;


// ─────────────────────────────────────────────────────────────────────────────
// The rest of the file below is unchanged from your original
// ─────────────────────────────────────────────────────────────────────────────

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color emojiColor;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool isLast;
  final int? badge;

  const _MenuItem({
    required this.icon,
    required this.iconColor,
    required this.emojiColor,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.isLast = false,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: emojiColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.dmSans(
                          color: const Color(0xFF1A4731),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: GoogleFonts.dmSans(
                            color: Colors.grey.shade400,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (badge != null) ...[
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE05454),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badge! > 99 ? '99+' : '$badge',
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey.shade300,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            color: Colors.grey.shade100,
            indent: 16,
            endIndent: 16,
          ),
      ],
    );
  }
}

class EditProfileSheet extends StatefulWidget {
  final String currentUsername;
  final String currentEmail;

  const EditProfileSheet({
    super.key,
    required this.currentUsername,
    required this.currentEmail,
  });

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentUsername);
    _emailController = TextEditingController(text: widget.currentEmail);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    setState(() => _isSaving = true);

    try {
      if (name != widget.currentUsername) {
        await _authService.updateUsername(name);
      }

      if (email != widget.currentEmail) {
        await _authService.updateEmail(email);
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Icons.mark_email_read_outlined,
                    color: Color(0xFF7EEDB0),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Confirmation link sent to $email',
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF1A4731),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else {
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF1A4731),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Profile updated successfully!',
                    style: GoogleFonts.dmSans(
                      color: const Color(0xFF1A4731),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF7EEDB0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 40),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFE05454),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
      EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Edit Profile',
                style: GoogleFonts.dmSans(
                  color: const Color(0xFF1A4731),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              _textField(
                controller: _nameController,
                label: 'Username',
                icon: Icons.person_outline_rounded,
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Please enter a username';
                  }
                  if (val.length < 6) return 'At least 6 characters';
                  final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(val);
                  final hasDigit = RegExp(r'[0-9]').hasMatch(val);
                  if (!hasLetter || !hasDigit) {
                    return 'Must contain letters and numbers';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _textField(
                controller: _emailController,
                label: 'Email Address',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (val) {
                  if (val == null || !val.contains('@')) {
                    return 'Invalid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D7A4F),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : Text(
                    'Save Changes',
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: GoogleFonts.dmSans(
        color: const Color(0xFF1A4731),
        fontSize: 15,
      ),
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.dmSans(color: Colors.grey.shade500),
        filled: true,
        fillColor: const Color(0xFFF7F9F8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
          const BorderSide(color: Color(0xFF3DAB6A), width: 1.5),
        ),
        prefixIcon: Icon(icon, color: const Color(0xFF3DAB6A), size: 20),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}

class ChangePasswordSheet extends StatefulWidget {
  final String email;

  const ChangePasswordSheet({
    super.key,
    required this.email,
  });

  @override
  State<ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmController = TextEditingController();

  int _step = 1;
  bool _isSaving = false;
  int _resendCountdown = 0;
  String? _localError;
  Timer? _timer;

  void _startCountdown() {
    setState(() => _resendCountdown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        if (mounted) setState(() => _resendCountdown--);
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    _passController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _sendOTP() async {
    setState(() => _isSaving = true);
    try {
      await _supabase.auth.resetPasswordForEmail(widget.email);
      if (mounted) {
        setState(() => _step = 2);
        _startCountdown();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '8-digit code sent to registered address: ${widget.email}'),
            backgroundColor: const Color(0xFF2D7A4F),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFE05454),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showAppSnackBar(
      BuildContext context,
      String message, {
        required bool isError,
        required IconData icon,
      }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              icon,
              color: isError ? Colors.white : const Color(0xFF1A4731),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.dmSans(
                  color: isError ? Colors.white : const Color(0xFF1A4731),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor:
        isError ? const Color(0xFFE05454) : const Color(0xFF7EEDB0),
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      ),
    );
  }

  Future<void> _verifyAndSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _localError = null;
    });

    try {
      await _supabase.auth.verifyOTP(
        email: widget.email,
        token: _otpController.text.trim(),
        type: OtpType.recovery,
      );

      await _authService.updatePassword(_passController.text.trim());

      if (mounted) {
        Navigator.pop(context);
        _showAppSnackBar(
          context,
          'Password updated successfully!',
          isError: false,
          icon: Icons.lock_reset_rounded,
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _localError = 'Invalid or expired code';
        });
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
      EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Change Password',
                style: GoogleFonts.dmSans(
                  color: const Color(0xFF1A4731),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'A verification code will be sent to your registered email: ${widget.email}',
                style: GoogleFonts.dmSans(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),
              if (_step == 1) ...[
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _sendOTP,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D7A4F),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                        : Text(
                      'Send Verification Code',
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                Text(
                  'Enter the 8-digit code',
                  style: GoogleFonts.dmSans(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(8, (index) {
                        final isFilled = _otpController.text.length > index;
                        return Container(
                          width: 32,
                          height: 45,
                          decoration: BoxDecoration(
                            color: isFilled
                                ? const Color(0xFF3DAB6A).withOpacity(0.1)
                                : const Color(0xFFF7F9F8),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isFilled
                                  ? const Color(0xFF3DAB6A)
                                  : Colors.grey.shade200,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              isFilled ? _otpController.text[index] : '',
                              style: const TextStyle(
                                color: Color(0xFF1A4731),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    Opacity(
                      opacity: 0,
                      child: TextField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        maxLength: 8,
                        autofocus: true,
                        readOnly: _isSaving,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          counterText: '',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _passField(
                  _passController,
                  'New Password',
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (val.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(val);
                    final hasDigit = RegExp(r'[0-9]').hasMatch(val);
                    final hasSymbol =
                    RegExp(r'[!@#$%+=_^&*(),.?":{}|<>]').hasMatch(val);                    if (!hasLetter || !hasDigit || !hasSymbol) {
                      return 'Must include letters, numbers, and symbols';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _passField(
                  _confirmController,
                  'Confirm New Password',
                  validator: (val) {
                    if (val != _passController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: _resendCountdown > 0 ? null : _sendOTP,
                      child: Text(
                        _resendCountdown > 0
                            ? 'Resend in ${_resendCountdown}s'
                            : 'Resend Code',
                        style: GoogleFonts.dmSans(
                          color: _resendCountdown > 0
                              ? Colors.grey
                              : const Color(0xFF3DAB6A),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_localError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Color(0xFFE05454),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _localError!,
                          style: GoogleFonts.dmSans(
                            color: const Color(0xFFE05454),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _verifyAndSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D7A4F),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                        : Text(
                      'Verify & Update Password',
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _passField(
      TextEditingController controller,
      String label, {
        String? Function(String?)? validator,
      }) {
    return TextFormField(
      controller: controller,
      obscureText: true,
      style: GoogleFonts.dmSans(
        color: const Color(0xFF1A4731),
        fontSize: 15,
      ),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.dmSans(color: Colors.grey.shade500),
        filled: true,
        fillColor: const Color(0xFFF7F9F8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        prefixIcon: const Icon(
          Icons.lock_outline_rounded,
          color: Color(0xFF3DAB6A),
          size: 20,
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}

class FavoriteStationsScreen extends StatefulWidget {
  const FavoriteStationsScreen({super.key});

  @override
  State<FavoriteStationsScreen> createState() => _FavoriteStationsScreenState();
}

class _FavoriteStationsScreenState extends State<FavoriteStationsScreen> {
  bool _isLoading = true;
  List<RecyclingCenter> _favorites = [];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);

    try {
      final userId = supabaseClient.auth.currentUser?.id;
      if (userId == null) {
        setState(() {
          _favorites = [];
          _isLoading = false;
        });
        return;
      }

      final rows = await supabaseClient
          .from('favorite_stations')
          .select('station_id, recycling_stations(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final result = <RecyclingCenter>[];

      for (final row in rows as List) {
        final station = row['recycling_stations'] as Map<String, dynamic>?;
        if (station == null) continue;

        double? toD(dynamic v) {
          if (v is num) return v.toDouble();
          if (v is String) return double.tryParse(v);
          return null;
        }

        final lat = toD(station['latitude']) ??
            toD(station['location_lat']) ??
            toD(station['lat']);
        final lng = toD(station['longitude']) ??
            toD(station['location_lng']) ??
            toD(station['lng']);

        if (lat == null || lng == null) continue;

        result.add(
          RecyclingCenter(
            id: (station['id'] ?? '').toString(),
            name: (station['name'] ?? '').toString(),
            address: (station['address'] ?? '').toString(),
            location: LatLng(lat, lng),
            phoneNumber: station['phone']?.toString(),
            isOpen:
            station['is_open'] == null ? true : station['is_open'] == true,
          ),
        );
      }

      if (mounted) {
        setState(() {
          _favorites = result;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _removeFavorite(String stationId) async {
    final userId = supabaseClient.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _favorites.removeWhere((c) => c.id == stationId));

    try {
      await supabaseClient
          .from('favorite_stations')
          .delete()
          .eq('user_id', userId)
          .eq('station_id', stationId);
    } catch (_) {
      _loadFavorites();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Failed to remove. Please try again.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: const Color(0xFFE05454),
            behavior: SnackBarBehavior.floating,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F6F2),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: const Color(0xFF1A4731),
            automaticallyImplyLeading: false,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
            actions: [
              GestureDetector(
                onTap: _loadFavorites,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(0, 8, 12, 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.refresh_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(56, 0, 56, 16),
              centerTitle: true,
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.star_rounded,
                    color: Color(0xFFE8A020),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Favourite Stations',
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A4731), Color(0xFF2D7A4F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 52),
                    child: Text(
                      'Your saved recycling spots',
                      style: GoogleFonts.dmSans(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF3DAB6A)),
              ),
            )
          else if (_favorites.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3CD),
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: const Icon(
                        Icons.star_border_rounded,
                        color: Color(0xFFE8A020),
                        size: 44,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No favourites yet',
                      style: GoogleFonts.dmSans(
                        color: const Color(0xFF1A4731),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap ⭐ on any station in the map to save it here',
                      style: GoogleFonts.dmSans(
                        color: Colors.grey.shade500,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5EE),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Color(0xFFE8A020),
                              size: 13,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${_favorites.length} station${_favorites.length != 1 ? 's' : ''} saved',
                              style: GoogleFonts.dmSans(
                                color: const Color(0xFF3DAB6A),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, i) {
                      final c = _favorites[i];
                      return _FavCard(
                        center: c,
                        onRemove: () => _removeFavorite(c.id),
                      );
                    },
                    childCount: _favorites.length,
                  ),
                ),
              ),
            ],
        ],
      ),
    );
  }
}

class _FavCard extends StatelessWidget {
  final RecyclingCenter center;
  final VoidCallback onRemove;

  const _FavCard({
    required this.center,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3CD),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.recycling_rounded,
                    color: Color(0xFFE8A020),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        center.name,
                        style: GoogleFonts.dmSans(
                          color: const Color(0xFF1A4731),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (center.address.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          center.address,
                          style: GoogleFonts.dmSans(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: center.isOpen
                                  ? const Color(0xFFE8F5EE)
                                  : const Color(0xFFFFF0F0),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  center.isOpen
                                      ? Icons.check_circle_outline_rounded
                                      : Icons.cancel_outlined,
                                  color: center.isOpen
                                      ? const Color(0xFF3DAB6A)
                                      : const Color(0xFFE05454),
                                  size: 11,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  center.isOpen ? 'Open now' : 'Closed',
                                  style: GoogleFonts.dmSans(
                                    color: center.isOpen
                                        ? const Color(0xFF3DAB6A)
                                        : const Color(0xFFE05454),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _confirmRemove(context),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFF3CD),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFE8A020),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmRemove(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Remove Favourite',
          style: GoogleFonts.dmSans(
            color: const Color(0xFF1A4731),
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Remove "${center.name}" from your favourites?',
          style: GoogleFonts.dmSans(color: Colors.grey.shade600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.dmSans(color: Colors.grey.shade500),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onRemove();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE05454),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: Text(
              'Remove',
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AppNotification {
  final String id;
  final String type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? data;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    this.data,
  });

  factory AppNotification.fromMap(Map<String, dynamic> m) {
    return AppNotification(
      id: m['id'].toString(),
      type: (m['type'] ?? 'info').toString(),
      title: (m['title'] ?? '').toString(),
      body: (m['body'] ?? '').toString(),
      isRead: m['is_read'] == true,
      createdAt: DateTime.parse(m['created_at'].toString()).toLocal(),
      data: m['data'] != null ? Map<String, dynamic>.from(m['data']) : null,
    );
  }
}

class NotificationsSheet extends StatefulWidget {
  final String userId;

  const NotificationsSheet({
    super.key,
    required this.userId,
  });

  @override
  State<NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends State<NotificationsSheet> {
  List<AppNotification> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);

    try {
      final data = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', widget.userId)
          .order('created_at', ascending: false)
          .limit(50);

      if (mounted) {
        setState(() {
          _notifications =
              (data as List).map((e) => AppNotification.fromMap(e)).toList();
          _isLoading = false;
        });
      }

      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', widget.userId)
          .eq('is_read', false);
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteOne(String id) async {
    if (mounted) {
      setState(() => _notifications.removeWhere((n) => n.id == id));
    }
    await _supabase.from('notifications').delete().eq('id', id);
  }

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Clear All',
          style: GoogleFonts.dmSans(
            color: const Color(0xFF1A4731),
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Delete all notifications?',
          style: GoogleFonts.dmSans(color: Colors.grey.shade600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.dmSans(color: Colors.grey.shade500),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE05454),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: Text(
              'Clear',
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (mounted) setState(() => _notifications.clear());
    await _supabase.from('notifications').delete().eq('user_id', widget.userId);
  }

  Map<String, dynamic> _typeConfig(String type) {
    switch (type) {
      case 'approved':
        return {
          'icon': Icons.check_circle_rounded,
          'color': const Color(0xFF3DAB6A),
          'bg': const Color(0xFFE8F5EE),
        };
      case 'rejected':
        return {
          'icon': Icons.cancel_rounded,
          'color': const Color(0xFFE05454),
          'bg': const Color(0xFFFFF0F0),
        };
      case 'points':
        return {
          'icon': Icons.star_rounded,
          'color': const Color(0xFFE8A020),
          'bg': const Color(0xFFFFF3CD),
        };
      default:
        return {
          'icon': Icons.notifications_rounded,
          'color': const Color(0xFF4A90D9),
          'bg': const Color(0xFFE8F0FA),
        };
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;

    return Container(
      height: screenH * 0.82,
      decoration: const BoxDecoration(
        color: Color(0xFFF0F6F2),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F0FA),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.notifications_rounded,
                          color: Color(0xFF4A90D9),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Notifications',
                              style: GoogleFonts.dmSans(
                                color: const Color(0xFF1A4731),
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (!_isLoading)
                              Text(
                                '${_notifications.length} notification${_notifications.length != 1 ? 's' : ''}',
                                style: GoogleFonts.dmSans(
                                  color: Colors.grey.shade400,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (_notifications.isNotEmpty)
                        GestureDetector(
                          onTap: _clearAll,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF0F0),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Clear all',
                              style: GoogleFonts.dmSans(
                                color: const Color(0xFFE05454),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF3DAB6A)),
            )
                : _notifications.isEmpty
                ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F0FA),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.notifications_off_outlined,
                      color: Color(0xFF4A90D9),
                      size: 38,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: GoogleFonts.dmSans(
                      color: const Color(0xFF1A4731),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              color: const Color(0xFF3DAB6A),
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                itemCount: _notifications.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final n = _notifications[i];
                  final cfg = _typeConfig(n.type);

                  return Dismissible(
                    key: Key(n.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE05454),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    onDismissed: (_) => _deleteOne(n.id),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: n.isRead
                            ? Colors.white
                            : const Color(0xFFF0F8FF),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: cfg['bg'] as Color,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              cfg['icon'] as IconData,
                              color: cfg['color'] as Color,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  n.title,
                                  style: GoogleFonts.dmSans(
                                    color: const Color(0xFF1A4731),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  n.body,
                                  style: GoogleFonts.dmSans(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Text(
                                      _timeAgo(n.createdAt),
                                      style: GoogleFonts.dmSans(
                                        color: Colors.grey.shade400,
                                        fontSize: 11,
                                      ),
                                    ),
                                    if (n.data != null &&
                                        n.data!['url'] != null) ...[
                                      const SizedBox(width: 10),
                                      GestureDetector(
                                        onTap: () async {
                                          final url = Uri.tryParse(
                                            n.data!['url'].toString(),
                                          );
                                          if (url != null) {
                                            await launchUrl(
                                              url,
                                              mode: LaunchMode
                                                  .externalApplication,
                                            );
                                          }
                                        },
                                        child: Text(
                                          'Open',
                                          style: GoogleFonts.dmSans(
                                            color: const Color(
                                                0xFF4A90D9),
                                            fontSize: 11,
                                            fontWeight:
                                            FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}