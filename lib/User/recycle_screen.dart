import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

// â”€â”€â”€ Data Model â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class RecycleRecord {
  final String id;
  final String userId;
  final String category;
  final double weightKg;
  final String station;
  final int points;
  final DateTime date;
  final DateTime createdAt;

  RecycleRecord({
    required this.id,
    required this.userId,
    required this.category,
    required this.weightKg,
    required this.station,
    required this.points,
    required this.date,
    required this.createdAt,
  });

  factory RecycleRecord.fromMap(Map<String, dynamic> map) {
    return RecycleRecord(
      id: map['id'],
      userId: map['user_id'],
      category: map['category'],
      weightKg: (map['weight_kg'] as num).toDouble(),
      station: map['station'] ?? '',
      points: map['points'] ?? 0,
      date: DateTime.parse(map['date']),
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}

// â”€â”€â”€ Category Config â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class CategoryConfig {
  final String name;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final int pointsPerKg;

  const CategoryConfig({
    required this.name,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.pointsPerKg,
  });
}

const categories = <String, CategoryConfig>{
  'Plastic': CategoryConfig(
    name: 'Plastic',
    icon: Icons.water_drop_outlined,
    color: Color(0xFF3DAB6A),
    bgColor: Color(0xFFE8F5EE),
    pointsPerKg: 10,
  ),
  'Paper': CategoryConfig(
    name: 'Paper',
    icon: Icons.article_outlined,
    color: Color(0xFF4A90D9),
    bgColor: Color(0xFFE8F0FA),
    pointsPerKg: 8,
  ),
  'Glass': CategoryConfig(
    name: 'Glass',
    icon: Icons.wine_bar_outlined,
    color: Color(0xFF9B6FD4),
    bgColor: Color(0xFFF0EBF9),
    pointsPerKg: 12,
  ),
  'Metal': CategoryConfig(
    name: 'Metal',
    icon: Icons.hardware_outlined,
    color: Color(0xFFE8A020),
    bgColor: Color(0xFFFBF3E3),
    pointsPerKg: 15,
  ),
};

const recyclingStations = [
  'EcoPoint Melaka Central',
  'EcoPoint Bukit Beruang',
  'EcoPoint Ayer Keroh',
  'EcoPoint Banda Hilir',
  'EcoPoint Cheng',
  'EcoPoint Bachang',
];

// â”€â”€â”€ Main Screen â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class RecycleScreen extends StatefulWidget {
  const RecycleScreen({super.key});

  @override
  State<RecycleScreen> createState() => _RecycleScreenState();
}

class _RecycleScreenState extends State<RecycleScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<RecycleRecord> _records = [];
  bool _isLoading = true;

  // Stats
  double get _totalWeight => _records.fold(0, (sum, r) => sum + r.weightKg);
  int get _totalPoints => _records.fold(0, (sum, r) => sum + r.points);

  Map<String, double> get _categoryWeights {
    final map = <String, double>{};
    for (final r in _records) {
      map[r.category] = (map[r.category] ?? 0) + r.weightKg;
    }
    return map;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRecords();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;
      final data = await supabase
          .from('recycle_records')
          .select()
          .eq('user_id', user.id)
          .order('date', ascending: false);
      if (mounted) {
        setState(() {
          _records =
              (data as List).map((e) => RecycleRecord.fromMap(e)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteRecord(String id) async {
    try {
      await supabase.from('recycle_records').delete().eq('id', id);
      await _loadRecords();
      if (mounted) {
        _showSnack('Record deleted', isError: false);
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Delete failed. Please try again.', isError: true);
      }
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.dmSans(color: Colors.white)),
      backgroundColor:
          isError ? const Color(0xFFE05454) : const Color(0xFF3DAB6A),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  void _openAddSheet({RecycleRecord? editing}) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddRecordSheet(editing: editing),
    );
    if (result == true) await _loadRecords();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F5),
      body: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF3DAB6A)))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAddTab(),
                      _buildHistoryTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
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
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: back button + app name + points badge + avatar
              Row(
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 1),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.eco_rounded,
                        color: Color(0xFF7EEDB0), size: 18),
                  ),
                  const SizedBox(width: 8),
                  Text('GreenTrack',
                      style: GoogleFonts.dmSerifDisplay(
                          color: Colors.white, fontSize: 18)),
                  const Spacer(),
                  // Points badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.star_rounded,
                          color: Color(0xFFFFD700), size: 15),
                      const SizedBox(width: 5),
                      Text('$_totalPoints pts',
                          style: GoogleFonts.dmSans(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12)),
                    ]),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Title + subtitle
              Text('Recycle',
                  style: GoogleFonts.dmSerifDisplay(
                      color: Colors.white, fontSize: 26)),
              const SizedBox(height: 2),
              Text('Track your recycling records',
                  style:
                      GoogleFonts.dmSans(color: Colors.white60, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: const Color(0xFF2D7A4F),
      child: TabBar(
        controller: _tabController,
        indicatorColor: const Color(0xFF7EEDB0),
        indicatorWeight: 2.5,
        labelColor: const Color(0xFF7EEDB0),
        unselectedLabelColor: Colors.white.withValues(alpha: 0.5),
        labelStyle:
            GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.dmSans(fontSize: 13),
        tabs: const [
          Tab(text: 'ADD / SUBMIT'),
          Tab(text: 'HISTORY'),
        ],
      ),
    );
  }

  // â”€â”€ Tab 1: Add Record (inline form) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildAddTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: _InlineAddForm(onSuccess: _loadRecords),
    );
  }

  // â”€â”€ Tab 2: History â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildHistoryTab() {
    if (_records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.recycling_rounded,
                size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('No records yet',
                style: GoogleFonts.dmSans(
                    color: Colors.grey.shade400, fontSize: 16)),
            const SizedBox(height: 8),
            Text('Go to the ADD page to submit your first record!',
                style: GoogleFonts.dmSans(
                    color: Colors.grey.shade400, fontSize: 13)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF3DAB6A),
      onRefresh: _loadRecords,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Category breakdown
          if (_categoryWeights.isNotEmpty) ...[
            _buildCategoryBreakdown(),
            const SizedBox(height: 20),
          ],
          Text('Record History',
              style: GoogleFonts.dmSans(
                  color: const Color(0xFF1A4731),
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ..._records.map((r) => _RecordCard(
                record: r,
                onEdit: () => _openAddSheet(editing: r),
                onDelete: () => _showDeleteDialog(r.id),
              )),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('By Category',
              style: GoogleFonts.dmSans(
                  color: const Color(0xFF1A4731),
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ..._categoryWeights.entries.map((e) {
            final cfg = categories[e.key]!;
            final pct = _totalWeight > 0 ? e.value / _totalWeight : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                children: [
                  Row(children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                          color: cfg.bgColor,
                          borderRadius: BorderRadius.circular(8)),
                      child: Icon(cfg.icon, color: cfg.color, size: 14),
                    ),
                    const SizedBox(width: 10),
                    Text(cfg.name,
                        style: GoogleFonts.dmSans(
                            color: const Color(0xFF333333),
                            fontSize: 13,
                            fontWeight: FontWeight.w500)),
                    const Spacer(),
                    Text('${e.value.toStringAsFixed(1)} kg',
                        style: GoogleFonts.dmSans(
                            color: cfg.color,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ]),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 5,
                      backgroundColor: cfg.bgColor,
                      valueColor: AlwaysStoppedAnimation<Color>(cfg.color),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showDeleteDialog(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Delete Record',
            style: GoogleFonts.dmSans(
                color: const Color(0xFF1A4731), fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to delete this recycling record?',
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
              _deleteRecord(id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE05454),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text('Delete',
                style: GoogleFonts.dmSans(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// â”€â”€â”€ Inline Add Form (Tab 1) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _InlineAddForm extends StatefulWidget {
  final Future<void> Function() onSuccess;
  const _InlineAddForm({required this.onSuccess});

  @override
  State<_InlineAddForm> createState() => _InlineAddFormState();
}

class _InlineAddFormState extends State<_InlineAddForm> {
  final _weightController = TextEditingController();
  String _selectedCategory = 'Plastic';
  String _selectedStation = recyclingStations.first;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  int get _calculatedPoints => ((double.tryParse(_weightController.text) ?? 0) *
          (categories[_selectedCategory]?.pointsPerKg ?? 10))
      .round();

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final weight = double.tryParse(_weightController.text.trim());
    if (weight == null || weight <= 0) {
      _showSnack('Please enter a valid weight', isError: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;
      final pts =
          (weight * (categories[_selectedCategory]!.pointsPerKg)).round();
      await supabase.from('recycle_records').insert({
        'user_id': user.id,
        'category': _selectedCategory,
        'weight_kg': weight,
        'station': _selectedStation,
        'points': pts,
        'date': _selectedDate.toIso8601String().substring(0, 10),
      });
      _weightController.clear();
      setState(() => _selectedCategory = 'Plastic');
      await widget.onSuccess();
      if (mounted) {
        _showSnack('Record submitted! You earned $pts points!', isError: false);
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Submission failed. Please try again.', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.dmSans(color: Colors.white)),
      backgroundColor:
          isError ? const Color(0xFFE05454) : const Color(0xFF3DAB6A),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 4))
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
                gradient: const LinearGradient(
                    colors: [Color(0xFF4CD787), Color(0xFF2D7A4F)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Text('Add New Record',
                style: GoogleFonts.dmSans(
                    color: const Color(0xFF1A4731),
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
          ]),

          const SizedBox(height: 24),

          // Category
          Text('CATEGORY',
              style: GoogleFonts.dmSans(
                  color: const Color(0xFF888888),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: categories.keys.map((cat) {
              final cfg = categories[cat]!;
              final selected = _selectedCategory == cat;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? cfg.color : cfg.bgColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? cfg.color : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(cfg.icon,
                        color: selected ? Colors.white : cfg.color, size: 16),
                    const SizedBox(width: 6),
                    Text(cat,
                        style: GoogleFonts.dmSans(
                            color: selected ? Colors.white : cfg.color,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                  ]),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // Weight
          Text('WEIGHT (KG)',
              style: GoogleFonts.dmSans(
                  color: const Color(0xFF888888),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8)),
          const SizedBox(height: 8),
          TextField(
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            style: GoogleFonts.dmSans(
                color: const Color(0xFF1A4731),
                fontSize: 15,
                fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: '0.0',
              hintStyle: GoogleFonts.dmSans(color: Colors.grey.shade300),
              filled: true,
              fillColor: const Color(0xFFF7F9F8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFF3DAB6A), width: 1.5),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              suffixText: 'kg',
              suffixStyle:
                  GoogleFonts.dmSans(color: Colors.grey.shade400, fontSize: 14),
            ),
          ),

          const SizedBox(height: 20),

          // Station
          Text('RECYCLING STATION',
              style: GoogleFonts.dmSans(
                  color: const Color(0xFF888888),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9F8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200, width: 1.5),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedStation,
                isExpanded: true,
                style: GoogleFonts.dmSans(
                    color: const Color(0xFF1A4731),
                    fontSize: 14,
                    fontWeight: FontWeight.w500),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(12),
                items: recyclingStations
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedStation = v!),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Date picker
          Text('DATE',
              style: GoogleFonts.dmSans(
                  color: const Color(0xFF888888),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                builder: (ctx, child) => Theme(
                  data: ThemeData(
                    colorScheme: const ColorScheme.light(
                      primary: Color(0xFF3DAB6A),
                      onPrimary: Colors.white,
                    ),
                  ),
                  child: child!,
                ),
              );
              if (picked != null) setState(() => _selectedDate = picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F9F8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200, width: 1.5),
              ),
              child: Row(children: [
                Icon(Icons.calendar_today_outlined,
                    color: Colors.grey.shade400, size: 18),
                const SizedBox(width: 10),
                Text(
                  '${_selectedDate.year}-'
                  '${_selectedDate.month.toString().padLeft(2, '0')}-'
                  '${_selectedDate.day.toString().padLeft(2, '0')}',
                  style: GoogleFonts.dmSans(
                      color: const Color(0xFF1A4731),
                      fontSize: 14,
                      fontWeight: FontWeight.w500),
                ),
              ]),
            ),
          ),

          // Points preview
          if (_weightController.text.isNotEmpty &&
              double.tryParse(_weightController.text) != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FAF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFB8E8CC), width: 1.5),
              ),
              child: Row(children: [
                const Icon(Icons.star_rounded,
                    color: Color(0xFFFFB800), size: 20),
                const SizedBox(width: 8),
                Text('You will earn ',
                    style: GoogleFonts.dmSans(
                        color: Colors.grey.shade600, fontSize: 13)),
                Text('$_calculatedPoints points',
                    style: GoogleFonts.dmSans(
                        color: const Color(0xFF2D7A4F),
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
                const Spacer(),
                Text(
                  '${categories[_selectedCategory]!.pointsPerKg} pts/kg',
                  style: GoogleFonts.dmSans(
                      color: Colors.grey.shade400, fontSize: 12),
                ),
              ]),
            ),
          ],

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D7A4F),
                disabledBackgroundColor:
                    const Color(0xFF2D7A4F).withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : Text('Submit Record',
                      style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€â”€ Record Card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _RecordCard extends StatelessWidget {
  final RecycleRecord record;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RecordCard({
    required this.record,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cfg = categories[record.category] ?? categories['Plastic']!;
    final dateStr =
        '${record.date.year}-${record.date.month.toString().padLeft(2, '0')}-${record.date.day.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Row(children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
              color: cfg.bgColor, borderRadius: BorderRadius.circular(14)),
          child: Icon(cfg.icon, color: cfg.color, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(record.category,
                  style: GoogleFonts.dmSans(
                      color: const Color(0xFF1A4731),
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text('$dateStr  Â·  ${record.station}',
                  style: GoogleFonts.dmSans(
                      color: Colors.grey.shade500, fontSize: 11),
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${record.weightKg.toStringAsFixed(1)} kg',
              style: GoogleFonts.dmSans(
                  color: cfg.color, fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Row(children: [
            const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 12),
            const SizedBox(width: 2),
            Text('${record.points} pts',
                style: GoogleFonts.dmSans(
                    color: Colors.grey.shade400, fontSize: 11)),
          ]),
        ]),
        const SizedBox(width: 10),
        Column(children: [
          GestureDetector(
            onTap: onEdit,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                  color: const Color(0xFFF0FAF4),
                  borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.edit_outlined,
                  color: Color(0xFF3DAB6A), size: 15),
            ),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: onDelete,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F0),
                  borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.delete_outline,
                  color: Color(0xFFE05454), size: 15),
            ),
          ),
        ]),
      ]),
    );
  }
}

// â”€â”€â”€ Edit Sheet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _AddRecordSheet extends StatefulWidget {
  final RecycleRecord? editing;
  const _AddRecordSheet({this.editing});

  @override
  State<_AddRecordSheet> createState() => _AddRecordSheetState();
}

class _AddRecordSheetState extends State<_AddRecordSheet> {
  late TextEditingController _weightController;
  late String _selectedCategory;
  late String _selectedStation;
  late DateTime _selectedDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    _weightController =
        TextEditingController(text: e != null ? e.weightKg.toString() : '');
    _selectedCategory = e?.category ?? 'Plastic';
    _selectedStation = e?.station ?? recyclingStations.first;
    _selectedDate = e?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final weight = double.tryParse(_weightController.text.trim());
    if (weight == null || weight <= 0) return;
    setState(() => _isLoading = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;
      final pts = (weight * categories[_selectedCategory]!.pointsPerKg).round();
      if (widget.editing != null) {
        await supabase.from('recycle_records').update({
          'category': _selectedCategory,
          'weight_kg': weight,
          'station': _selectedStation,
          'points': pts,
          'date': _selectedDate.toIso8601String().substring(0, 10),
        }).eq('id', widget.editing!.id);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) Navigator.pop(context, false);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 24),
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
          Text('Edit Record',
              style: GoogleFonts.dmSans(
                  color: const Color(0xFF1A4731),
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          // Category
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categories.keys.map((cat) {
              final cfg = categories[cat]!;
              final selected = _selectedCategory == cat;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? cfg.color : cfg.bgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(cfg.icon,
                        color: selected ? Colors.white : cfg.color, size: 14),
                    const SizedBox(width: 5),
                    Text(cat,
                        style: GoogleFonts.dmSans(
                            color: selected ? Colors.white : cfg.color,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ]),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          // Weight
          TextField(
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.dmSans(color: const Color(0xFF1A4731)),
            decoration: InputDecoration(
              labelText: 'Weight (kg)',
              labelStyle: GoogleFonts.dmSans(color: Colors.grey),
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
            ),
          ),
          const SizedBox(height: 16),
          // Station dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9F8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200, width: 1.5),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedStation,
                isExpanded: true,
                style: GoogleFonts.dmSans(
                    color: const Color(0xFF1A4731), fontSize: 14),
                dropdownColor: Colors.white,
                items: recyclingStations
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedStation = v!),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D7A4F),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : Text('Save Changes',
                      style: GoogleFonts.dmSans(
                          color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
