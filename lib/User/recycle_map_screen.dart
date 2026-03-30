import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/supabase_client.dart';

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// No API key needed, uses OpenStreetMap (completely free).
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

// â”€â”€â”€ Accepted recycling material types â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

const _recycleTypes = [
  _RecycleType('Plastic', Icons.water_drop_outlined, Color(0xFF3DAB6A),
      Color(0xFFE8F5EE)),
  _RecycleType(
      'Paper', Icons.article_outlined, Color(0xFF4A90D9), Color(0xFFE8F0FA)),
  _RecycleType(
      'Glass', Icons.wine_bar_outlined, Color(0xFF9B6FD4), Color(0xFFF0EBF9)),
  _RecycleType(
      'Metal', Icons.hardware_outlined, Color(0xFFE8A020), Color(0xFFFBF3E3)),
  _RecycleType(
      'E-Waste', Icons.devices_outlined, Color(0xFFE05454), Color(0xFFFFF0F0)),
  _RecycleType('Clothes', Icons.checkroom_outlined, Color(0xFF00ACC1),
      Color(0xFFE0F7FA)),
];

class _RecycleType {
  final String label;
  final IconData icon;
  final Color color;
  final Color bg;
  const _RecycleType(this.label, this.icon, this.color, this.bg);
}

// â”€â”€â”€ Data Model â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class RecyclingCenter {
  final String id;
  final String name;
  final String address;
  final LatLng location;
  final double? rating;
  final bool isOpen;
  final String? phoneNumber;
  final List<String> openingHours;
  final List<String> acceptedTypes;
  double distanceKm;

  RecyclingCenter({
    required this.id,
    required this.name,
    required this.address,
    required this.location,
    this.rating,
    this.isOpen = true,
    this.phoneNumber,
    this.openingHours = const [],
    this.acceptedTypes = const [],
    this.distanceKm = 0,
  });
}

// â”€â”€â”€ Map Screen â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class RecycleMapScreen extends StatefulWidget {
  const RecycleMapScreen({super.key});

  @override
  State<RecycleMapScreen> createState() => _RecycleMapScreenState();
}

class _RecycleMapScreenState extends State<RecycleMapScreen>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  LatLng? _currentPosition;
  List<RecyclingCenter> _centers = [];
  List<RecyclingCenter> _allCenters = [];
  RecyclingCenter? _selectedCenter;

  bool _isLoading = true;
  int _radiusKm = 5;

  late AnimationController _sheetAnim;
  late Animation<Offset> _sheetSlide;

  // Melaka default center
  static const _melakaCenter = LatLng(2.1896, 102.2501);

  @override
  void initState() {
    super.initState();
    _sheetAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _sheetSlide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _sheetAnim, curve: Curves.easeOutCubic));
    _initLocation();
  }

  @override
  void dispose() {
    _sheetAnim.dispose();
    super.dispose();
  }

  // â”€â”€ Location â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> _initLocation() async {
    setState(() {
      _isLoading = true;
    });
    try {
      if (!await _requestPermission()) {
        // Permission denied, still show map centered on Melaka.
        setState(() {
          _currentPosition = _melakaCenter;
        });
        await _loadCenters();
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() => _currentPosition = LatLng(pos.latitude, pos.longitude));
      _mapController.move(_currentPosition!, 13.5);
      await _loadCenters();
    } catch (_) {
      // Fallback to Melaka center if location fails
      setState(() => _currentPosition = _melakaCenter);
      await _loadCenters();
    }
  }

  Future<bool> _requestPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    return perm != LocationPermission.denied &&
        perm != LocationPermission.deniedForever;
  }

  // â”€â”€ Load & Filter Centers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Future<List<RecyclingCenter>> _fetchCentersFromDb() async {
    final data = await supabaseClient
        .from('recycling_stations')
        .select()
        .order('created_at', ascending: false);

    final rows = List<Map<String, dynamic>>.from(data as List);
    final result = <RecyclingCenter>[];

    for (final row in rows) {
      final lat = _toDouble(row['latitude']) ??
          _toDouble(row['location_lat']) ??
          _toDouble(row['lat']);
      final lng = _toDouble(row['longitude']) ??
          _toDouble(row['location_lng']) ??
          _toDouble(row['lng']);

      if (lat == null || lng == null) continue;

      final name = (row['name'] ?? '').toString().trim();
      if (name.isEmpty) continue;

      result.add(
        RecyclingCenter(
          id: (row['id'] ?? name).toString(),
          name: name,
          address: (row['address'] ?? '').toString(),
          location: LatLng(lat, lng),
          phoneNumber: row['phone']?.toString(),
          isOpen: row['is_open'] == null ? true : row['is_open'] == true,
        ),
      );
    }

    return result;
  }

  Future<void> _loadCenters() async {
    final origin = _currentPosition ?? _melakaCenter;

    try {
      _allCenters = await _fetchCentersFromDb();
    } catch (_) {
      _allCenters = <RecyclingCenter>[];
    }

    final withDistance = _allCenters.map((c) {
      c.distanceKm = Geolocator.distanceBetween(origin.latitude,
              origin.longitude, c.location.latitude, c.location.longitude) /
          1000;
      return c;
    }).toList()
      ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

    final nearby =
        withDistance.where((c) => c.distanceKm <= _radiusKm).toList();
    final display = nearby.isEmpty ? withDistance.take(20).toList() : nearby;

    setState(() {
      _centers = display;
      _isLoading = false;
      _selectedCenter = null;
    });
  }

  void _selectCenter(RecyclingCenter center) {
    setState(() => _selectedCenter = center);
    _sheetAnim.forward();
    _mapController.move(center.location, 15.5);
  }

  void _dismissSheet() {
    _sheetAnim.reverse().then((_) {
      if (mounted) setState(() => _selectedCenter = null);
    });
  }

  // â”€â”€ Navigation â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  void _showNavOptions(RecyclingCenter c) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: EdgeInsets.fromLTRB(
            20, 16, 20, MediaQuery.of(context).padding.bottom + 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 20),
          Text('Navigate to',
              style: GoogleFonts.dmSans(
                  color: const Color(0xFF1A4731),
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(c.name,
              style:
                  GoogleFonts.dmSans(color: Colors.grey.shade500, fontSize: 13),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          _navTile(
            icon: Icons.map_rounded,
            title: 'Open in Google Maps',
            subtitle: 'Full turn-by-turn navigation',
            color: const Color(0xFF4A90D9),
            bg: const Color(0xFFE8F0FA),
            onTap: () {
              Navigator.pop(context);
              _openGoogleMaps(c);
            },
          ),
          const SizedBox(height: 12),
          _navTile(
            icon: Icons.directions_rounded,
            title: 'Open in Waze',
            subtitle: 'Navigate with Waze',
            color: const Color(0xFF3DAB6A),
            bg: const Color(0xFFE8F5EE),
            onTap: () {
              Navigator.pop(context);
              _openWaze(c);
            },
          ),
        ]),
      ),
    );
  }

  Future<void> _openGoogleMaps(RecyclingCenter c) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${c.location.latitude},${c.location.longitude}'
      '&travelmode=driving',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openWaze(RecyclingCenter c) async {
    final uri = Uri.parse(
      'https://waze.com/ul?ll=${c.location.latitude},${c.location.longitude}&navigate=yes',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _navTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color bg,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
        ),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: GoogleFonts.dmSans(
                      color: const Color(0xFF1A4731),
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
              Text(subtitle,
                  style: GoogleFonts.dmSans(
                      color: Colors.grey.shade500, fontSize: 12)),
            ]),
          ),
          Icon(Icons.arrow_forward_ios_rounded, color: color, size: 14),
        ]),
      ),
    );
  }

  // â”€â”€ Build â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        _buildMap(),
        _buildTopBar(),
        _buildRadiusPills(),
        if (_isLoading) _buildLoadingOverlay(),
        if (_selectedCenter != null) _buildDetailSheet(),
        if (!_isLoading) _buildCountBadge(),
      ]),
    );
  }

  // â”€â”€ Map (OpenStreetMap â€” no API key) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildMap() {
    final center = _currentPosition ?? _melakaCenter;
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 13.5,
        onTap: (_, __) {
          if (_selectedCenter != null) _dismissSheet();
        },
      ),
      children: [
        // OpenStreetMap tile layer â€” completely free
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.system_green_track',
        ),

        // Recycling centre markers
        MarkerLayer(
          markers: [
            // User location marker
            if (_currentPosition != null)
              Marker(
                point: _currentPosition!,
                width: 44,
                height: 44,
                child: _userMarker(),
              ),

            // Recycling centre markers
            ..._centers.map((c) => Marker(
                  point: c.location,
                  width: 44,
                  height: 44,
                  child: GestureDetector(
                    onTap: () => _selectCenter(c),
                    child: _centerMarker(c),
                  ),
                )),
          ],
        ),
      ],
    );
  }

  Widget _userMarker() => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF4A90D9),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF4A90D9).withValues(alpha: 0.4),
                blurRadius: 10)
          ],
        ),
        child:
            const Icon(Icons.person_pin_rounded, color: Colors.white, size: 22),
      );

  Widget _centerMarker(RecyclingCenter c) {
    final isSelected = _selectedCenter?.id == c.id;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF1A4731) : const Color(0xFF3DAB6A),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
              color: (isSelected
                      ? const Color(0xFF1A4731)
                      : const Color(0xFF3DAB6A))
                  .withValues(alpha: 0.45),
              blurRadius: 10)
        ],
      ),
      child: Icon(
        Icons.recycling_rounded,
        color: Colors.white,
        size: isSelected ? 22 : 18,
      ),
    );
  }

  // â”€â”€ Top Bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Row(children: [
          _iconBtn(Icons.arrow_back_ios_new_rounded,
              onTap: () => Navigator.pop(context)),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(13),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.09),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Row(children: [
                const Icon(Icons.recycling_rounded,
                    color: Color(0xFF3DAB6A), size: 18),
                const SizedBox(width: 8),
                Text('Nearby Recycling Centres',
                    style: GoogleFonts.dmSans(
                        color: const Color(0xFF1A4731),
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
          const SizedBox(width: 12),
          _iconBtn(Icons.my_location_rounded,
              bg: const Color(0xFF3DAB6A),
              iconColor: Colors.white,
              onTap: _initLocation),
        ]),
      ),
    );
  }

  Widget _iconBtn(
    IconData icon, {
    Color bg = Colors.white,
    Color iconColor = const Color(0xFF1A4731),
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(13),
          boxShadow: [
            BoxShadow(
                color: bg == Colors.white
                    ? Colors.black.withValues(alpha: 0.09)
                    : bg.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
    );
  }

  // â”€â”€ Radius Pills â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildRadiusPills() {
    const opts = [
      (l: '1 km', v: 1),
      (l: '3 km', v: 3),
      (l: '5 km', v: 5),
      (l: '10 km', v: 10),
    ];
    return Positioned(
      top: MediaQuery.of(context).padding.top + 68,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: opts.map((o) {
          final sel = _radiusKm == o.v;
          return GestureDetector(
            onTap: () {
              setState(() => _radiusKm = o.v);
              _loadCenters();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: sel ? const Color(0xFF2D7A4F) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Text(o.l,
                  style: GoogleFonts.dmSans(
                      color: sel ? Colors.white : const Color(0xFF1A4731),
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
          );
        }).toList(),
      ),
    );
  }


  // â”€â”€ Count Badge â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildCountBadge() {
    return Positioned(
      bottom: _selectedCenter != null ? 340 : 28,
      left: 16,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.09),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.location_on_rounded,
              color: Color(0xFF3DAB6A), size: 14),
          const SizedBox(width: 6),
          Text(
            '${_centers.length} centre${_centers.length != 1 ? 's' : ''} found',
            style: GoogleFonts.dmSans(
                color: const Color(0xFF1A4731),
                fontSize: 12,
                fontWeight: FontWeight.w600),
          ),
        ]),
      ),
    );
  }

  // â”€â”€ Loading Overlay â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildLoadingOverlay() => Positioned.fill(
        child: Container(
          color: Colors.white.withValues(alpha: 0.75),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.07),
                        blurRadius: 20)
                  ]),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const CircularProgressIndicator(color: Color(0xFF3DAB6A)),
                const SizedBox(height: 16),
                Text('Loading map...',
                    style: GoogleFonts.dmSans(
                        color: const Color(0xFF1A4731),
                        fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        ),
      );

  // â”€â”€ Detail Sheet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildDetailSheet() {
    final c = _selectedCenter!;
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _sheetSlide,
        child: Container(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.65),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black12, blurRadius: 20, offset: Offset(0, -4))
            ],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Handle + close
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(children: [
                Expanded(
                  child: Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _dismissSheet,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade100, shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded,
                        color: Colors.grey, size: 16),
                  ),
                ),
              ]),
            ),

            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: _buildSheetContent(c),
              ),
            ),

            // Navigate button
            Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 12, 20, MediaQuery.of(context).padding.bottom + 16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => _showNavOptions(c),
                  icon: const Icon(Icons.navigation_rounded,
                      color: Colors.white, size: 18),
                  label: Text('Navigate',
                      style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D7A4F),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildSheetContent(RecyclingCenter c) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Name + address
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
              color: const Color(0xFFE8F5EE),
              borderRadius: BorderRadius.circular(14)),
          child: const Icon(Icons.recycling_rounded,
              color: Color(0xFF3DAB6A), size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(c.name,
                style: GoogleFonts.dmSans(
                    color: const Color(0xFF1A4731),
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(c.address,
                style: GoogleFonts.dmSans(
                    color: Colors.grey.shade500, fontSize: 12)),
          ]),
        ),
      ]),

      const SizedBox(height: 16),

      // Info chips
      Wrap(spacing: 8, runSpacing: 8, children: [
        _chip(
            Icons.straighten_rounded,
            '${c.distanceKm.toStringAsFixed(1)} km away',
            const Color(0xFF4A90D9),
            const Color(0xFFE8F0FA)),
        if (c.rating != null)
          _chip(Icons.star_rounded, '${c.rating!.toStringAsFixed(1)} â˜…',
              const Color(0xFFE8A020), const Color(0xFFFBF3E3)),
        _chip(
          c.isOpen ? Icons.check_circle_outline_rounded : Icons.cancel_outlined,
          c.isOpen ? 'Open now' : 'Closed',
          c.isOpen ? const Color(0xFF3DAB6A) : const Color(0xFFE05454),
          c.isOpen ? const Color(0xFFE8F5EE) : const Color(0xFFFFF0F0),
        ),
        if (c.phoneNumber != null)
          GestureDetector(
            onTap: () => launchUrl(Uri.parse('tel:${c.phoneNumber}')),
            child: _chip(Icons.phone_outlined, c.phoneNumber!,
                const Color(0xFF9B6FD4), const Color(0xFFF0EBF9)),
          ),
      ]),

      // Opening hours
      if (c.openingHours.isNotEmpty) ...[
        const SizedBox(height: 20),
        _sectionLabel(Icons.schedule_rounded, 'Opening Hours'),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: const Color(0xFFF7F9F8),
              borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: c.openingHours.map((line) {
              final parts = line.split(': ');
              final day = parts.isNotEmpty ? parts[0] : line;
              final hours = parts.length > 1 ? parts[1] : '';
              final today = _isToday(day);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(children: [
                  SizedBox(
                    width: 92,
                    child: Text(day,
                        style: GoogleFonts.dmSans(
                            color: today
                                ? const Color(0xFF2D7A4F)
                                : Colors.grey.shade600,
                            fontSize: 12,
                            fontWeight:
                                today ? FontWeight.w700 : FontWeight.w400)),
                  ),
                  Expanded(
                    child: Text(hours,
                        style: GoogleFonts.dmSans(
                            color: today
                                ? const Color(0xFF1A4731)
                                : Colors.grey.shade500,
                            fontSize: 12,
                            fontWeight:
                                today ? FontWeight.w600 : FontWeight.w400)),
                  ),
                  if (today)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: const Color(0xFF3DAB6A),
                          borderRadius: BorderRadius.circular(6)),
                      child: Text('Today',
                          style: GoogleFonts.dmSans(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700)),
                    ),
                ]),
              );
            }).toList(),
          ),
        ),
      ],

      // Accepted materials
      if (c.acceptedTypes.isNotEmpty) ...[
        const SizedBox(height: 20),
        _sectionLabel(Icons.category_outlined, 'Accepted Materials'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _recycleTypes
              .where((t) => c.acceptedTypes.contains(t.label))
              .map((t) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                        color: t.bg, borderRadius: BorderRadius.circular(10)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(t.icon, color: t.color, size: 13),
                      const SizedBox(width: 5),
                      Text(t.label,
                          style: GoogleFonts.dmSans(
                              color: t.color,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ]),
                  ))
              .toList(),
        ),
      ],

      const SizedBox(height: 24),
    ]);
  }

  // â”€â”€ Helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _sectionLabel(IconData icon, String label) => Row(children: [
        Icon(icon, color: const Color(0xFF3DAB6A), size: 15),
        const SizedBox(width: 6),
        Text(label,
            style: GoogleFonts.dmSans(
                color: const Color(0xFF1A4731),
                fontSize: 13,
                fontWeight: FontWeight.w700)),
      ]);

  Widget _chip(IconData icon, String label, Color color, Color bg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.dmSans(
                  color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ]),
      );

  bool _isToday(String dayName) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return dayName.startsWith(days[DateTime.now().weekday - 1]);
  }
}
