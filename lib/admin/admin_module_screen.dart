import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import 'tabs/admin_dashboard_tab.dart';
import 'tabs/admin_stations_tab.dart';
import 'tabs/admin_users_tab.dart';
import '../services/supabase_client.dart';

class AdminModuleScreen extends StatefulWidget {
  const AdminModuleScreen({super.key});

  @override
  State<AdminModuleScreen> createState() => _AdminModuleScreenState();
}

class _AdminModuleScreenState extends State<AdminModuleScreen>
    with SingleTickerProviderStateMixin {
  static const Color _bg = Color(0xFFF4FAF4);
  static const Color _primary = Color(0xFF2D7A4F);
  static const Color _ink = Color(0xFF1A4731);
  static const LatLng _melakaCenter = LatLng(2.1896, 102.2501);

  final _supabase = supabaseClient;

  late final TabController _tabController;
  final MapController _stationMapController = MapController();
  int _currentTabIndex = 0;

  bool _isLoading = true;
  bool _isAuthorizing = true;
  bool _isAdmin = false;
  bool _isSavingStation = false;
  String? _stationsLoadError;
  LatLng _selectedStationPoint = _melakaCenter;

  List<Map<String, dynamic>> _users = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _records = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _stations = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _pendingRecords = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging &&
          _currentTabIndex != _tabController.index) {
        setState(() => _currentTabIndex = _tabController.index);
      }
    });
    _authorizeAndLoad();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _authorizeAndLoad() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        if (mounted) {
          setState(() {
            _isAdmin = false;
            _isAuthorizing = false;
          });
        }
        return;
      }

      final profile = await _supabase
          .from('profiles')
          .select('role, is_admin')
          .eq('id', user.id)
          .single();

      final role = (profile['role'] ?? '').toString().toLowerCase();
      final isAdminFlag = profile['is_admin'] == true;

      if (mounted) {
        setState(() {
          _isAdmin = isAdminFlag || role == 'admin';
          _isAuthorizing = false;
        });
      }

      if (_isAdmin) {
        await _loadAllData();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isAdmin = false;
          _isAuthorizing = false;
        });
      }
    }
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);

    await Future.wait([
      _loadUsers(),
      _loadRecords(),
      _loadPendingRecords(),
      _loadStations(),
    ]);

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUsers() async {
    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .order('created_at', ascending: false);

      _users = List<Map<String, dynamic>>.from(data as List);
    } catch (_) {
      _users = <Map<String, dynamic>>[];
    }
  }

  Future<void> _loadRecords() async {
    try {
      final data = await _supabase
          .from('recycle_records')
          .select()
          .neq('status', 'pending')
          .order('created_at', ascending: false);

      _records = List<Map<String, dynamic>>.from(data as List);
    } catch (_) {
      _records = <Map<String, dynamic>>[];
    }
  }

  Future<void> _loadPendingRecords() async {
    try {
      final data = await _supabase
          .from('recycle_records')
          .select()
          .eq('status', 'pending')
          .order('created_at', ascending: true);

      _pendingRecords = List<Map<String, dynamic>>.from(data as List);
    } catch (_) {
      _pendingRecords = <Map<String, dynamic>>[];
    }
  }

  Future<void> _moderatePendingRecord(
    Map<String, dynamic> record,
    bool approved,
  ) async {
    final recordId = record['id'];
    if (recordId == null) {
      _showSnack('Invalid record id.', isError: true);
      return;
    }

    final status = approved ? 'approved' : 'rejected';

    try {
      await _supabase
          .from('recycle_records')
          .update({'status': status}).eq('id', recordId);

      await Future.wait([
        _loadPendingRecords(),
        _loadRecords(),
      ]);

      if (!mounted) return;
      setState(() {});
      _showSnack(
        approved ? 'Record approved.' : 'Record rejected.',
        isError: false,
      );
    } catch (error) {
      _showSnack('Failed to update record status.', isError: true);
      debugPrint('Moderation update error: $error');
    }
  }

  Future<void> _loadStations() async {
    _stationsLoadError = null;
    try {
      final data = await _supabase
          .from('recycling_stations')
          .select()
          .order('created_at', ascending: false);

      _stations = List<Map<String, dynamic>>.from(data as List);
      if (_stations.isNotEmpty) {
        final firstPoint = _stationPointFromMap(_stations.first);
        if (firstPoint != null) {
          _selectedStationPoint = firstPoint;
        }
      }
    } catch (error) {
      _stations = <Map<String, dynamic>>[];
      _stationsLoadError =
          'Station table unavailable. Create table "recycling_stations" to manage stations.';
      debugPrint('Station load error: $error');
    }
  }

  void _showSnack(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.dmSans(color: Colors.white),
        ),
        backgroundColor:
            isError ? const Color(0xFFE05454) : const Color(0xFF2D7A4F),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  LatLng? _stationPointFromMap(Map<String, dynamic> station) {
    final lat = _toDouble(station['latitude']) ??
        _toDouble(station['location_lat']) ??
        _toDouble(station['lat']);
    final lng = _toDouble(station['longitude']) ??
        _toDouble(station['location_lng']) ??
        _toDouble(station['lng']);
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  Future<bool> _insertStation({
    required String name,
    required String address,
    required String phone,
    required LatLng point,
  }) async {
    final base = <String, dynamic>{
      'name': name,
      'address': address,
      'phone': phone.isEmpty ? null : phone,
    };

    final payloads = <Map<String, dynamic>>[
      <String, dynamic>{
        ...base,
        'latitude': point.latitude,
        'longitude': point.longitude,
      },
      <String, dynamic>{
        ...base,
        'location_lat': point.latitude,
        'location_lng': point.longitude,
      },
      <String, dynamic>{
        ...base,
        'lat': point.latitude,
        'lng': point.longitude,
      },
    ];

    Object? lastError;
    for (final payload in payloads) {
      try {
        await _supabase.from('recycling_stations').insert(payload);
        return true;
      } catch (error) {
        lastError = error;
      }
    }

    debugPrint('Station insert failed: $lastError');
    return false;
  }

  Future<bool> _updateStation({
    required Map<String, dynamic> station,
    required String name,
    required String address,
    required String phone,
    required LatLng point,
  }) async {
    final stationId = station['id'];
    if (stationId == null) return false;

    final base = <String, dynamic>{
      'name': name,
      'address': address,
      'phone': phone.isEmpty ? null : phone,
    };

    final payloads = <Map<String, dynamic>>[];

    if (station.containsKey('latitude') && station.containsKey('longitude')) {
      payloads.add(
        <String, dynamic>{
          ...base,
          'latitude': point.latitude,
          'longitude': point.longitude,
        },
      );
    }
    if (station.containsKey('location_lat') &&
        station.containsKey('location_lng')) {
      payloads.add(
        <String, dynamic>{
          ...base,
          'location_lat': point.latitude,
          'location_lng': point.longitude,
        },
      );
    }
    if (station.containsKey('lat') && station.containsKey('lng')) {
      payloads.add(
        <String, dynamic>{
          ...base,
          'lat': point.latitude,
          'lng': point.longitude,
        },
      );
    }

    payloads.addAll([
      <String, dynamic>{
        ...base,
        'latitude': point.latitude,
        'longitude': point.longitude,
      },
      <String, dynamic>{
        ...base,
        'location_lat': point.latitude,
        'location_lng': point.longitude,
      },
      <String, dynamic>{
        ...base,
        'lat': point.latitude,
        'lng': point.longitude,
      },
    ]);

    Object? lastError;
    for (final payload in payloads) {
      try {
        await _supabase
            .from('recycling_stations')
            .update(payload)
            .eq('id', stationId);
        return true;
      } catch (error) {
        lastError = error;
      }
    }

    debugPrint('Station update failed: $lastError');
    return false;
  }

  Future<bool> _deleteStation(Map<String, dynamic> station) async {
    final stationId = station['id'];
    if (stationId == null) return false;
    try {
      await _supabase.from('recycling_stations').delete().eq('id', stationId);
      return true;
    } catch (error) {
      debugPrint('Station delete failed: $error');
      return false;
    }
  }

  Future<void> _confirmDeleteStation(Map<String, dynamic> station) async {
    final name = (station['name'] ?? 'this station').toString();
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'Delete Station',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Delete $name? This cannot be undone.',
          style: GoogleFonts.dmSans(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE05454),
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (result != true) return;

    final ok = await _deleteStation(station);
    if (!mounted) return;

    if (ok) {
      await _loadStations();
      if (!mounted) return;
      _showSnack('Station deleted.', isError: false);
      setState(() {});
    } else {
      _showSnack('Failed to delete station.', isError: true);
    }
  }

  Future<void> _openAddStationSheet({
    LatLng? initialPoint,
    Map<String, dynamic>? editingStation,
  }) async {
    final isEditing = editingStation != null;

    final nameController =
        TextEditingController(text: editingStation?['name']?.toString() ?? '');
    final addressController = TextEditingController(
      text: editingStation?['address']?.toString() ?? '',
    );
    final phoneController = TextEditingController(
      text: editingStation?['phone']?.toString() ?? '',
    );

    LatLng selectedPoint = initialPoint ??
        _stationPointFromMap(editingStation ?? {}) ??
        _selectedStationPoint;

    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 12,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.92,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEditing ? 'Edit Station' : 'Add Station',
                              style: GoogleFonts.dmSans(
                                color: _ink,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isEditing
                                  ? 'Update details and tap map to adjust location.'
                                  : 'Tap map to choose the exact station location.',
                              style: GoogleFonts.dmSans(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: SizedBox(
                                height: 240,
                                child: FlutterMap(
                                  options: MapOptions(
                                    initialCenter: selectedPoint,
                                    initialZoom: 14,
                                    onTap: (_, point) {
                                      setModalState(
                                          () => selectedPoint = point);
                                    },
                                  ),
                                  children: [
                                    TileLayer(
                                      urlTemplate:
                                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                      userAgentPackageName:
                                          'com.example.system_green_track',
                                    ),
                                    MarkerLayer(
                                      markers: [
                                        Marker(
                                          point: selectedPoint,
                                          width: 44,
                                          height: 44,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: _primary,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 2.5,
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.add_location_alt_rounded,
                                              color: Colors.white,
                                              size: 22,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Selected: '
                              '${selectedPoint.latitude.toStringAsFixed(6)}, '
                              '${selectedPoint.longitude.toStringAsFixed(6)}',
                              style: GoogleFonts.dmSans(
                                color: const Color(0xFF4A90D9),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 14),
                            _buildInputField(
                              controller: nameController,
                              label: 'Station Name',
                              hint: 'Example: EcoPoint Taman Kota',
                            ),
                            const SizedBox(height: 10),
                            _buildInputField(
                              controller: addressController,
                              label: 'Address',
                              hint: 'Full address',
                              maxLines: 2,
                            ),
                            const SizedBox(height: 10),
                            _buildInputField(
                              controller: phoneController,
                              label: 'Phone (Optional)',
                              hint: '06-123 4567',
                              keyboardType: TextInputType.phone,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isSavingStation
                                  ? null
                                  : () => Navigator.pop(context, false),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _ink,
                                side: const BorderSide(
                                  color: Color(0xFFD4E6D8),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isSavingStation
                                  ? null
                                  : () async {
                                      final name = nameController.text.trim();
                                      final address =
                                          addressController.text.trim();
                                      final phone = phoneController.text.trim();

                                      if (name.isEmpty || address.isEmpty) {
                                        _showSnack(
                                          'Please fill station name and address.',
                                          isError: true,
                                        );
                                        return;
                                      }

                                      setState(() => _isSavingStation = true);
                                      final ok = isEditing
                                          ? await _updateStation(
                                              station: editingStation,
                                              name: name,
                                              address: address,
                                              phone: phone,
                                              point: selectedPoint,
                                            )
                                          : await _insertStation(
                                              name: name,
                                              address: address,
                                              phone: phone,
                                              point: selectedPoint,
                                            );
                                      if (!mounted) return;
                                      setState(() => _isSavingStation = false);

                                      if (ok) {
                                        _selectedStationPoint = selectedPoint;
                                        await _loadStations();
                                        if (!mounted) return;
                                        Navigator.pop(context, true);
                                      } else {
                                        _showSnack(
                                          isEditing
                                              ? 'Failed to update station.'
                                              : 'Failed to add station. Check table columns for coordinates.',
                                          isError: true,
                                        );
                                      }
                                    },
                              icon: _isSavingStation
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.add_rounded, size: 16),
                              label: Text(
                                _isSavingStation
                                    ? 'Saving...'
                                    : (isEditing
                                        ? 'Update Station'
                                        : 'Save Station'),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
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
            );
          },
        );
      },
    );

    nameController.dispose();
    addressController.dispose();
    phoneController.dispose();

    if (created == true && mounted) {
      _showSnack(
        isEditing
            ? 'Station updated successfully.'
            : 'Station added successfully.',
        isError: false,
      );
      setState(() {});
    }
  }

  int get _totalUsers => _users.length;
  int get _totalRecords => _records.length;
  double get _totalCarbonSaved {
    final totalWeight = _records.fold<double>(0, (sum, item) {
      return sum + ((item['weight_kg'] as num?)?.toDouble() ?? 0);
    });
    return totalWeight * 2.5;
  }

  @override
  Widget build(BuildContext context) {
    if (_isAuthorizing) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: _primary),
        ),
      );
    }

    if (!_isAdmin) {
      return Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          title: Text(
            'Admin Control Center',
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
          ),
          backgroundColor: Colors.white,
          foregroundColor: _ink,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_outline_rounded,
                  color: Color(0xFFE05454),
                  size: 44,
                ),
                const SizedBox(height: 10),
                Text(
                  'Access denied',
                  style: GoogleFonts.dmSans(
                    color: const Color(0xFF1A4731),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Only admin users can open this module.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    color: Colors.black54,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                  ),
                  child: const Text('Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text(
          'Admin Module',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        foregroundColor: _ink,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadAllData,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _primary),
            )
          : TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                AdminDashboardTab(
                  users: _users,
                  records: _records,
                  pendingRecords: _pendingRecords,
                  onRefresh: _loadAllData,
                  onModerateRecord: _moderatePendingRecord,
                ),
                AdminUsersTab(
                  users: _users,
                  onRefresh: _loadUsers,
                ),
                AdminStationsTab(
                  stations: _stations,
                  stationsLoadError: _stationsLoadError,
                  selectedStationPoint: _selectedStationPoint,
                  isSavingStation: _isSavingStation,
                  mapController: _stationMapController,
                  onRefresh: _loadStations,
                  onAddStation: () => _openAddStationSheet(
                    initialPoint: _selectedStationPoint,
                  ),
                  onEditStation: (station) {
                    final point = _stationPointFromMap(station);
                    _openAddStationSheet(
                      initialPoint: point ?? _selectedStationPoint,
                      editingStation: station,
                    );
                  },
                  onDeleteStation: _confirmDeleteStation,
                  onSelectStationPoint: (point) {
                    setState(() => _selectedStationPoint = point);
                  },
                  onPickStation: (station) {
                    _showSnack(
                      'Selected: ${station['name'] ?? 'Station'}',
                      isError: false,
                    );
                  },
                  stationPointFromMap: _stationPointFromMap,
                ),
              ],
            ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: _primary,
        indicatorColor: const Color(0xFF7EEDB0),
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: Color(0xFF1A4731),
              fontWeight: FontWeight.w700,
            );
          }
          return const TextStyle(color: Colors.white70);
        }),
        selectedIndex: _currentTabIndex,
        onDestinationSelected: (index) {
          setState(() => _currentTabIndex = index);
          _tabController.animateTo(index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_rounded, color: Colors.white70),
            selectedIcon:
                Icon(Icons.dashboard_rounded, color: Color(0xFF1A4731)),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_alt_rounded, color: Colors.white70),
            selectedIcon:
                Icon(Icons.people_alt_rounded, color: Color(0xFF1A4731)),
            label: 'Users',
          ),
          NavigationDestination(
            icon: Icon(Icons.location_on_rounded, color: Colors.white70),
            selectedIcon:
                Icon(Icons.location_on_rounded, color: Color(0xFF1A4731)),
            label: 'Stations',
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return AdminDashboardTab(
      users: _users,
      records: _records,
      pendingRecords: _pendingRecords,
      onRefresh: _loadAllData,
      onModerateRecord: _moderatePendingRecord,
    );
  }

  Widget _buildUsersTab() {
    return AdminUsersTab(
      users: _users,
      onRefresh: _loadUsers,
    );
  }

  Widget _buildRecordsTab() {
    return _buildOverviewTab();
  }

  Widget _buildPendingSubmissionsTab() {
    return _buildOverviewTab();
  }

  Widget _buildStationsTab() {
    return AdminStationsTab(
      stations: _stations,
      stationsLoadError: _stationsLoadError,
      selectedStationPoint: _selectedStationPoint,
      isSavingStation: _isSavingStation,
      mapController: _stationMapController,
      onRefresh: _loadStations,
      onAddStation: () => _openAddStationSheet(
        initialPoint: _selectedStationPoint,
      ),
      onEditStation: (station) {
        final point = _stationPointFromMap(station);
        _openAddStationSheet(
          initialPoint: point ?? _selectedStationPoint,
          editingStation: station,
        );
      },
      onDeleteStation: _confirmDeleteStation,
      onSelectStationPoint: (point) {
        setState(() => _selectedStationPoint = point);
      },
      onPickStation: (station) {
        _showSnack(
          'Selected: ${station['name'] ?? 'Station'}',
          isError: false,
        );
      },
      stationPointFromMap: _stationPointFromMap,
    );
  }

  Widget _sectionHeader({
    required String title,
    required String subtitle,
    Widget? action,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.dmSans(
                  color: _ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.dmSans(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        if (action != null) action,
      ],
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3EEE6)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0E000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.dmSans(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.dmSans(
              color: _ink,
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(
    IconData icon,
    String text,
    Color bg,
    Color fg,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.dmSans(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            color: Colors.grey.shade700,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: GoogleFonts.dmSans(
            color: _ink,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.dmSans(color: Colors.grey.shade400),
            filled: true,
            fillColor: const Color(0xFFF7F9F8),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 11,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: _primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _simpleSectionCard({
    required String title,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3EEE6)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0E000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.dmSans(
              color: _ink,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
