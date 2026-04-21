import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminUsersTab extends StatefulWidget {
  const AdminUsersTab({
    super.key,
    required this.users,
    required this.totalUsers,
    required this.totalAdmins,
    required this.searchQuery,
    required this.roleFilter,
    required this.onSearchChanged,
    required this.onRoleFilterChanged,
    required this.isUpdatingUser,
    required this.onToggleAdmin,
    required this.onEditUser,
    required this.onDeleteUser,
    required this.onRefresh,
  });

  final List<Map<String, dynamic>> users;
  final int totalUsers;
  final int totalAdmins;
  final String searchQuery;
  final String roleFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onRoleFilterChanged;
  final bool isUpdatingUser;
  final Future<void> Function(Map<String, dynamic> user, bool isAdmin)
  onToggleAdmin;
  final Future<void> Function(Map<String, dynamic> user) onEditUser;
  final Future<void> Function(Map<String, dynamic> user) onDeleteUser;
  final Future<void> Function() onRefresh;

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> {
  static const Color _ink = Color(0xFF1A4731);
  static const Color _primary = Color(0xFF2D7A4F);

  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
  }

  @override
  void didUpdateWidget(covariant AdminUsersTab oldWidget) {
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
            title: 'Users',
            subtitle: 'Registered users and point balances.',
            action: _chip(
              Icons.groups_rounded,
              '${widget.totalAdmins} admin${widget.totalAdmins == 1 ? '' : 's'} / ${widget.totalUsers} users',
              const Color(0xFFE8F5EE),
              _primary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: widget.onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search by username, email, or role',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                      const BorderSide(color: Color(0xFFE3EEE6)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                      const BorderSide(color: Color(0xFFE3EEE6)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                      const BorderSide(color: _primary, width: 1.2),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _openRoleFilterSheet,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _ink,
                  side: const BorderSide(color: Color(0xFFD4E6D8)),
                  backgroundColor:
                  widget.roleFilter == 'all' ? Colors.white : const Color(0xFFE8F5EE),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
                icon: const Icon(Icons.tune_rounded, size: 18),
                label: Text(_roleLabel(widget.roleFilter)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (widget.users.isEmpty)
            _simpleSectionCard(
              title: 'No users',
              child: Text(
                widget.searchQuery.trim().isEmpty
                    ? 'No profile records found.'
                    : 'No users match "${widget.searchQuery}".',
                style: GoogleFonts.dmSans(color: Colors.grey.shade600),
              ),
            )
          else
            ...widget.users.map((user) {
              final isAdmin = user['is_admin'] == true ||
                  (user['role'] ?? '').toString().toLowerCase() == 'admin';
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
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _chip(
                          Icons.workspace_premium_rounded,
                          'Points: ${user['total_points'] ?? 0}',
                          const Color(0xFFE8F5EE),
                          _primary,
                        ),
                        _chip(
                          isAdmin
                              ? Icons.verified_rounded
                              : Icons.person_rounded,
                          isAdmin ? 'Admin' : 'User',
                          isAdmin
                              ? const Color(0xFFE8F1FB)
                              : const Color(0xFFF7F9F8),
                          isAdmin ? const Color(0xFF4A90D9) : _ink,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: widget.isUpdatingUser
                                ? null
                                : () => widget.onEditUser(user),
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
                            onPressed: widget.isUpdatingUser
                                ? null
                                : () => widget.onDeleteUser(user),
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
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextButton.icon(
                            onPressed: widget.isUpdatingUser
                                ? null
                                : () => widget.onToggleAdmin(user, !isAdmin),
                            style: TextButton.styleFrom(
                              foregroundColor:
                              isAdmin ? const Color(0xFFE05454) : _primary,
                            ),
                            icon: Icon(
                              isAdmin
                                  ? Icons.remove_moderator_rounded
                                  : Icons.verified_user_rounded,
                              size: 16,
                            ),
                            label: Text(
                              isAdmin ? 'Remove' : 'Admin',
                            ),
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

  Future<void> _openRoleFilterSheet() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _roleFilterOption(sheetContext, 'all', 'All roles'),
              _roleFilterOption(sheetContext, 'admin', 'Admin only'),
              _roleFilterOption(sheetContext, 'user', 'User only'),
            ],
          ),
        );
      },
    );

    if (selected != null && selected != widget.roleFilter) {
      widget.onRoleFilterChanged(selected);
    }
  }

  Widget _roleFilterOption(BuildContext sheetContext, String value, String label) {
    final selected = widget.roleFilter == value;
    return ListTile(
      onTap: () => Navigator.pop(sheetContext, value),
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_off,
        color: selected ? _primary : Colors.grey.shade500,
      ),
      title: Text(
        label,
        style: GoogleFonts.dmSans(
          color: _ink,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }

  String _roleLabel(String filter) {
    switch (filter) {
      case 'admin':
        return 'Admin';
      case 'user':
        return 'User';
      default:
        return 'Filter';
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
