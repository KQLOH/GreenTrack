import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum _DashboardSection {
  recentActivity,
  processedRecords,
  pendingSubmissions,
}

class AdminDashboardTab extends StatefulWidget {
  const AdminDashboardTab({
    super.key,
    required this.users,
    required this.records,
    required this.pendingRecords,
    required this.stations,
    required this.onRefresh,
    required this.onModerateRecord,
  });

  final List<Map<String, dynamic>> users;
  final List<Map<String, dynamic>> records;
  final List<Map<String, dynamic>> pendingRecords;
  final List<Map<String, dynamic>> stations;
  final Future<void> Function() onRefresh;
  final Future<void> Function(Map<String, dynamic> record, bool approved)
      onModerateRecord;

  @override
  State<AdminDashboardTab> createState() => _AdminDashboardTabState();
}

class _AdminDashboardTabState extends State<AdminDashboardTab> {
  static const Color _primary = Color(0xFF2D7A4F);
  static const Color _ink = Color(0xFF1A4731);

  _DashboardSection selectedSection = _DashboardSection.recentActivity;

  @override
  Widget build(BuildContext context) {
    final totalStations = widget.stations.length;
    final totalCarbonSaved = widget.records.fold<double>(0, (sum, item) {
      return sum + (((item['weight_kg'] as num?)?.toDouble() ?? 0) * 2.5);
    });
    final recentActivity = widget.records.take(5).toList();
    final processedRecords = widget.records.where((record) {
      final status = (record['status'] ?? '').toString().toLowerCase();
      return status == 'approved' || status == 'rejected';
    }).toList();
    final pendingSubmissions = widget.pendingRecords;

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionHeader(
            title: 'Dashboard',
            subtitle: 'Realtime snapshot of platform activity.',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _statCard(
                  title: 'Total Users',
                  value: widget.users.length.toString(),
                  icon: Icons.people_alt_rounded,
                  color: _primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  title: 'Total Records',
                  value: widget.records.length.toString(),
                  icon: Icons.recycling_rounded,
                  color: const Color(0xFF4A90D9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _statCard(
                  title: 'Total Stations',
                  value: totalStations.toString(),
                  icon: Icons.location_on_rounded,
                  color: const Color(0xFF4A90D9),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  title: 'Pending Reviews',
                  value: widget.pendingRecords.length.toString(),
                  icon: Icons.hourglass_top_rounded,
                  color: const Color(0xFFE39B35),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _statCard(
            title: 'Estimated Carbon Saved',
            value: '${totalCarbonSaved.toStringAsFixed(1)} kg CO2',
            icon: Icons.eco_rounded,
            color: const Color(0xFF66BB6A),
          ),
          const SizedBox(height: 20),
          _sectionHeader(
            title: 'Notification Overview',
            subtitle: 'Switch between key admin content sections.',
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _switchPill(
                  label: 'Recent Activity',
                  badgeCount: recentActivity.length,
                  icon: Icons.history_rounded,
                  color: const Color(0xFF4A90D9),
                  section: _DashboardSection.recentActivity,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _switchPill(
                  label: 'Processed Records',
                  badgeCount: processedRecords.length,
                  icon: Icons.task_alt_rounded,
                  color: const Color(0xFF3DAB6A),
                  section: _DashboardSection.processedRecords,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _switchPill(
                  label: 'Pending Submissions',
                  badgeCount: pendingSubmissions.length,
                  icon: Icons.hourglass_top_rounded,
                  color: const Color(0xFFE39B35),
                  section: _DashboardSection.pendingSubmissions,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._buildActiveContent(
            recentActivity: recentActivity,
            processedRecords: processedRecords,
            pendingSubmissions: pendingSubmissions,
          ),
        ],
      ),
    );
  }

  Widget _switchPill({
    required String label,
    required int badgeCount,
    required IconData icon,
    required Color color,
    required _DashboardSection section,
  }) {
    final isSelected = selectedSection == section;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() => selectedSection = section),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? color : const Color(0xFFE3EEE6),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0C000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(icon, color: color, size: 16),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      badgeCount.toString(),
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(
                  color: isSelected ? color : _ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildActiveContent({
    required List<Map<String, dynamic>> recentActivity,
    required List<Map<String, dynamic>> processedRecords,
    required List<Map<String, dynamic>> pendingSubmissions,
  }) {
    switch (selectedSection) {
      case _DashboardSection.recentActivity:
        return [
          _sectionHeader(
            title: 'Recent Activity',
            subtitle: 'Latest recycle submissions from Supabase.',
          ),
          const SizedBox(height: 12),
          if (recentActivity.isEmpty)
            _simpleSectionCard(
              title: 'No recent activity',
              child: Text(
                'No recycle records found yet.',
                style: GoogleFonts.dmSans(color: Colors.grey.shade600),
              ),
            )
          else
            ...recentActivity.map((record) {
              final submittedBy = (record['submitted_user'] ??
                      record['user_email'] ??
                      record['user_id'] ??
                      '-')
                  .toString();
              return _simpleSectionCard(
                title:
                    '${record['category'] ?? '-'} • ${record['weight_kg'] ?? '-'} kg',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Submitted by: $submittedBy',
                      style: GoogleFonts.dmSans(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Status: ${(record['status'] ?? 'pending').toString()}',
                      style: GoogleFonts.dmSans(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Date: ${(record['created_at']?.toString() ?? record['date']?.toString() ?? '-').split('T').first}',
                      style: GoogleFonts.dmSans(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              );
            }),
        ];
      case _DashboardSection.processedRecords:
        return [
          _sectionHeader(
            title: 'Processed Records',
            subtitle: 'Approved or rejected submissions.',
          ),
          const SizedBox(height: 12),
          if (processedRecords.isEmpty)
            _simpleSectionCard(
              title: 'No records yet',
              child: Text(
                'No approved/rejected records found.',
                style: GoogleFonts.dmSans(color: Colors.grey.shade600),
              ),
            )
          else
            ...processedRecords.map((record) {
              final status = (record['status'] ?? '').toString().toLowerCase();
              final statusColor = status == 'approved'
                  ? const Color(0xFF3DAB6A)
                  : const Color(0xFFE05454);
              return _simpleSectionCard(
                title: '${record['category']} - ${record['weight_kg']} kg',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _chip(
                          Icons.storefront_rounded,
                          (record['station'] ?? '-').toString(),
                          const Color(0xFFF7F9F8),
                          _ink,
                        ),
                        _chip(
                          status == 'approved'
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                          status.isEmpty ? 'unknown' : status,
                          statusColor.withValues(alpha: 0.12),
                          statusColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Date: ${(record['date']?.toString() ?? '-').split('T').first}',
                      style: GoogleFonts.dmSans(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              );
            }),
        ];
      case _DashboardSection.pendingSubmissions:
        return [
          _sectionHeader(
            title: 'Pending Submissions',
            subtitle: 'Approve or reject incoming records.',
          ),
          const SizedBox(height: 12),
          if (pendingSubmissions.isEmpty)
            _simpleSectionCard(
              title: 'All caught up',
              child: Text(
                'No pending submissions right now.',
                style: GoogleFonts.dmSans(color: Colors.grey.shade600),
              ),
            )
          else
            ...pendingSubmissions.map((record) {
              return _simpleSectionCard(
                title: '${record['category']} - ${record['weight_kg']} kg',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Station: ${record['station'] ?? '-'}',
                      style: GoogleFonts.dmSans(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Date: ${(record['date']?.toString() ?? '-').split('T').first}',
                      style: GoogleFonts.dmSans(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                widget.onModerateRecord(record, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3DAB6A),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.check_rounded, size: 16),
                            label: const Text('Approve'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                widget.onModerateRecord(record, false),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFE05454),
                              side: const BorderSide(color: Color(0xFFE05454)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.close_rounded, size: 16),
                            label: const Text('Reject'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ];
    }
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
