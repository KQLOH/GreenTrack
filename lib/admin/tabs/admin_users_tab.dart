import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminUsersTab extends StatelessWidget {
  const AdminUsersTab({
    super.key,
    required this.users,
    required this.onRefresh,
  });

  static const Color _ink = Color(0xFF1A4731);
  static const Color _primary = Color(0xFF2D7A4F);

  final List<Map<String, dynamic>> users;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionHeader(
            title: 'Users',
            subtitle: 'Registered users and point balances.',
          ),
          const SizedBox(height: 12),
          if (users.isEmpty)
            _simpleSectionCard(
              title: 'No users',
              child: Text(
                'No profile records found.',
                style: GoogleFonts.dmSans(color: Colors.grey.shade600),
              ),
            )
          else
            ...users.map((user) {
              return _simpleSectionCard(
                title: user['username']?.toString() ?? 'Unknown',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Email: ${user['email'] ?? '-'}',
                      style: GoogleFonts.dmSans(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 6),
                    _chip(
                      Icons.workspace_premium_rounded,
                      'Points: ${user['total_points'] ?? 0}',
                      const Color(0xFFE8F5EE),
                      _primary,
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

