import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../admin/admin_module_screen.dart';
import '../services/supabase_client.dart';
import 'recycle_map_screen.dart';
import 'package:url_launcher/url_launcher.dart';

final _supabase = supabaseClient;

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
    setState(() => _isLoading = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final profile =
          await _supabase.from('profiles').select().eq('id', user.id).single();

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
        final role = (profile['role'] ?? '').toString().toLowerCase();
        final isAdminFlag = profile['is_admin'] == true;

        // Load unread notifications count
        int unreadCount = 0;
        try {
          final unread = await _supabase
              .from('notifications')
              .select('id')
              .eq('user_id', user.id)
              .eq('is_read', false);
          unreadCount = (unread as List).length;
        } catch (_) {}

        setState(() {
          _profile = Map<String, dynamic>.from(profile);
          _profile!['email'] = user.email ?? '';
          _isAdmin = isAdminFlag || role == 'admin';
          _totalWeight = totalWeight;
          _co2Saved = totalWeight * 2.5;
          _totalPoints = totalPoints;
          _unreadCount = unreadCount;
          _isLoading = false;
        });
      }
    } catch (e) {
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

  void _openNotifications() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NotificationsSheet(
        userId: _supabase.auth.currentUser?.id ?? '',
      ),
    );
    // Refresh unread count after closing
    await _loadData();
  }

  void _openAdminModule() {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const AdminModuleScreen()));
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
                // ── Header ────────────────────────────────────────────────
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
                        child: Column(children: [
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
                                      color:
                                          Colors.white.withValues(alpha: 0.2)),
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
                            GestureDetector(
                              onTap: _showEditUsernameSheet,
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color:
                                          Colors.white.withValues(alpha: 0.2)),
                                ),
                                child: const Icon(Icons.edit_outlined,
                                    color: Colors.white, size: 17),
                              ),
                            ),
                          ]),
                          const SizedBox(height: 24),
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: const Color(0xFF7EEDB0),
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6))
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
                            child:
                                Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.eco_rounded,
                                  color: Color(0xFF7EEDB0), size: 15),
                              const SizedBox(width: 6),
                              Text('${level['label']} · Lv. ${level['level']}',
                                  style: GoogleFonts.dmSans(
                                      color: const Color(0xFF7EEDB0),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                            ]),
                          ),
                        ]),
                      ),
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 40),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // ── Stats ──────────────────────────────────────────
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

                      // ── Account ────────────────────────────────────────
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
                          badge: _unreadCount > 0 ? _unreadCount : null,
                          onTap: () => _openNotifications(),
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

                      // ── Achievements ───────────────────────────────────
                      _sectionLabel('Achievements'),
                      const SizedBox(height: 10),
                      _menuGroup([
                        _MenuItem(
                          icon: Icons.star_rounded,
                          iconColor: const Color(0xFFE8A020),
                          emojiColor: const Color(0xFFFFF3CD),
                          title: 'Favourite Stations',
                          subtitle: 'Your saved recycling spots',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const FavoriteStationsScreen()),
                          ),
                        ),
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

                      // ── App ────────────────────────────────────────────
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

                      if (_isAdmin) ...[
                        const SizedBox(height: 24),
                        _sectionLabel('Administration'),
                        const SizedBox(height: 10),
                        _menuGroup([
                          _MenuItem(
                            icon: Icons.admin_panel_settings_rounded,
                            iconColor: const Color(0xFF2D7A4F),
                            emojiColor: const Color(0xFFE8F5EE),
                            title: 'Admin Control Center',
                            subtitle: 'Manage users, records, and stations',
                            onTap: _openAdminModule,
                            isLast: true,
                          ),
                        ]),
                      ],

                      const SizedBox(height: 28),

                      // ── Logout ─────────────────────────────────────────
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
                              ]),
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

  Widget _divider() =>
      Container(width: 1, height: 36, color: Colors.grey.shade100);

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
      content: Text('$feature – coming soon!',
          style: GoogleFonts.dmSans(color: Colors.white)),
      backgroundColor: const Color(0xFF2D7A4F),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }
}

// ─── Menu Item ────────────────────────────────────────────────────────────────

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
                    ]),
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
                        fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 6),
              ],
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

// ─── Edit Username Sheet ──────────────────────────────────────────────────────

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
                        borderRadius: BorderRadius.circular(2))),
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
            ]),
      ),
    );
  }
}

// ─── Favourite Stations Screen ────────────────────────────────────────────────

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

  // ── Load from Supabase ────────────────────────────────────────────────────

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

      // Join favorite_stations with recycling_stations
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

        result.add(RecyclingCenter(
          id: (station['id'] ?? '').toString(),
          name: (station['name'] ?? '').toString(),
          address: (station['address'] ?? '').toString(),
          location: LatLng(lat, lng),
          phoneNumber: station['phone']?.toString(),
          isOpen:
              station['is_open'] == null ? true : station['is_open'] == true,
        ));
      }

      setState(() {
        _favorites = result;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  // ── Remove from Supabase ──────────────────────────────────────────────────

  Future<void> _removeFavorite(String stationId) async {
    final userId = supabaseClient.auth.currentUser?.id;
    if (userId == null) return;

    // Optimistic UI update
    setState(() => _favorites.removeWhere((c) => c.id == stationId));

    try {
      await supabaseClient
          .from('favorite_stations')
          .delete()
          .eq('user_id', userId)
          .eq('station_id', stationId);
    } catch (_) {
      // Reload on failure to restore correct state
      _loadFavorites();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to remove. Please try again.',
              style: GoogleFonts.dmSans(color: Colors.white)),
          backgroundColor: const Color(0xFFE05454),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F6F2),
      body: CustomScrollView(
        slivers: [
          // ── App Bar ───────────────────────────────────────────────────
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
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 16),
              ),
            ),
            actions: [
              // Refresh button
              GestureDetector(
                onTap: _loadFavorites,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(0, 8, 12, 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.refresh_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(56, 0, 56, 16),
              centerTitle: true,
              title: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.star_rounded,
                    color: Color(0xFFE8A020), size: 16),
                const SizedBox(width: 6),
                Text('Favourite Stations',
                    style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
              ]),
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
                    child: Text('Your saved recycling spots',
                        style: GoogleFonts.dmSans(
                            color: Colors.white60, fontSize: 12)),
                  ),
                ),
              ),
            ),
          ),

          // ── Body ──────────────────────────────────────────────────────
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF3DAB6A))),
            )
          else if (_favorites.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                        color: const Color(0xFFFFF3CD),
                        borderRadius: BorderRadius.circular(26)),
                    child: const Icon(Icons.star_border_rounded,
                        color: Color(0xFFE8A020), size: 44),
                  ),
                  const SizedBox(height: 20),
                  Text('No favourites yet',
                      style: GoogleFonts.dmSans(
                          color: const Color(0xFF1A4731),
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text('Tap ⭐ on any station in the map to save it here',
                      style: GoogleFonts.dmSans(
                          color: Colors.grey.shade500, fontSize: 13),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  // Count badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                        color: const Color(0xFFE8F5EE),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text('0 stations saved',
                        style: GoogleFonts.dmSans(
                            color: const Color(0xFF3DAB6A),
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ),
                ]),
              ),
            )
          else ...[
            // Count header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Row(children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: const Color(0xFFE8F5EE),
                        borderRadius: BorderRadius.circular(20)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.star_rounded,
                          color: Color(0xFFE8A020), size: 13),
                      const SizedBox(width: 5),
                      Text(
                          '${_favorites.length} station${_favorites.length != 1 ? 's' : ''} saved',
                          style: GoogleFonts.dmSans(
                              color: const Color(0xFF3DAB6A),
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ]),
              ),
            ),
            // List
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

// ─── Favourite Card ───────────────────────────────────────────────────────────

class _FavCard extends StatelessWidget {
  final RecyclingCenter center;
  final VoidCallback onRemove;

  const _FavCard({required this.center, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                  color: const Color(0xFFFFF3CD),
                  borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.recycling_rounded,
                  color: Color(0xFFE8A020), size: 24),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(center.name,
                        style: GoogleFonts.dmSans(
                            color: const Color(0xFF1A4731),
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                    if (center.address.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(center.address,
                          style: GoogleFonts.dmSans(
                              color: Colors.grey.shade500, fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ],
                    const SizedBox(height: 8),
                    Row(children: [
                      // Open/Closed
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: center.isOpen
                              ? const Color(0xFFE8F5EE)
                              : const Color(0xFFFFF0F0),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(
                              center.isOpen
                                  ? Icons.check_circle_outline_rounded
                                  : Icons.cancel_outlined,
                              color: center.isOpen
                                  ? const Color(0xFF3DAB6A)
                                  : const Color(0xFFE05454),
                              size: 11),
                          const SizedBox(width: 4),
                          Text(center.isOpen ? 'Open now' : 'Closed',
                              style: GoogleFonts.dmSans(
                                  color: center.isOpen
                                      ? const Color(0xFF3DAB6A)
                                      : const Color(0xFFE05454),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        ]),
                      ),
                      if (center.phoneNumber != null) ...[
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () =>
                              launchUrl(Uri.parse('tel:${center.phoneNumber}')),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                                color: const Color(0xFFF0EBF9),
                                borderRadius: BorderRadius.circular(8)),
                            child:
                                Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.phone_outlined,
                                  color: Color(0xFF9B6FD4), size: 11),
                              const SizedBox(width: 4),
                              Text(center.phoneNumber!,
                                  style: GoogleFonts.dmSans(
                                      color: const Color(0xFF9B6FD4),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600)),
                            ]),
                          ),
                        ),
                      ],
                    ]),
                  ]),
            ),

            // Remove star
            GestureDetector(
              onTap: () => _confirmRemove(context),
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                    color: Color(0xFFFFF3CD), shape: BoxShape.circle),
                child: const Icon(Icons.star_rounded,
                    color: Color(0xFFE8A020), size: 20),
              ),
            ),
          ]),
        ),

        // Bottom action row
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF7F9F8),
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(18)),
          ),
          child: Row(children: [
            // Navigate
            Expanded(
              child: GestureDetector(
                onTap: () => _openGoogleMaps(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.navigation_rounded,
                            color: Color(0xFF2D7A4F), size: 14),
                        const SizedBox(width: 6),
                        Text('Navigate',
                            style: GoogleFonts.dmSans(
                                color: const Color(0xFF2D7A4F),
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ]),
                ),
              ),
            ),
            Container(width: 1, height: 20, color: Colors.grey.shade200),
            // Remove
            Expanded(
              child: GestureDetector(
                onTap: () => _confirmRemove(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star_outline_rounded,
                            color: Color(0xFFE05454), size: 14),
                        const SizedBox(width: 6),
                        Text('Remove',
                            style: GoogleFonts.dmSans(
                                color: const Color(0xFFE05454),
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ]),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  void _confirmRemove(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Remove Favourite',
            style: GoogleFonts.dmSans(
                color: const Color(0xFF1A4731), fontWeight: FontWeight.w700)),
        content: Text('Remove "${center.name}" from your favourites?',
            style: GoogleFonts.dmSans(color: Colors.grey.shade600)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.dmSans(color: Colors.grey.shade500)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onRemove();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE05454),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text('Remove',
                style: GoogleFonts.dmSans(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<void> _openGoogleMaps(BuildContext context) async {
    final uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=${center.location.latitude},${center.location.longitude}&travelmode=driving');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
// ─── Notifications Sheet ──────────────────────────────────────────────────────

class AppNotification {
  final String id;
  final String type; // 'approved', 'rejected', 'points'
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
  const NotificationsSheet({super.key, required this.userId});

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
      // Mark all as read silently
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
    setState(() => _notifications.removeWhere((n) => n.id == id));
    await _supabase.from('notifications').delete().eq('id', id);
  }

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Clear All',
            style: GoogleFonts.dmSans(
                color: const Color(0xFF1A4731), fontWeight: FontWeight.w700)),
        content: Text('Delete all notifications?',
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
            child: Text('Clear',
                style: GoogleFonts.dmSans(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _notifications.clear());
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
      child: Column(children: [
        // ── Handle + Header ────────────────────────────────────────
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F0FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.notifications_rounded,
                      color: Color(0xFF4A90D9), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Notifications',
                            style: GoogleFonts.dmSans(
                                color: const Color(0xFF1A4731),
                                fontSize: 17,
                                fontWeight: FontWeight.w700)),
                        if (!_isLoading)
                          Text(
                              '${_notifications.length} notification${_notifications.length != 1 ? 's' : ''}',
                              style: GoogleFonts.dmSans(
                                  color: Colors.grey.shade400, fontSize: 12)),
                      ]),
                ),
                if (_notifications.isNotEmpty)
                  GestureDetector(
                    onTap: _clearAll,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0F0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('Clear all',
                          style: GoogleFonts.dmSans(
                              color: const Color(0xFFE05454),
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
              ]),
            ),
          ]),
        ),

        // ── Body ───────────────────────────────────────────────────
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF3DAB6A)))
              : _notifications.isEmpty
                  ? Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                              color: const Color(0xFFE8F0FA),
                              borderRadius: BorderRadius.circular(24)),
                          child: const Icon(Icons.notifications_off_outlined,
                              color: Color(0xFF4A90D9), size: 38),
                        ),
                        const SizedBox(height: 16),
                        Text('No notifications yet',
                            style: GoogleFonts.dmSans(
                                color: const Color(0xFF1A4731),
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Text(
                            'You\'ll be notified when your\nrecords are approved or rejected.',
                            style: GoogleFonts.dmSans(
                                color: Colors.grey.shade400, fontSize: 13),
                            textAlign: TextAlign.center),
                      ]),
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
                              child: const Icon(Icons.delete_outline,
                                  color: Colors.white, size: 22),
                            ),
                            onDismissed: (_) => _deleteOne(n.id),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: n.isRead
                                    ? Colors.white
                                    : const Color(0xFFF0F8FF),
                                borderRadius: BorderRadius.circular(16),
                                border: n.isRead
                                    ? null
                                    : Border.all(
                                        color: const Color(0xFF4A90D9)
                                            .withValues(alpha: 0.2),
                                        width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2))
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
                                        borderRadius: BorderRadius.circular(13),
                                      ),
                                      child: Icon(cfg['icon'] as IconData,
                                          color: cfg['color'] as Color,
                                          size: 22),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(children: [
                                              Expanded(
                                                child: Text(n.title,
                                                    style: GoogleFonts.dmSans(
                                                      color: const Color(
                                                          0xFF1A4731),
                                                      fontSize: 13,
                                                      fontWeight: n.isRead
                                                          ? FontWeight.w600
                                                          : FontWeight.w700,
                                                    )),
                                              ),
                                              if (!n.isRead)
                                                Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration:
                                                      const BoxDecoration(
                                                          color:
                                                              Color(0xFF4A90D9),
                                                          shape:
                                                              BoxShape.circle),
                                                ),
                                            ]),
                                            const SizedBox(height: 4),
                                            Text(n.body,
                                                style: GoogleFonts.dmSans(
                                                    color: Colors.grey.shade500,
                                                    fontSize: 12),
                                                maxLines: 2,
                                                overflow:
                                                    TextOverflow.ellipsis),
                                            const SizedBox(height: 6),
                                            Text(_timeAgo(n.createdAt),
                                                style: GoogleFonts.dmSans(
                                                    color: Colors.grey.shade400,
                                                    fontSize: 11)),
                                          ]),
                                    ),
                                  ]),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ]),
    );
  }
}
