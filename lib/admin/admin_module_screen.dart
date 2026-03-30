import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/supabase_client.dart';

class AdminModuleScreen extends StatefulWidget {
  const AdminModuleScreen({super.key});

  @override
  State<AdminModuleScreen> createState() => _AdminModuleScreenState();
}

class _AdminModuleScreenState extends State<AdminModuleScreen>
    with SingleTickerProviderStateMixin {
  final _supabase = supabaseClient;

  late final TabController _tabController;

  bool _isLoading = true;
  bool _isAuthorizing = true;
  bool _isAdmin = false;
  bool _isSavingStation = false;
  String? _stationsLoadError;

  List<Map<String, dynamic>> _users = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _records = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _stations = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
          .order('created_at', ascending: false);

      _records = List<Map<String, dynamic>>.from(data as List);
    } catch (_) {
      try {
        final data =
            await _supabase.from('recycle_records').select().order('date');
        _records = List<Map<String, dynamic>>.from(data as List);
      } catch (_) {
        _records = <Map<String, dynamic>>[];
      }
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
    } catch (error) {
      _stations = <Map<String, dynamic>>[];
      _stationsLoadError =
          'Station table unavailable. Create table "recycling_stations" to manage stations.';
      debugPrint('Station load error: $error');
    }
  }

  Future<void> _updateUser(Map<String, dynamic> user) async {
    final id = user['id']?.toString();
    if (id == null || id.isEmpty) return;

    final usernameController =
        TextEditingController(text: user['username']?.toString() ?? '');
    final emailController =
        TextEditingController(text: user['email']?.toString() ?? '');
    final pointsController = TextEditingController(
      text: (user['total_points'] ?? 0).toString(),
    );
    final roleController =
        TextEditingController(text: user['role']?.toString() ?? 'user');

    String role = roleController.text;
    bool isAdmin = user['is_admin'] == true;

    final save = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Edit User',
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
          ),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: usernameController,
                      decoration: const InputDecoration(labelText: 'Username'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: pointsController,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Total Points'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      enabled: user.containsKey('role'),
                      controller: roleController,
                      onChanged: (value) => role = value.trim(),
                      decoration: const InputDecoration(labelText: 'Role'),
                    ),
                    const SizedBox(height: 6),
                    SwitchListTile.adaptive(
                      value: isAdmin,
                      onChanged: user.containsKey('is_admin')
                          ? (value) => setDialogState(() => isAdmin = value)
                          : null,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Is Admin'),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (save != true) return;

    final updatePayload = <String, dynamic>{
      'username': usernameController.text.trim(),
      'email': emailController.text.trim(),
      'total_points': int.tryParse(pointsController.text.trim()) ?? 0,
    };

    if (user.containsKey('role')) {
      updatePayload['role'] = role.isEmpty ? 'user' : role;
    }

    if (user.containsKey('is_admin')) {
      updatePayload['is_admin'] = isAdmin;
    }

    try {
      await _supabase.from('profiles').update(updatePayload).eq('id', id);
      await _loadUsers();
      if (mounted) {
        setState(() {});
        _showSnack('User updated', isError: false);
      }
    } catch (_) {
      if (mounted) {
        _showSnack('Failed to update user', isError: true);
      }
    }
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    final id = user['id']?.toString();
    if (id == null || id.isEmpty) return;

    final shouldDelete = await _confirmDialog(
      title: 'Delete user?',
      message:
          'This will remove profile data and related recycling records for this user.',
    );
    if (!shouldDelete) return;

    try {
      await _supabase.from('recycle_records').delete().eq('user_id', id);
      await _supabase.from('profiles').delete().eq('id', id);
      await _loadAllData();
      if (mounted) {
        _showSnack('User deleted', isError: false);
      }
    } catch (_) {
      if (mounted) {
        _showSnack('Failed to delete user', isError: true);
      }
    }
  }

  Future<void> _updateRecord(Map<String, dynamic> record) async {
    final id = record['id']?.toString();
    if (id == null || id.isEmpty) return;

    final categoryController =
        TextEditingController(text: record['category']?.toString() ?? '');
    final weightController = TextEditingController(
      text: (record['weight_kg'] ?? 0).toString(),
    );
    final stationController =
        TextEditingController(text: record['station']?.toString() ?? '');
    final pointsController = TextEditingController(
      text: (record['points'] ?? 0).toString(),
    );
    final dateController = TextEditingController(
      text: (record['date']?.toString() ?? '').split('T').first,
    );

    final save = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'Edit Record',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: weightController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Weight (kg)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: stationController,
                decoration: const InputDecoration(labelText: 'Station'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: pointsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Points'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: dateController,
                decoration:
                    const InputDecoration(labelText: 'Date (YYYY-MM-DD)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (save != true) return;

    final updatePayload = <String, dynamic>{
      'category': categoryController.text.trim(),
      'weight_kg': double.tryParse(weightController.text.trim()) ?? 0,
      'station': stationController.text.trim(),
      'points': int.tryParse(pointsController.text.trim()) ?? 0,
      'date': dateController.text.trim(),
    };

    try {
      await _supabase
          .from('recycle_records')
          .update(updatePayload)
          .eq('id', id);
      await _loadRecords();
      if (mounted) {
        setState(() {});
        _showSnack('Record updated', isError: false);
      }
    } catch (_) {
      if (mounted) {
        _showSnack('Failed to update record', isError: true);
      }
    }
  }

  Future<void> _deleteRecord(Map<String, dynamic> record) async {
    final id = record['id']?.toString();
    if (id == null || id.isEmpty) return;

    final shouldDelete = await _confirmDialog(
      title: 'Delete recycling record?',
      message: 'This action cannot be undone.',
    );
    if (!shouldDelete) return;

    try {
      await _supabase.from('recycle_records').delete().eq('id', id);
      await _loadRecords();
      if (mounted) {
        setState(() {});
        _showSnack('Record deleted', isError: false);
      }
    } catch (_) {
      if (mounted) {
        _showSnack('Failed to delete record', isError: true);
      }
    }
  }

  Future<void> _createOrEditStation({Map<String, dynamic>? station}) async {
    final id = station?['id']?.toString();
    final nameController =
        TextEditingController(text: station?['name']?.toString() ?? '');
    final addressController =
        TextEditingController(text: station?['address']?.toString() ?? '');
    final phoneController =
        TextEditingController(text: station?['phone']?.toString() ?? '');
    final latitudeController =
        TextEditingController(text: station?['latitude']?.toString() ?? '');
    final longitudeController =
        TextEditingController(text: station?['longitude']?.toString() ?? '');
    bool isOpen = station?['is_open'] != false;

    final save = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          station == null ? 'Add Station' : 'Edit Station',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
        ),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: addressController,
                    decoration: const InputDecoration(labelText: 'Address'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(labelText: 'Phone'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: latitudeController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Latitude'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: longitudeController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Longitude'),
                  ),
                  const SizedBox(height: 6),
                  SwitchListTile.adaptive(
                    value: isOpen,
                    onChanged: (value) => setDialogState(() => isOpen = value),
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Open'),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (save != true) return;

    final payload = <String, dynamic>{
      'name': nameController.text.trim(),
      'address': addressController.text.trim(),
      'phone': phoneController.text.trim(),
      'latitude': double.tryParse(latitudeController.text.trim()),
      'longitude': double.tryParse(longitudeController.text.trim()),
      'is_open': isOpen,
    };

    setState(() => _isSavingStation = true);
    try {
      if (station == null) {
        await _supabase.from('recycling_stations').insert(payload);
      } else {
        await _supabase
            .from('recycling_stations')
            .update(payload)
            .eq('id', id!);
      }

      await _loadStations();
      if (mounted) {
        setState(() {});
        _showSnack(
          station == null ? 'Station added' : 'Station updated',
          isError: false,
        );
      }
    } catch (_) {
      if (mounted) {
        _showSnack('Failed to save station', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSavingStation = false);
    }
  }

  Future<void> _deleteStation(Map<String, dynamic> station) async {
    final id = station['id']?.toString();
    if (id == null || id.isEmpty) return;

    final shouldDelete = await _confirmDialog(
      title: 'Delete station?',
      message: 'This action cannot be undone.',
    );
    if (!shouldDelete) return;

    try {
      await _supabase.from('recycling_stations').delete().eq('id', id);
      await _loadStations();
      if (mounted) {
        setState(() {});
        _showSnack('Station deleted', isError: false);
      }
    } catch (_) {
      if (mounted) {
        _showSnack('Failed to delete station', isError: true);
      }
    }
  }

  Future<bool> _confirmDialog({
    required String title,
    required String message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE05454),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    return result == true;
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
          child: CircularProgressIndicator(color: Color(0xFF2D7A4F)),
        ),
      );
    }

    if (!_isAdmin) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4FAF4),
        appBar: AppBar(
          title: Text(
            'Admin Control Center',
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
          ),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1A4731),
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
                    backgroundColor: const Color(0xFF2D7A4F),
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
      backgroundColor: const Color(0xFFF4FAF4),
      appBar: AppBar(
        title: Text(
          'Admin Control Center',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A4731),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadAllData,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF1A4731),
          indicatorColor: const Color(0xFF2D7A4F),
          unselectedLabelColor: Colors.black54,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Users'),
            Tab(text: 'Records'),
            Tab(text: 'Stations'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2D7A4F)),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildUsersTab(),
                _buildRecordsTab(),
                _buildStationsTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _statCard(
                title: 'Total Users',
                value: _totalUsers.toString(),
                icon: Icons.people_alt_rounded,
                color: const Color(0xFF2D7A4F),
              ),
              _statCard(
                title: 'Recycling Records',
                value: _totalRecords.toString(),
                icon: Icons.recycling_rounded,
                color: const Color(0xFF4A90D9),
              ),
              _statCard(
                title: 'Total Carbon Saved',
                value: '${_totalCarbonSaved.toStringAsFixed(1)} kg CO2',
                icon: Icons.eco_rounded,
                color: const Color(0xFF66BB6A),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _simpleSectionCard(
            title: 'System Notes',
            child: Text(
              'Use this module to manage users, recycling records, and stations. '
              'Changes apply to all users in the system.',
              style: GoogleFonts.dmSans(
                color: Colors.black87,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];
          final username = user['username']?.toString() ?? 'Unknown';
          final email = user['email']?.toString() ?? '-';
          final points = (user['total_points'] ?? 0).toString();

          return _simpleSectionCard(
            title: username,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _updateUser(user),
                  icon: const Icon(Icons.edit_rounded),
                ),
                IconButton(
                  onPressed: () => _deleteUser(user),
                  icon: const Icon(Icons.delete_rounded, color: Colors.red),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Email: $email', style: GoogleFonts.dmSans(fontSize: 13)),
                const SizedBox(height: 4),
                Text('Points: $points',
                    style: GoogleFonts.dmSans(fontSize: 13)),
                const SizedBox(height: 4),
                Text(
                  'Role: ${user['role'] ?? (user['is_admin'] == true ? 'admin' : 'user')}',
                  style: GoogleFonts.dmSans(fontSize: 13),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecordsTab() {
    return RefreshIndicator(
      onRefresh: _loadRecords,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _records.length,
        itemBuilder: (context, index) {
          final record = _records[index];
          final category = record['category']?.toString() ?? 'Unknown';
          final weight = ((record['weight_kg'] as num?)?.toDouble() ?? 0)
              .toStringAsFixed(2);
          final station = record['station']?.toString() ?? '-';
          final userId = record['user_id']?.toString() ?? '-';

          return _simpleSectionCard(
            title: '$category - $weight kg',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _updateRecord(record),
                  icon: const Icon(Icons.edit_rounded),
                ),
                IconButton(
                  onPressed: () => _deleteRecord(record),
                  icon: const Icon(Icons.delete_rounded, color: Colors.red),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Station: $station',
                    style: GoogleFonts.dmSans(fontSize: 13)),
                const SizedBox(height: 4),
                Text('User ID: $userId',
                    style: GoogleFonts.dmSans(fontSize: 13)),
                const SizedBox(height: 4),
                Text(
                  'Date: ${(record['date']?.toString() ?? '-').split('T').first}',
                  style: GoogleFonts.dmSans(fontSize: 13),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStationsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Manage recycling stations',
                  style: GoogleFonts.dmSans(
                    color: const Color(0xFF1A4731),
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isSavingStation
                    ? null
                    : () => _createOrEditStation(station: null),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D7A4F),
                ),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Station'),
              ),
            ],
          ),
        ),
        if (_stationsLoadError != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFCC80)),
              ),
              child: Text(
                _stationsLoadError!,
                style: GoogleFonts.dmSans(
                  color: const Color(0xFF8A5A00),
                  fontSize: 12,
                ),
              ),
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadStations,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: _stations.length,
              itemBuilder: (context, index) {
                final station = _stations[index];
                final name = station['name']?.toString() ?? 'Unnamed station';
                final address = station['address']?.toString() ?? '-';
                final phone = station['phone']?.toString() ?? '-';
                final isOpen = station['is_open'] != false;

                return _simpleSectionCard(
                  title: name,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: _isSavingStation
                            ? null
                            : () => _createOrEditStation(station: station),
                        icon: const Icon(Icons.edit_rounded),
                      ),
                      IconButton(
                        onPressed: _isSavingStation
                            ? null
                            : () => _deleteStation(station),
                        icon:
                            const Icon(Icons.delete_rounded, color: Colors.red),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Address: $address',
                        style: GoogleFonts.dmSans(fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Phone: $phone',
                        style: GoogleFonts.dmSans(fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Status: ${isOpen ? 'Open' : 'Closed'}',
                        style: GoogleFonts.dmSans(fontSize: 13),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 360),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x11000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.dmSans(
                      color: Colors.black87,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: GoogleFonts.dmSans(
                      color: const Color(0xFF1A4731),
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _simpleSectionCard({
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.dmSans(
                    color: const Color(0xFF1A4731),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
