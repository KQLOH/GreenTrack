import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/supabase_client.dart';

final _supabase = supabaseClient;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _profile;
  double _totalWeight = 0;
  double _co2Saved = 0;
  int _totalPoints = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Load profile
      final profile = await _supabase
          .from('profiles')
          .select('id, username, created_at, total_points')
          .eq('id', user.id)
          .single();

      // Load recycle stats
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

      if (mounted) {
        setState(() {
          _profile = Map<String, dynamic>.from(profile);
          _profile!['email'] = user.email ?? '';
          _totalWeight = totalWeight;
          _co2Saved = totalWeight * 2.5;
          _totalPoints = totalPoints;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Compute eco level from points
  Map<String, dynamic> _ecoLevel() {
    if (_totalPoints >= 500) {
      return {'label': 'Eco Master', 'level': 20, 'emoji': 'EM'};
    }
    if (_totalPoints >= 300) {
      return {'label': 'Eco Champion', 'level': 15, 'emoji': 'EC'};
    }
    if (_totalPoints >= 150) {
      return {'label': 'Eco Warrior', 'level': 12, 'emoji': 'EW'};
    }
    if (_totalPoints >= 50) {
      return {'label': 'Eco Starter', 'level': 5, 'emoji': 'ES'};
    }
    return {'label': 'Newcomer', 'level': 1, 'emoji': 'NC'};
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Logout',
            style: GoogleFonts.dmSans(
                color: const Color(0xFF1A4731), fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to logout?',
            style: GoogleFonts.dmSans(color: Colors.grey.shade600)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: GoogleFonts.dmSans(color: Colors.grey.shade500)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE05454),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text('Logout',
                style: GoogleFonts.dmSans(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirm == true) await _supabase.auth.signOut();
  }

  void _showEditUsernameSheet() async {
    final controller = TextEditingController(text: _profile?['username'] ?? '');
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditUsernameSheet(controller: controller),
    );
    if (result == true) await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final level = _ecoLevel();
    final username = _profile?['username'] ?? 'User';
    final email = _profile?['email'] ?? '';
    final joinedRaw = _profile?['created_at'];
    final joined = joinedRaw != null
        ? DateTime.parse(joinedRaw).toLocal().toString().substring(0, 10)
        : '-';

    return Scaffold(
      backgroundColor: const Color(0xFFF0F6F2),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2D7A4F)))
          : CustomScrollView(
              slivers: [
                // â”€â”€ Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
                            // Top bar
                            Row(children: [
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: Colors.white
                                            .withValues(alpha: 0.2)),
                                  ),
                                  child: const Icon(
                                      Icons.arrow_back_ios_new_rounded,
                                      color: Colors.white,
                                      size: 16),
                                ),
                              ),
                              const Spacer(),
                              Text('Profile',
                                  style: GoogleFonts.dmSans(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600)),
                              const Spacer(),
                              // Edit button
                              GestureDetector(
                                onTap: _showEditUsernameSheet,
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: Colors.white
                                            .withValues(alpha: 0.2)),
                                  ),
                                  child: const Icon(Icons.edit_outlined,
                                      color: Colors.white, size: 17),
                                ),
                              ),
                            ]),
                            const SizedBox(height: 24),
                            // Avatar
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: const Color(0xFF7EEDB0),
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: [
                                  BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.15),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6)),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  username.isNotEmpty
                                      ? username[0].toUpperCase()
                                      : 'U',
                                  style: GoogleFonts.dmSerifDisplay(
                                      color: const Color(0xFF1A4731),
                                      fontSize: 30),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(username,
                                style: GoogleFonts.dmSerifDisplay(
                                    color: Colors.white, fontSize: 22)),
                            const SizedBox(height: 4),
                            Text(email,
                                style: GoogleFonts.dmSans(
                                    color: Colors.white60, fontSize: 13)),
                            const SizedBox(height: 12),
                            // Eco badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2D7A4F),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: const Color(0xFF7EEDB0)
                                        .withValues(alpha: 0.4),
                                    width: 1.5),
                              ),
                              child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.eco_rounded,
                                        color: Color(0xFF7EEDB0), size: 15),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${level['label']} Â· Lv. ${level['level']}',
                                      style: GoogleFonts.dmSans(
                                          color: const Color(0xFF7EEDB0),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ]),
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
                    delegate: SliverChildListDelegate([
                      // â”€â”€ Stats Card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 12,
                                offset: const Offset(0, 4))
                          ],
                        ),
                        child: Row(children: [
                          _statItem('${_totalWeight.toStringAsFixed(1)} kg',
                              'Recycled'),
                          _divider(),
                          _statItem(_co2Saved.toStringAsFixed(1), 'CO2 Saved'),
                          _divider(),
                          _statItem(_totalPoints.toString(), 'Points'),
                        ]),
                      ),

                      const SizedBox(height: 28),

                      // â”€â”€ Account Section â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                      _sectionLabel('Account'),
                      const SizedBox(height: 10),
                      _menuGroup([
                        _MenuItem(
                          icon: Icons.edit_outlined,
                          iconColor: const Color(0xFFCC8A2E),
                          emojiColor: const Color(0xFFFFF3E3),
                          title: 'Edit Profile',
                          onTap: _showEditUsernameSheet,
                        ),
                        _MenuItem(
                          icon: Icons.notifications_none_rounded,
                          iconColor: const Color(0xFF4A90D9),
                          emojiColor: const Color(0xFFE8F0FA),
                          title: 'Notifications',
                          onTap: () => _showComingSoon('Notifications'),
                        ),
                        _MenuItem(
                          icon: Icons.shield_outlined,
                          iconColor: const Color(0xFFE8A020),
                          emojiColor: const Color(0xFFFBF3E3),
                          title: 'Privacy & Security',
                          onTap: () => _showComingSoon('Privacy & Security'),
                          isLast: true,
                        ),
                      ]),

                      const SizedBox(height: 24),

                      // â”€â”€ Achievements Section â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                      _sectionLabel('Achievements'),
                      const SizedBox(height: 10),
                      _menuGroup([
                        _MenuItem(
                          icon: Icons.history_rounded,
                          iconColor: const Color(0xFF3DAB6A),
                          emojiColor: const Color(0xFFE8F5EE),
                          title: 'Impact History',
                          subtitle: 'Joined $joined',
                          onTap: () => _showComingSoon('Impact History'),
                          isLast: true,
                        ),
                      ]),

                      const SizedBox(height: 24),

                      // â”€â”€ App Section â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                      _sectionLabel('App'),
                      const SizedBox(height: 10),
                      _menuGroup([
                        _MenuItem(
                          icon: Icons.star_border_rounded,
                          iconColor: const Color(0xFFE8A020),
                          emojiColor: const Color(0xFFFFF8E1),
                          title: 'Rate the App',
                          onTap: () => _showComingSoon('Rate the App'),
                        ),
                        _MenuItem(
                          icon: Icons.info_outline_rounded,
                          iconColor: const Color(0xFF4A90D9),
                          emojiColor: const Color(0xFFE8F0FA),
                          title: 'About GreenTrack',
                          subtitle: 'Version 1.0.0',
                          onTap: () => _showComingSoon('About'),
                          isLast: true,
                        ),
                      ]),

                      const SizedBox(height: 28),

                      // â”€â”€ Logout Button â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                      GestureDetector(
                        onTap: _signOut,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF0F0),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: const Color(0xFFFFD0D0), width: 1.5),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.logout_rounded,
                                  color: Color(0xFFE05454), size: 18),
                              const SizedBox(width: 8),
                              Text('Logout',
                                  style: GoogleFonts.dmSans(
                                      color: const Color(0xFFE05454),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _statItem(String value, String label) {
    return Expanded(
      child: Column(children: [
        Text(value,
            style: GoogleFonts.dmSans(
                color: const Color(0xFF1A4731),
                fontSize: 20,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label,
            style:
                GoogleFonts.dmSans(color: Colors.grey.shade400, fontSize: 12)),
      ]),
    );
  }

  Widget _divider() {
    return Container(width: 1, height: 36, color: Colors.grey.shade100);
  }

  Widget _sectionLabel(String title) {
    return Text(title,
        style: GoogleFonts.dmSans(
            color: const Color(0xFF1A4731),
            fontSize: 15,
            fontWeight: FontWeight.w700));
  }

  Widget _menuGroup(List<_MenuItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(children: items),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$feature â€” coming soon!',
          style: GoogleFonts.dmSans(color: Colors.white)),
      backgroundColor: const Color(0xFF2D7A4F),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }
}

// â”€â”€â”€ Menu Item â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color emojiColor;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool isLast;

  const _MenuItem({
    required this.icon,
    required this.iconColor,
    required this.emojiColor,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.isLast = false,
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
            child: Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: emojiColor, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.dmSans(
                            color: const Color(0xFF1A4731),
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!,
                          style: GoogleFonts.dmSans(
                              color: Colors.grey.shade400, fontSize: 12)),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: Colors.grey.shade300, size: 20),
            ]),
          ),
        ),
        if (!isLast)
          Divider(
              height: 1,
              color: Colors.grey.shade100,
              indent: 16,
              endIndent: 16),
      ],
    );
  }
}

// â”€â”€â”€ Edit Username Sheet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _EditUsernameSheet extends StatefulWidget {
  final TextEditingController controller;
  const _EditUsernameSheet({required this.controller});

  @override
  State<_EditUsernameSheet> createState() => _EditUsernameSheetState();
}

class _EditUsernameSheetState extends State<_EditUsernameSheet> {
  bool _isSaving = false;

  Future<void> _save() async {
    final name = widget.controller.text.trim();
    if (name.isEmpty) return;
    setState(() => _isSaving = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      await _supabase
          .from('profiles')
          .update({'username': name}).eq('id', user.id);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) Navigator.pop(context, false);
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
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Text('Edit Username',
                style: GoogleFonts.dmSans(
                    color: const Color(0xFF1A4731),
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(
              controller: widget.controller,
              autofocus: true,
              style: GoogleFonts.dmSans(
                  color: const Color(0xFF1A4731), fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Enter your username',
                hintStyle: GoogleFonts.dmSans(color: Colors.grey.shade300),
                filled: true,
                fillColor: const Color(0xFFF7F9F8),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFF3DAB6A), width: 1.5),
                ),
                prefixIcon: const Icon(Icons.person_outline_rounded,
                    color: Color(0xFF3DAB6A), size: 20),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D7A4F),
                  disabledBackgroundColor:
                      const Color(0xFF2D7A4F).withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : Text('Save Changes',
                        style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
