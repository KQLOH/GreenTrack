import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import '../services/supabase_client.dart';

final supabase = supabaseClient;

class RecycleRecord {
  final String id;
  final String userId;
  final String category;
  final double weightKg;
  final String station;
  final int points;
  final DateTime date;
  final DateTime createdAt;
  final String status;
  final double? locationLat;
  final double? locationLng;
  final DateTime? approvedAt;
  final String? rejectionReason;

  RecycleRecord({
    required this.id,
    required this.userId,
    required this.category,
    required this.weightKg,
    required this.station,
    required this.points,
    required this.date,
    required this.createdAt,
    this.status = 'pending',
    this.locationLat,
    this.locationLng,
    this.approvedAt,
    this.rejectionReason,
  });

  factory RecycleRecord.fromMap(Map<String, dynamic> map) {
    return RecycleRecord(
      id: map['id'].toString(),
      userId: map['user_id'].toString(),
      category: map['category'].toString(),
      weightKg: (map['weight_kg'] as num).toDouble(),
      station: (map['station'] ?? '').toString(),
      points: (map['points'] ?? 0) as int,
      date: DateTime.parse(map['date'].toString()),
      createdAt: DateTime.parse(map['created_at'].toString()),
      status: (map['status'] ?? 'pending').toString(),
      locationLat: (map['location_lat'] as num?)?.toDouble(),
      locationLng: (map['location_lng'] as num?)?.toDouble(),
      approvedAt: map['approved_at'] != null
          ? DateTime.parse(map['approved_at'].toString())
          : null,
      rejectionReason: map['rejection_reason']?.toString(),
    );
  }
}

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

const Map<String, Map<String, double>> stationCoordinates = {
  'EcoPoint Melaka Central': {
    'lat': 3.201320,
    'lng': 101.716046,
  },
  'EcoPoint Bukit Beruang': {
    'lat': 2.2448,
    'lng': 102.2787,
  },
  'EcoPoint Ayer Keroh': {
    'lat': 2.2707,
    'lng': 102.2876,
  },
  'EcoPoint Banda Hilir': {
    'lat': 2.1896,
    'lng': 102.2497,
  },
  'EcoPoint Cheng': {
    'lat': 2.2483,
    'lng': 102.2205,
  },
  'EcoPoint Bachang': {
    'lat': 2.2256,
    'lng': 102.2329,
  },
};

const double allowedDistanceInMeters = 1000.0;

class RecycleScreen extends StatefulWidget {
  const RecycleScreen({super.key});

  @override
  State<RecycleScreen> createState() => _RecycleScreenState();
}

class _RecycleScreenState extends State<RecycleScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<RecycleRecord> _records = [];
  List<String> _stations = List<String>.from(recyclingStations);
  Map<String, Map<String, double>> _stationCoordinates =
      Map<String, Map<String, double>>.from(stationCoordinates);
  bool _isLoading = true;

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
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && _tabController.index == 0) {
        _loadStations();
      }
    });
    _loadRecords();
    _loadStations();
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
      if (user == null) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

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
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnack('Failed to load records.', isError: true);
      }
    }
  }

  double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Future<void> _loadStations() async {
    try {
      final data = await supabase
          .from('recycling_stations')
          .select()
          .order('name', ascending: true);

      final rows = List<Map<String, dynamic>>.from(data as List);
      final names = <String>[];
      final coords = <String, Map<String, double>>{};

      for (final row in rows) {
        // Admin toggles station availability via is_open.
        if (row['is_open'] == false) continue;

        // Treat missing is_active as active for backward compatibility.
        if (row['is_active'] == false) continue;

        final name = (row['name'] ?? '').toString().trim();
        if (name.isEmpty) continue;

        final lat = _toDouble(row['latitude']) ??
            _toDouble(row['location_lat']) ??
            _toDouble(row['lat']);
        final lng = _toDouble(row['longitude']) ??
            _toDouble(row['location_lng']) ??
            _toDouble(row['lng']);

        names.add(name);
        if (lat != null && lng != null) {
          coords[name] = {'lat': lat, 'lng': lng};
        }
      }

      if (!mounted) return;

      setState(() {
        if (names.isEmpty) {
          _stations = <String>[];
          _stationCoordinates = <String, Map<String, double>>{};
        } else {
          _stations = names;
          _stationCoordinates = coords;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _stations = <String>[];
        _stationCoordinates = <String, Map<String, double>>{};
      });
    }
  }

  Future<void> _deleteRecord(String id) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      await supabase
          .from('recycle_records')
          .delete()
          .eq('id', id)
          .eq('user_id', user.id);

      await _loadRecords();

      if (mounted) {
        _showSnack('Record deleted', isError: false);
      }
    } catch (_) {
      if (mounted) {
        _showSnack('Delete failed. Please try again.', isError: true);
      }
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.dmSans(color: Colors.white),
        ),
        backgroundColor:
            isError ? const Color(0xFFE05454) : const Color(0xFF3DAB6A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _openAddSheet({RecycleRecord? editing}) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddRecordSheet(
        editing: editing,
        stations: _stations,
      ),
    );

    if (result == true) {
      await _loadRecords();
      await _loadStations();
    }
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
                    child: CircularProgressIndicator(
                      color: Color(0xFF3DAB6A),
                    ),
                  )
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
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.eco_rounded,
                      color: Color(0xFF7EEDB0),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'GreenTrack',
                    style: GoogleFonts.dmSerifDisplay(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFFD700),
                          size: 15,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '$_totalPoints pts',
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Recycle',
                style: GoogleFonts.dmSerifDisplay(
                  color: Colors.white,
                  fontSize: 26,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Track your recycling records',
                style: GoogleFonts.dmSans(
                  color: Colors.white60,
                  fontSize: 12,
                ),
              ),
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
        unselectedLabelColor: Colors.white.withOpacity(0.5),
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

  Widget _buildAddTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: _InlineAddForm(
        onSuccess: _loadRecords,
        stations: _stations,
        stationCoordinates: _stationCoordinates,
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.recycling_rounded,
                size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No records yet',
              style: GoogleFonts.dmSans(
                color: Colors.grey.shade400,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Go to the ADD page to submit your first record!',
              style: GoogleFonts.dmSans(
                color: Colors.grey.shade400,
                fontSize: 13,
              ),
            ),
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
          if (_categoryWeights.isNotEmpty) ...[
            _buildCategoryBreakdown(),
            const SizedBox(height: 20),
          ],
          Text(
            'Record History',
            style: GoogleFonts.dmSans(
              color: const Color(0xFF1A4731),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ..._records.map(
            (r) => _RecordCard(
              record: r,
              canManage: r.status.toLowerCase() == 'pending',
              onEdit: () => _openAddSheet(editing: r),
              onDelete: () => _showDeleteDialog(r.id),
            ),
          ),
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
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'By Category',
            style: GoogleFonts.dmSans(
              color: const Color(0xFF1A4731),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ..._categoryWeights.entries.map((e) {
            final cfg = categories[e.key]!;
            final pct = _totalWeight > 0 ? e.value / _totalWeight : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: cfg.bgColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(cfg.icon, color: cfg.color, size: 14),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        cfg.name,
                        style: GoogleFonts.dmSans(
                          color: const Color(0xFF333333),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${e.value.toStringAsFixed(1)} kg',
                        style: GoogleFonts.dmSans(
                          color: cfg.color,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
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
        title: Text(
          'Delete Record',
          style: GoogleFonts.dmSans(
            color: const Color(0xFF1A4731),
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this recycling record?',
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
              _deleteRecord(id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE05454),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: Text(
              'Delete',
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

class _InlineAddForm extends StatefulWidget {
  final Future<void> Function() onSuccess;
  final List<String> stations;
  final Map<String, Map<String, double>> stationCoordinates;

  const _InlineAddForm({
    required this.onSuccess,
    required this.stations,
    required this.stationCoordinates,
  });

  @override
  State<_InlineAddForm> createState() => _InlineAddFormState();
}

class _InlineAddFormState extends State<_InlineAddForm> {
  final _weightController = TextEditingController();

  String _selectedCategory = 'Plastic';
  String _selectedStation = '';
  DateTime _selectedDate = DateTime.now();

  bool _isLoading = false;
  bool _isCheckingLocation = false;
  bool _isLocationValid = false;

  double? _currentLat;
  double? _currentLng;

  String _locationStatus = 'Checking location...';

  int get _calculatedPoints => ((double.tryParse(_weightController.text) ?? 0) *
          (categories[_selectedCategory]?.pointsPerKg ?? 10))
      .round();

  @override
  void initState() {
    super.initState();
    _selectedStation = widget.stations.isNotEmpty ? widget.stations.first : '';
    _checkLocation();
  }

  @override
  void didUpdateWidget(covariant _InlineAddForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.stations.isEmpty) {
      if (_selectedStation.isNotEmpty) {
        setState(() {
          _selectedStation = '';
          _isLocationValid = false;
          _locationStatus = 'No station available';
        });
      }
      return;
    }

    if (!widget.stations.contains(_selectedStation)) {
      setState(() {
        _selectedStation = widget.stations.first;
      });
      if (_currentLat != null && _currentLng != null) {
        _validateAgainstSelectedStation();
      }
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _checkLocation() async {
    setState(() {
      _isCheckingLocation = true;
      _locationStatus = 'Checking location...';
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLocationValid = false;
          _locationStatus = 'Location service is disabled';
          _isCheckingLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        setState(() {
          _isLocationValid = false;
          _locationStatus = 'Location permission denied';
          _isCheckingLocation = false;
        });
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLocationValid = false;
          _locationStatus = 'Location permission denied forever';
          _isCheckingLocation = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _currentLat = position.latitude;
      _currentLng = position.longitude;

      // 自动选最近的 station
      final sorted = _stationsSortedByDistance;
      if (sorted.isNotEmpty && widget.stations.contains(sorted.first)) {
        _selectedStation = sorted.first;
      }

      _validateAgainstSelectedStation();
    } catch (_) {
      setState(() {
        _isLocationValid = false;
        _locationStatus = 'Failed to get current location';
        _isCheckingLocation = false;
      });
    }
  }

  void _validateAgainstSelectedStation() {
    final station = widget.stationCoordinates[_selectedStation];

    if (station == null || _currentLat == null || _currentLng == null) {
      setState(() {
        _isLocationValid = false;
        _locationStatus = 'Station location not available';
        _isCheckingLocation = false;
      });
      return;
    }

    final distance = Geolocator.distanceBetween(
      _currentLat!,
      _currentLng!,
      station['lat']!,
      station['lng']!,
    );

    setState(() {
      _isLocationValid = distance <= allowedDistanceInMeters;
      _locationStatus = _isLocationValid
          ? 'Location verified (${distance.toStringAsFixed(0)}m from station)'
          : 'You are too far from $_selectedStation (${distance.toStringAsFixed(0)}m)';
      _isCheckingLocation = false;
    });
  }

  double? _distanceTo(String stationName) {
    if (_currentLat == null || _currentLng == null) return null;
    final coords = widget.stationCoordinates[stationName];
    if (coords == null) return null;
    return Geolocator.distanceBetween(
      _currentLat!,
      _currentLng!,
      coords['lat']!,
      coords['lng']!,
    );
  }

  List<String> get _stationsSortedByDistance {
    final sorted = List<String>.from(widget.stations);
    if (_currentLat != null && _currentLng != null) {
      sorted.sort((a, b) {
        final da = _distanceTo(a) ?? double.infinity;
        final db = _distanceTo(b) ?? double.infinity;
        return da.compareTo(db);
      });
    }
    return sorted;
  }

  String _formatDistance(double? meters) {
    if (meters == null) return '';
    if (meters >= 1000) return '${(meters / 1000).toStringAsFixed(1)} km';
    return '${meters.toStringAsFixed(0)} m';
  }

  Future<void> _submit() async {
    if (_selectedStation.isEmpty) {
      _showSnack('No station available yet. Please try again shortly.',
          isError: true);
      return;
    }

    if (!_isLocationValid) {
      _showSnack(
        'You must be near the selected recycling station to submit',
        isError: true,
      );
      return;
    }

    final weight = double.tryParse(_weightController.text.trim());
    if (weight == null || weight <= 0) {
      _showSnack('Please enter a valid weight', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        _showSnack('User not logged in', isError: true);
        return;
      }

      await supabase.from('recycle_records').insert({
        'user_id': user.id,
        'category': _selectedCategory,
        'weight_kg': weight,
        'station': _selectedStation,
        'points': 0,
        'status': 'pending',
        'location_lat': _currentLat,
        'location_lng': _currentLng,
        'date': _selectedDate.toIso8601String().substring(0, 10),
      });

      _weightController.clear();
      setState(() {
        _selectedCategory = 'Plastic';
        _selectedStation =
            widget.stations.isNotEmpty ? widget.stations.first : '';
        _selectedDate = DateTime.now();
      });

      await widget.onSuccess();

      if (mounted) {
        _showSnack(
          'Record submitted for review! Pending admin approval.',
          isError: false,
        );
        _checkLocation();
      }
    } catch (_) {
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.dmSans(color: Colors.white),
        ),
        backgroundColor:
            isError ? const Color(0xFFE05454) : const Color(0xFF3DAB6A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
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
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4CD787), Color(0xFF2D7A4F)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Add New Record',
                style: GoogleFonts.dmSans(
                  color: const Color(0xFF1A4731),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'CATEGORY',
            style: GoogleFonts.dmSans(
              color: const Color(0xFF888888),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        cfg.icon,
                        color: selected ? Colors.white : cfg.color,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        cat,
                        style: GoogleFonts.dmSans(
                          color: selected ? Colors.white : cfg.color,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Text(
            'WEIGHT (KG)',
            style: GoogleFonts.dmSans(
              color: const Color(0xFF888888),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            style: GoogleFonts.dmSans(
              color: const Color(0xFF1A4731),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
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
          Text(
            'RECYCLING STATION',
            style: GoogleFonts.dmSans(
              color: const Color(0xFF888888),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
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
                value: widget.stations.contains(_selectedStation)
                    ? _selectedStation
                    : null,
                isExpanded: true,
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(12),
                hint: Text(
                  'No station available',
                  style: GoogleFonts.dmSans(
                    color: Colors.grey.shade500,
                    fontSize: 13,
                  ),
                ),
                selectedItemBuilder: (context) =>
                    _stationsSortedByDistance.map((s) {
                  final dist = _distanceTo(s);
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            s,
                            style: GoogleFonts.dmSans(
                              color: const Color(0xFF1A4731),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (dist != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            _formatDistance(dist),
                            style: GoogleFonts.dmSans(
                              color: Colors.grey.shade400,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
                items: _stationsSortedByDistance.map((s) {
                  final dist = _distanceTo(s);
                  final isNearest = _stationsSortedByDistance.isNotEmpty &&
                      s == _stationsSortedByDistance.first &&
                      _currentLat != null;
                  return DropdownMenuItem<String>(
                    value: s,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      s,
                                      style: GoogleFonts.dmSans(
                                        color: const Color(0xFF1A4731),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isNearest) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE8F5EE),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Nearest',
                                        style: GoogleFonts.dmSans(
                                          color: const Color(0xFF3DAB6A),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              if (dist != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  _formatDistance(dist),
                                  style: GoogleFonts.dmSans(
                                    color: Colors.grey.shade400,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: widget.stations.isEmpty
                    ? null
                    : (v) {
                        if (v == null) return;
                        setState(() => _selectedStation = v);
                        if (_currentLat != null && _currentLng != null) {
                          _validateAgainstSelectedStation();
                        } else {
                          _checkLocation();
                        }
                      },
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'DATE',
            style: GoogleFonts.dmSans(
              color: const Color(0xFF888888),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
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

              if (picked != null) {
                setState(() => _selectedDate = picked);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F9F8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200, width: 1.5),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    color: Colors.grey.shade400,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                    style: GoogleFonts.dmSans(
                      color: const Color(0xFF1A4731),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _isLocationValid
                  ? const Color(0xFFE8F5EE)
                  : const Color(0xFFFFF0F0),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isLocationValid
                    ? const Color(0xFFB8E8CC)
                    : const Color(0xFFF3C2C2),
              ),
            ),
            child: Row(
              children: [
                if (_isCheckingLocation)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(
                    _isLocationValid
                        ? Icons.check_circle_rounded
                        : Icons.location_off_rounded,
                    size: 18,
                    color: _isLocationValid
                        ? const Color(0xFF3DAB6A)
                        : const Color(0xFFE05454),
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _locationStatus,
                    style: GoogleFonts.dmSans(
                      color: _isLocationValid
                          ? const Color(0xFF2D7A4F)
                          : const Color(0xFFE05454),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _isCheckingLocation ? null : _checkLocation,
                  child: Text(
                    'Refresh',
                    style: GoogleFonts.dmSans(
                      color: const Color(0xFF2D7A4F),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_weightController.text.isNotEmpty &&
              double.tryParse(_weightController.text) != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FAF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFB8E8CC),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.star_rounded,
                    color: Color(0xFFFFB800),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Potential reward: ',
                    style: GoogleFonts.dmSans(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '$_calculatedPoints points',
                    style: GoogleFonts.dmSans(
                      color: const Color(0xFF2D7A4F),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${categories[_selectedCategory]!.pointsPerKg} pts/kg',
                    style: GoogleFonts.dmSans(
                      color: Colors.grey.shade400,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed:
                  (_isLoading || _isCheckingLocation || !_isLocationValid)
                      ? null
                      : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D7A4F),
                disabledBackgroundColor:
                    const Color(0xFF2D7A4F).withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      _isLocationValid ? 'Submit Record' : 'Not near a station',
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  final RecycleRecord record;
  final bool canManage;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RecordCard({
    required this.record,
    required this.canManage,
    required this.onEdit,
    required this.onDelete,
  });

  Map<String, dynamic> _getStatusInfo() {
    switch (record.status.toLowerCase()) {
      case 'approved':
        return {
          'label': 'Approved',
          'color': const Color(0xFF3DAB6A),
          'bgColor': const Color(0xFFE8F5EE),
          'icon': Icons.check_circle_rounded,
        };
      case 'rejected':
        return {
          'label': 'Rejected',
          'color': const Color(0xFFE05454),
          'bgColor': const Color(0xFFFFF0F0),
          'icon': Icons.cancel_rounded,
        };
      default:
        return {
          'label': 'Pending',
          'color': const Color(0xFF4A90D9),
          'bgColor': const Color(0xFFE8F0FA),
          'icon': Icons.schedule_rounded,
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final cfg = categories[record.category] ?? categories['Plastic']!;
    final dateStr =
        '${record.date.year}-${record.date.month.toString().padLeft(2, '0')}-${record.date.day.toString().padLeft(2, '0')}';
    final statusInfo = _getStatusInfo();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: cfg.bgColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(cfg.icon, color: cfg.color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      record.category,
                      style: GoogleFonts.dmSans(
                        color: const Color(0xFF1A4731),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusInfo['bgColor'] as Color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            statusInfo['icon'] as IconData,
                            color: statusInfo['color'] as Color,
                            size: 11,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            statusInfo['label'] as String,
                            style: GoogleFonts.dmSans(
                              color: statusInfo['color'] as Color,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '$dateStr  ·  ${record.station}',
                  style: GoogleFonts.dmSans(
                    color: Colors.grey.shade500,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (record.rejectionReason != null &&
                    record.rejectionReason!.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Reason: ${record.rejectionReason}',
                    style: GoogleFonts.dmSans(
                      color: const Color(0xFFE05454),
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${record.weightKg.toStringAsFixed(1)} kg',
                style: GoogleFonts.dmSans(
                  color: cfg.color,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(
                    Icons.star_rounded,
                    color: Color(0xFFFFB800),
                    size: 12,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${record.points} pts',
                    style: GoogleFonts.dmSans(
                      color: Colors.grey.shade400,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (canManage) ...[
            const SizedBox(width: 10),
            Column(
              children: [
                GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FAF4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      color: Color(0xFF3DAB6A),
                      size: 15,
                    ),
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
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: Color(0xFFE05454),
                      size: 15,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _AddRecordSheet extends StatefulWidget {
  final RecycleRecord? editing;
  final List<String> stations;

  const _AddRecordSheet({
    this.editing,
    required this.stations,
  });

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
    _selectedStation =
        e?.station ?? (widget.stations.isNotEmpty ? widget.stations.first : '');
    _selectedDate = e?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_selectedStation.isEmpty) return;

    final weight = double.tryParse(_weightController.text.trim());
    if (weight == null || weight <= 0) return;

    setState(() => _isLoading = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      if (widget.editing != null) {
        await supabase
            .from('recycle_records')
            .update({
              'category': _selectedCategory,
              'weight_kg': weight,
              'station': _selectedStation,
              'points': 0,
              'status': 'pending',
              'approved_at': null,
              'rejection_reason': null,
              'date': _selectedDate.toIso8601String().substring(0, 10),
            })
            .eq('id', widget.editing!.id)
            .eq('user_id', user.id);

        if (mounted) Navigator.pop(context, true);
      }
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
        24,
        16,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
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
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Edit Record',
            style: GoogleFonts.dmSans(
              color: const Color(0xFF1A4731),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        cfg.icon,
                        color: selected ? Colors.white : cfg.color,
                        size: 14,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        cat,
                        style: GoogleFonts.dmSans(
                          color: selected ? Colors.white : cfg.color,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
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
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFF3DAB6A), width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9F8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200, width: 1.5),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: widget.stations.contains(_selectedStation)
                    ? _selectedStation
                    : null,
                isExpanded: true,
                style: GoogleFonts.dmSans(
                  color: const Color(0xFF1A4731),
                  fontSize: 14,
                ),
                dropdownColor: Colors.white,
                hint: Text(
                  'No station available',
                  style: GoogleFonts.dmSans(
                    color: Colors.grey.shade500,
                    fontSize: 13,
                  ),
                ),
                items: widget.stations
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: widget.stations.isEmpty
                    ? null
                    : (v) {
                        if (v != null) {
                          setState(() => _selectedStation = v);
                        }
                      },
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
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
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
    );
  }
}
