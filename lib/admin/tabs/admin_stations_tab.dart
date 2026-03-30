import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

class AdminStationsTab extends StatelessWidget {
  const AdminStationsTab({
    super.key,
    required this.stations,
    required this.stationsLoadError,
    required this.selectedStationPoint,
    required this.isSavingStation,
    required this.mapController,
    required this.onRefresh,
    required this.onAddStation,
    required this.onEditStation,
    required this.onDeleteStation,
    required this.onSelectStationPoint,
    required this.onPickStation,
    required this.stationPointFromMap,
  });

  static const Color _primary = Color(0xFF2D7A4F);
  static const Color _ink = Color(0xFF1A4731);

  final List<Map<String, dynamic>> stations;
  final String? stationsLoadError;
  final LatLng selectedStationPoint;
  final bool isSavingStation;
  final MapController mapController;
  final Future<void> Function() onRefresh;
  final VoidCallback onAddStation;
  final void Function(Map<String, dynamic> station) onEditStation;
  final void Function(Map<String, dynamic> station) onDeleteStation;
  final void Function(LatLng point) onSelectStationPoint;
  final void Function(Map<String, dynamic> station) onPickStation;
  final LatLng? Function(Map<String, dynamic> station) stationPointFromMap;

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>[
      ...stations.map((station) {
        final point = stationPointFromMap(station);
        if (point == null) {
          return Marker(
            point: selectedStationPoint,
            width: 0,
            height: 0,
            child: const SizedBox.shrink(),
          );
        }

        return Marker(
          point: point,
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () {
              onSelectStationPoint(point);
              onPickStation(station);
            },
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF4A90D9),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.recycling_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        );
      }).where((m) => m.width > 0),
      Marker(
        point: selectedStationPoint,
        width: 48,
        height: 48,
        child: Container(
          decoration: BoxDecoration(
            color: _primary,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: _primary.withValues(alpha: 0.42),
                blurRadius: 10,
              ),
            ],
          ),
          child: const Icon(
            Icons.add_location_alt_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    ];

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionHeader(
            title: 'Stations',
            subtitle: 'Tap map to choose location, then add station.',
            action: ElevatedButton.icon(
              onPressed: isSavingStation ? null : onAddStation,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add_location_alt_rounded, size: 16),
              label: const Text('Add Station'),
            ),
          ),
          const SizedBox(height: 12),
          _simpleSectionCard(
            title: 'Map Picker',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    height: 270,
                    child: FlutterMap(
                      mapController: mapController,
                      options: MapOptions(
                        initialCenter: selectedStationPoint,
                        initialZoom: 13.5,
                        onTap: (_, point) => onSelectStationPoint(point),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName:
                              'com.example.system_green_track',
                        ),
                        MarkerLayer(markers: markers),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Selected point: ${selectedStationPoint.latitude.toStringAsFixed(6)}, '
                  '${selectedStationPoint.longitude.toStringAsFixed(6)}',
                  style: GoogleFonts.dmSans(
                    color: const Color(0xFF4A90D9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (stationsLoadError != null) ...[
            const SizedBox(height: 12),
            _simpleSectionCard(
              title: 'Station Table Issue',
              child: Text(
                stationsLoadError!,
                style: GoogleFonts.dmSans(
                  color: const Color(0xFFE05454),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (stations.isEmpty)
            _simpleSectionCard(
              title: 'No stations',
              child: Text(
                'No station records found in Supabase.',
                style: GoogleFonts.dmSans(color: Colors.grey.shade600),
              ),
            )
          else
            ...stations.map((station) {
              final point = stationPointFromMap(station);
              return _simpleSectionCard(
                title: station['name']?.toString() ?? 'Unknown',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Address: ${station['address'] ?? '-'}',
                      style: GoogleFonts.dmSans(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Phone: ${station['phone'] ?? '-'}',
                      style: GoogleFonts.dmSans(color: Colors.grey.shade700),
                    ),
                    if (point != null) ...[
                      const SizedBox(height: 8),
                      _chip(
                        Icons.pin_drop_rounded,
                        '${point.latitude.toStringAsFixed(5)}, '
                        '${point.longitude.toStringAsFixed(5)}',
                        const Color(0xFFE8F0FA),
                        const Color(0xFF4A90D9),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => onEditStation(station),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _ink,
                              side: const BorderSide(color: Color(0xFFD4E6D8)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.edit_rounded, size: 16),
                            label: const Text('Edit'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => onDeleteStation(station),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFE05454),
                              side: const BorderSide(color: Color(0xFFE05454)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon:
                                const Icon(Icons.delete_outline_rounded, size: 16),
                            label: const Text('Delete'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
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

