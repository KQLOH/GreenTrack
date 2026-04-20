import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/supabase_client.dart';

class ImpactHistoryScreen extends StatefulWidget {
  const ImpactHistoryScreen({super.key});

  @override
  State<ImpactHistoryScreen> createState() => _ImpactHistoryScreenState();
}

class _ImpactHistoryScreenState extends State<ImpactHistoryScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _records = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);

    try {
      final userId = supabaseClient.auth.currentUser?.id;

      final data = await supabaseClient
          .from('recycle_records')
          .select()
          .eq('user_id', userId!)
          .eq('status', 'approved')
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        _records = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  double get _totalWeight {
    return _records.fold<double>(
      0,
          (sum, r) => sum + ((r['weight_kg'] as num?)?.toDouble() ?? 0),
    );
  }

  int get _totalPoints {
    return _records.fold<int>(
      0,
          (sum, r) => sum + ((r['points'] as num?)?.toInt() ?? 0),
    );
  }

  Map<String, dynamic> _categoryStyle(String category) {
    switch (category.toLowerCase()) {
      case 'plastic':
        return {
          'icon': Icons.local_drink_outlined,
          'color': const Color(0xFF3DAB6A),
          'bg': const Color(0xFFE8F5EE),
        };
      case 'paper':
        return {
          'icon': Icons.description_outlined,
          'color': const Color(0xFF4A90D9),
          'bg': const Color(0xFFE8F0FA),
        };
      case 'glass':
        return {
          'icon': Icons.wine_bar_outlined,
          'color': const Color(0xFF9B6FD4),
          'bg': const Color(0xFFF1EAFE),
        };
      case 'metal':
        return {
          'icon': Icons.settings_outlined,
          'color': const Color(0xFFE8A020),
          'bg': const Color(0xFFFFF4DD),
        };
      default:
        return {
          'icon': Icons.recycling_rounded,
          'color': const Color(0xFF2D7A4F),
          'bg': const Color(0xFFE8F5EE),
        };
    }
  }

  String _formatDate(String raw) {
    final dt = DateTime.tryParse(raw)?.toLocal();
    if (dt == null) return '-';
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F6F2),
      body: CustomScrollView(
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
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                                borderRadius: BorderRadius.circular(12),
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
                            'Impact History',
                            style: GoogleFonts.dmSans(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: _loadHistory,
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                ),
                              ),
                              child: const Icon(
                                Icons.refresh_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'Your Recycling Journey',
                        style: GoogleFonts.dmSerifDisplay(
                          color: Colors.white,
                          fontSize: 26,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Track your approved recycling contributions and environmental impact.',
                        style: GoogleFonts.dmSans(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -14),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    height: 64,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2D7A4F),
                      ),
                    ),
                  )
                      : Row(
                    children: [
                      _summaryItem(
                        value: _totalWeight.toStringAsFixed(1),
                        label: 'KG Recycled',
                      ),
                      _summaryDivider(),
                      _summaryItem(
                        value: _totalPoints.toString(),
                        label: 'Points Earned',
                      ),
                      _summaryDivider(),
                      _summaryItem(
                        value: _records.length.toString(),
                        label: 'Approved Records',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          if (_isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF2D7A4F),
                ),
              ),
            )
          else if (_records.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 86,
                        height: 86,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5EE),
                          borderRadius: BorderRadius.circular(26),
                        ),
                        child: const Icon(
                          Icons.history_rounded,
                          color: Color(0xFF3DAB6A),
                          size: 42,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'No approved history yet',
                        style: GoogleFonts.dmSans(
                          color: const Color(0xFF1A4731),
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Approved recycling records will appear here once your submissions are verified.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(
                          color: Colors.grey.shade500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, i) {
                    final r = _records[i];
                    final category = (r['category'] ?? 'Unknown').toString();
                    final station = (r['station'] ?? 'Unknown station').toString();
                    final weight = (r['weight_kg'] as num?)?.toDouble() ?? 0;
                    final points = (r['points'] as num?)?.toInt() ?? 0;
                    final createdAt = _formatDate(
                      (r['created_at'] ?? '').toString(),
                    );

                    final style = _categoryStyle(category);
                    final icon = style['icon'] as IconData;
                    final color = style['color'] as Color;
                    final bg = style['bg'] as Color;
                    final isLast = i == _records.length - 1;

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withOpacity(0.25),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                            if (!isLast)
                              Container(
                                width: 2,
                                height: 110,
                                color: const Color(0xFFDDEADF),
                              ),
                          ],
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(16),
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: bg,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(icon, color: color, size: 24),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              category,
                                              style: GoogleFonts.dmSans(
                                                color: const Color(0xFF1A4731),
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFE8F5EE),
                                              borderRadius:
                                              BorderRadius.circular(10),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.check_circle_rounded,
                                                  color: Color(0xFF3DAB6A),
                                                  size: 12,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Approved',
                                                  style: GoogleFonts.dmSans(
                                                    color:
                                                    const Color(0xFF3DAB6A),
                                                    fontSize: 11,
                                                    fontWeight:
                                                    FontWeight.w700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.location_on_outlined,
                                            size: 14,
                                            color: Colors.grey.shade400,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              station,
                                              style: GoogleFonts.dmSans(
                                                color: Colors.grey.shade600,
                                                fontSize: 12,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.schedule_rounded,
                                            size: 14,
                                            color: Colors.grey.shade400,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            createdAt,
                                            style: GoogleFonts.dmSans(
                                              color: Colors.grey.shade500,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: bg,
                                              borderRadius:
                                              BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              '${weight.toStringAsFixed(1)} kg',
                                              style: GoogleFonts.dmSans(
                                                color: color,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFFF4DD),
                                              borderRadius:
                                              BorderRadius.circular(10),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.star_rounded,
                                                  color: Color(0xFFE8A020),
                                                  size: 13,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '+$points pts',
                                                  style: GoogleFonts.dmSans(
                                                    color:
                                                    const Color(0xFFE8A020),
                                                    fontSize: 12,
                                                    fontWeight:
                                                    FontWeight.w700,
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
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                  childCount: _records.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _summaryItem({
    required String value,
    required String label,
  }) {
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
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              color: Colors.grey.shade500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryDivider() {
    return Container(
      width: 1,
      height: 42,
      color: Colors.grey.shade200,
    );
  }
}