import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminRecordsTab extends StatefulWidget {
  const AdminRecordsTab({
    super.key,
    required this.records,
    required this.totalRecords,
    required this.searchQuery,
    required this.isSavingRecord,
    required this.onSearchChanged,
    required this.onRefresh,
    required this.onEditRecord,
    required this.onDeleteRecord,
  });

  final List<Map<String, dynamic>> records;
  final int totalRecords;
  final String searchQuery;
  final bool isSavingRecord;
  final ValueChanged<String> onSearchChanged;
  final Future<void> Function() onRefresh;
  final Future<void> Function(Map<String, dynamic> record) onEditRecord;
  final Future<void> Function(Map<String, dynamic> record) onDeleteRecord;

  @override
  State<AdminRecordsTab> createState() => _AdminRecordsTabState();
}

class _AdminRecordsTabState extends State<AdminRecordsTab> {
  static const Color _ink = Color(0xFF1A4731);
  static const Color _primary = Color(0xFF2D7A4F);

  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
  }

  @override
  void didUpdateWidget(covariant AdminRecordsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery != widget.searchQuery &&
        _searchController.text != widget.searchQuery) {
      _searchController.text = widget.searchQuery;
      _searchController.selection = TextSelection.collapsed(
        offset: widget.searchQuery.length,
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionHeader(
            title: 'Records',
            subtitle: 'Manage all recycle records from Supabase.',
            action: _chip(
              Icons.dataset_rounded,
              'Total: ${widget.totalRecords}',
              const Color(0xFFE8F5EE),
              _primary,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            onChanged: widget.onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search by type, station, status, or user',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE3EEE6)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE3EEE6)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _primary, width: 1.2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (widget.records.isEmpty)
            _simpleSectionCard(
              title: 'No records',
              child: Text(
                widget.searchQuery.trim().isEmpty
                    ? 'No recycle records found.'
                    : 'No records match "${widget.searchQuery}".',
                style: GoogleFonts.dmSans(color: Colors.grey.shade600),
              ),
            )
          else
            ...widget.records.map((record) {
              final status = (record['status'] ?? 'pending').toString();
              final submittedBy = (record['submitted_user'] ??
                      record['user_email'] ??
                      record['user_id'] ??
                      '-')
                  .toString();
              final createdAt = (record['created_at'] ?? record['date'] ?? '-')
                  .toString()
                  .split('T')
                  .first;

              return _simpleSectionCard(
                title:
                    '${record['category'] ?? '-'} • ${record['weight_kg'] ?? '-'} kg',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _chip(
                          Icons.person_outline_rounded,
                          submittedBy,
                          const Color(0xFFF7F9F8),
                          _ink,
                        ),
                        _chip(
                          Icons.storefront_rounded,
                          (record['station'] ?? '-').toString(),
                          const Color(0xFFE8F1FB),
                          const Color(0xFF4A90D9),
                        ),
                        _chip(
                          Icons.info_outline_rounded,
                          status,
                          status.toLowerCase() == 'approved'
                              ? const Color(0xFFE8F5EE)
                              : status.toLowerCase() == 'rejected'
                                  ? const Color(0xFFFFF0F0)
                                  : const Color(0xFFFFF8E9),
                          status.toLowerCase() == 'approved'
                              ? const Color(0xFF3DAB6A)
                              : status.toLowerCase() == 'rejected'
                                  ? const Color(0xFFE05454)
                                  : const Color(0xFFE39B35),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Date: $createdAt',
                      style: GoogleFonts.dmSans(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: widget.isSavingRecord
                                ? null
                                : () => widget.onEditRecord(record),
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
                            onPressed: widget.isSavingRecord
                                ? null
                                : () => widget.onDeleteRecord(record),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFE05454),
                              side: const BorderSide(color: Color(0xFFE05454)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.delete_outline_rounded,
                                size: 16),
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
