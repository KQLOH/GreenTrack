import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/supabase_client.dart';
import 'recycle_screen.dart';

final supabase = supabaseClient;

// â”€â”€â”€ Dashboard Screen â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  String _username = '';

  // Computed stats
  double _weeklyWeight = 0;
  double _monthlyWeight = 0;
  double _co2Saved = 0;
  final double _monthlyGoal = 25.0; // kg target
  int _totalPoints = 0;
  List<double> _weeklyBarData = List.filled(7, 0);
  Map<String, double> _categoryBreakdown = {};
  List<Map<String, dynamic>> _recentActivity = [];

  // Nearby stations loaded from Supabase `recycling_stations`.
  List<Map<String, dynamic>> _stations = [];

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _loadData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // Load profile
      final profile = await supabase
          .from('profiles')
          .select('username')
          .eq('id', user.id)
          .single();

      // Load all records
      final records = await supabase
          .from('recycle_records')
          .select()
          .eq('user_id', user.id)
          .order('date', ascending: false);

      final now = DateTime.now();
      final startOfWeek =
      now.subtract(Duration(days: now.weekday - 1)); // Monday
      final startOfMonth = DateTime(now.year, now.month, 1);

      double weeklyWeight = 0;
      double monthlyWeight = 0;
      int totalPoints = 0;
      final List<double> weeklyBars = List.filled(7, 0);
      final Map<String, double> catBreakdown = {};
      final List<Map<String, dynamic>> stations = [];

      for (final r in records as List) {
        final date = DateTime.parse(r['date']);
        final weight = (r['weight_kg'] as num).toDouble();
        final points = (r['points'] as num?)?.toInt() ?? 0;
        final category = r['category'] as String;

        totalPoints += points;
        catBreakdown[category] = (catBreakdown[category] ?? 0) + weight;

        if (!date.isBefore(startOfWeek)) {
          weeklyWeight += weight;
          final dayIndex = date.weekday - 1; // 0=Mon
          if (dayIndex >= 0 && dayIndex < 7) {
            weeklyBars[dayIndex] += weight;
          }
        }
        if (!date.isBefore(startOfMonth)) {
          monthlyWeight += weight;
        }
      }

      // CO2 saved: ~2.5 kg CO2 per kg recycled (average)
      final co2 = monthlyWeight * 2.5;

      try {
        final stationRows = await supabase
            .from('recycling_stations')
            .select('name, address, is_open')
            .order('created_at', ascending: false)
            .limit(10);

        for (final row in stationRows as List) {
          final map = Map<String, dynamic>.from(row as Map);
          final name = (map['name'] ?? '').toString().trim();
          if (name.isEmpty) continue;

          stations.add({
            'name': name,
            'distance': (map['address'] ?? '').toString(),
            'open': map['is_open'] == null ? true : map['is_open'] == true,
          });
        }
      } catch (_) {
        // Keep station list empty if table/columns are unavailable.
      }

      final recent = (records as List).take(5).toList();

      if (mounted) {
        setState(() {
          _username = profile['username'] ?? 'User';
          _weeklyWeight = weeklyWeight;
          _monthlyWeight = monthlyWeight;
          _co2Saved = co2;
          _totalPoints = totalPoints;
          _weeklyBarData = weeklyBars;
          _categoryBreakdown = catBreakdown;
          _stations = stations;
          _recentActivity =
              recent.map((e) => Map<String, dynamic>.from(e)).toList();
          _isLoading = false;
        });
        _fadeController.forward();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F6F2),
      body: _isLoading
          ? const Center(
          child: CircularProgressIndicator(color: Color(0xFF2D7A4F)))
          : FadeTransition(
        opacity: _fadeAnim,
        child: RefreshIndicator(
          color: const Color(0xFF2D7A4F),
          onRefresh: _loadData,
          child: CustomScrollView(
            slivers: [
              _buildSliverHeader(),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildOverviewGrid(),
                    const SizedBox(height: 24),
                    _buildAnalyticsSection(),
                    const SizedBox(height: 24),
                    _buildMonthlyGoal(),
                    const SizedBox(height: 24),
                    _buildNearbyStations(),
                    const SizedBox(height: 24),
                    _buildCategoryBreakdown(),
                    const SizedBox(height: 24),
                    _buildRecentActivity(),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context,
              MaterialPageRoute(builder: (_) => const RecycleScreen()));
          _loadData();
        },
        backgroundColor: const Color(0xFF2D7A4F),
        icon: const Icon(Icons.recycling_rounded, color: Colors.white),
        label: Text('Recycle',
            style: GoogleFonts.dmSans(
                color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildSliverHeader() {
    return SliverAppBar(
      expandedHeight: 160,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF1A4731),
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A4731), Color(0xFF2D7A4F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _greeting(),
                              style: GoogleFonts.dmSans(
                                  color: Colors.white60, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _username,
                              style: GoogleFonts.dmSerifDisplay(
                                  color: Colors.white, fontSize: 26),
                            ),
                          ],
                        ),
                      ),
                      // Points badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.star_rounded,
                              color: Color(0xFFFFD700), size: 16),
                          const SizedBox(width: 5),
                          Text('$_totalPoints pts',
                              style: GoogleFonts.dmSans(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13)),
                        ]),
                      ),
                      const SizedBox(width: 10),
                      // Avatar
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFF7EEDB0),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            _username.isNotEmpty
                                ? _username[0].toUpperCase()
                                : 'U',
                            style: GoogleFonts.dmSerifDisplay(
                                color: const Color(0xFF1A4731), fontSize: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      title: Text('Dashboard',
          style: GoogleFonts.dmSans(
              color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
    );
  }

  // â”€â”€ Overview Grid â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildOverviewGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Overview'),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
            child: _overviewCard(
              icon: Icons.recycling_rounded,
              iconColor: const Color(0xFF3DAB6A),
              iconBg: const Color(0xFFDFF5E9),
              label: 'RECYCLED',
              value: '${_weeklyWeight.toStringAsFixed(1)} kg',
              sub: 'This week',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _overviewCard(
              icon: Icons.track_changes_rounded,
              iconColor: const Color(0xFFE8A020),
              iconBg: const Color(0xFFFBF3E3),
              label: 'GOAL',
              value:
              '${(_monthlyWeight / _monthlyGoal * 100).clamp(0, 100).toStringAsFixed(0)}%',
              sub: 'Monthly target',
            ),
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: _overviewCard(
              icon: Icons.co2_outlined,
              iconColor: const Color(0xFF4A90D9),
              iconBg: const Color(0xFFE8F0FA),
              label: 'CO2 SAVED',
              value: '${_co2Saved.toStringAsFixed(1)} kg',
              sub: 'This month',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _overviewCard(
              icon: Icons.location_on_outlined,
              iconColor: const Color(0xFFE05499),
              iconBg: const Color(0xFFFDE8F3),
              label: 'STATIONS',
              value:
              '${_stations.where((s) => s['open'] == true).length} nearby',
              sub: 'Open now',
              valueColor: const Color(0xFFE05499),
            ),
          ),
        ]),
      ],
    );
  }

  Widget _overviewCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required String value,
    required String sub,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
                color: iconBg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(label,
              style: GoogleFonts.dmSans(
                  color: Colors.grey.shade500,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8)),
          const SizedBox(height: 4),
          Text(value,
              style: GoogleFonts.dmSans(
                  color: valueColor ?? const Color(0xFF1A4731),
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          Text(sub,
              style: GoogleFonts.dmSans(
                  color: Colors.grey.shade400, fontSize: 11)),
        ],
      ),
    );
  }

  // â”€â”€ Analytics (Weekly Bar Chart) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildAnalyticsSection() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final maxVal = _weeklyBarData
        .reduce((a, b) => a > b ? a : b)
        .clamp(0.1, double.infinity);
    final todayIndex = DateTime.now().weekday - 1;

    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _sectionTitle('Analytics'),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFDFF5E9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(children: [
                const Icon(Icons.bar_chart_rounded,
                    color: Color(0xFF3DAB6A), size: 14),
                const SizedBox(width: 4),
                Text('Weekly',
                    style: GoogleFonts.dmSans(
                        color: const Color(0xFF3DAB6A),
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ]),
            ),
          ]),
          const SizedBox(height: 4),
          Text('Recycling (kg)',
              style: GoogleFonts.dmSans(
                  color: Colors.grey.shade400, fontSize: 12)),
          const SizedBox(height: 20),
          SizedBox(
            height: 100,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final val = _weeklyBarData[i];
                final heightFactor = (val / maxVal).clamp(0.05, 1.0);
                final isToday = i == todayIndex;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (val > 0)
                          Text(
                            val.toStringAsFixed(1),
                            style: GoogleFonts.dmSans(
                                color: isToday
                                    ? const Color(0xFF2D7A4F)
                                    : Colors.grey.shade400,
                                fontSize: 9,
                                fontWeight: FontWeight.w600),
                          ),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: Duration(milliseconds: 400 + i * 80),
                          curve: Curves.easeOutCubic,
                          height: 80 * heightFactor,
                          decoration: BoxDecoration(
                            color: isToday
                                ? const Color(0xFF2D7A4F)
                                : val > 0
                                ? const Color(0xFF7EEDB0)
                                : Colors.grey.shade100,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6)),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(days[i],
                            style: GoogleFonts.dmSans(
                                color: isToday
                                    ? const Color(0xFF2D7A4F)
                                    : Colors.grey.shade400,
                                fontSize: 10,
                                fontWeight: isToday
                                    ? FontWeight.w700
                                    : FontWeight.w400)),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€ Monthly Goal â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildMonthlyGoal() {
    final progress = (_monthlyWeight / _monthlyGoal).clamp(0.0, 1.0);
    final remaining = (_monthlyGoal - _monthlyWeight).clamp(0, double.infinity);
    final pct = (progress * 100).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A4731), Color(0xFF2D7A4F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF2D7A4F).withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.flag_rounded,
                  color: Color(0xFF7EEDB0), size: 17),
            ),
            const SizedBox(width: 10),
            Text('Monthly Goal',
                style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
            const Spacer(),
            Text('$pct%',
                style: GoogleFonts.dmSans(
                    color: const Color(0xFF7EEDB0),
                    fontSize: 20,
                    fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              valueColor:
              const AlwaysStoppedAnimation<Color>(Color(0xFF7EEDB0)),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${_monthlyWeight.toStringAsFixed(1)} / ${_monthlyGoal.toStringAsFixed(0)} kg recycled  Â·  ${remaining.toStringAsFixed(1)} kg remaining',
            style: GoogleFonts.dmSans(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // â”€â”€ Nearby Stations â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildNearbyStations() {
    if (_stations.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Nearby Stations'),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'No stations available yet.',
              style: GoogleFonts.dmSans(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Nearby Stations'),
        const SizedBox(height: 14),
        ..._stations.take(3).map((s) => _stationTile(s)),
      ],
    );
  }

  Widget _stationTile(Map<String, dynamic> station) {
    final isOpen = station['open'] as bool;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isOpen ? const Color(0xFFDFF5E9) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.location_on_rounded,
              color: isOpen ? const Color(0xFF3DAB6A) : Colors.grey.shade400,
              size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(station['name'],
                  style: GoogleFonts.dmSans(
                      color: const Color(0xFF1A4731),
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(station['distance'],
                  style: GoogleFonts.dmSans(
                      color: Colors.grey.shade400, fontSize: 12)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isOpen ? const Color(0xFFDFF5E9) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            isOpen ? 'Open' : 'Closed',
            style: GoogleFonts.dmSans(
                color: isOpen ? const Color(0xFF3DAB6A) : Colors.grey.shade400,
                fontSize: 11,
                fontWeight: FontWeight.w600),
          ),
        ),
      ]),
    );
  }

  // â”€â”€ Category Breakdown â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildCategoryBreakdown() {
    if (_categoryBreakdown.isEmpty) return const SizedBox.shrink();

    const catColors = {
      'Plastic': Color(0xFF3DAB6A),
      'Paper': Color(0xFF4A90D9),
      'Glass': Color(0xFF9B6FD4),
      'Metal': Color(0xFFE8A020),
    };
    const catBg = {
      'Plastic': Color(0xFFDFF5E9),
      'Paper': Color(0xFFE8F0FA),
      'Glass': Color(0xFFF0EBF9),
      'Metal': Color(0xFFFBF3E3),
    };
    const catIcons = {
      'Plastic': Icons.water_drop_outlined,
      'Paper': Icons.article_outlined,
      'Glass': Icons.wine_bar_outlined,
      'Metal': Icons.hardware_outlined,
    };

    final total = _categoryBreakdown.values.fold(0.0, (sum, v) => sum + v);

    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('By Category'),
          const SizedBox(height: 16),
          ..._categoryBreakdown.entries.map((e) {
            final pct = total > 0 ? e.value / total : 0.0;
            final color = catColors[e.key] ?? const Color(0xFF3DAB6A);
            final bg = catBg[e.key] ?? const Color(0xFFDFF5E9);
            final icon = catIcons[e.key] ?? Icons.recycling_rounded;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                      color: bg, borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: color, size: 17),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text(e.key,
                            style: GoogleFonts.dmSans(
                                color: const Color(0xFF1A4731),
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                        const Spacer(),
                        Text('${e.value.toStringAsFixed(1)} kg',
                            style: GoogleFonts.dmSans(
                                color: color,
                                fontSize: 13,
                                fontWeight: FontWeight.w700)),
                      ]),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 6,
                          backgroundColor: bg,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
            );
          }),
        ],
      ),
    );
  }

  // â”€â”€ Recent Activity â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildRecentActivity() {
    if (_recentActivity.isEmpty) return const SizedBox.shrink();

    const catColors = {
      'Plastic': Color(0xFF3DAB6A),
      'Paper': Color(0xFF4A90D9),
      'Glass': Color(0xFF9B6FD4),
      'Metal': Color(0xFFE8A020),
    };
    const catBg = {
      'Plastic': Color(0xFFDFF5E9),
      'Paper': Color(0xFFE8F0FA),
      'Glass': Color(0xFFF0EBF9),
      'Metal': Color(0xFFFBF3E3),
    };
    const catIcons = {
      'Plastic': Icons.water_drop_outlined,
      'Paper': Icons.article_outlined,
      'Glass': Icons.wine_bar_outlined,
      'Metal': Icons.hardware_outlined,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Recent Activity'),
        const SizedBox(height: 14),
        Container(
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
          child: Column(
            children: _recentActivity.asMap().entries.map((entry) {
              final i = entry.key;
              final r = entry.value;
              final cat = r['category'] as String;
              final weight = (r['weight_kg'] as num).toDouble();
              final points = (r['points'] as num?)?.toInt() ?? 0;
              final date = DateTime.parse(r['date'] as String);
              final dateStr =
                  '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
              final color = catColors[cat] ?? const Color(0xFF3DAB6A);
              final bg = catBg[cat] ?? const Color(0xFFDFF5E9);
              final icon = catIcons[cat] ?? Icons.recycling_rounded;
              final isLast = i == _recentActivity.length - 1;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                            color: bg, borderRadius: BorderRadius.circular(12)),
                        child: Icon(icon, color: color, size: 19),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(cat,
                                style: GoogleFonts.dmSans(
                                    color: const Color(0xFF1A4731),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                            Text(
                              '$dateStr  Â·  ${r['station'] ?? ''}',
                              style: GoogleFonts.dmSans(
                                  color: Colors.grey.shade400, fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${weight.toStringAsFixed(1)} kg',
                              style: GoogleFonts.dmSans(
                                  color: color,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700),
                            ),
                            Row(children: [
                              const Icon(Icons.star_rounded,
                                  color: Color(0xFFFFB800), size: 12),
                              const SizedBox(width: 2),
                              Text('$points pts',
                                  style: GoogleFonts.dmSans(
                                      color: Colors.grey.shade400,
                                      fontSize: 11)),
                            ]),
                          ]),
                    ]),
                  ),
                  if (!isLast)
                    Divider(
                        height: 1,
                        color: Colors.grey.shade100,
                        indent: 16,
                        endIndent: 16),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // â”€â”€ Helper â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _sectionTitle(String title) {
    return Text(title,
        style: GoogleFonts.dmSans(
            color: const Color(0xFF1A4731),
            fontSize: 16,
            fontWeight: FontWeight.w700));
  }
}