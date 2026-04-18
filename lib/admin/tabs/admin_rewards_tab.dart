import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminRewardsTab extends StatelessWidget {
  const AdminRewardsTab({
    super.key,
    required this.rewards,
    required this.totalRedemptions,
    required this.rewardsLoadError,
    required this.isSavingReward,
    required this.onRefresh,
    required this.onAddReward,
    required this.onEditReward,
    required this.onDeleteReward,
    required this.onToggleReward,
  });

  static const Color _primary = Color(0xFF2D7A4F);
  static const Color _ink = Color(0xFF1A4731);

  final List<Map<String, dynamic>> rewards;
  final int totalRedemptions;
  final String? rewardsLoadError;
  final bool isSavingReward;
  final Future<void> Function() onRefresh;
  final VoidCallback onAddReward;
  final Future<void> Function(Map<String, dynamic> reward) onEditReward;
  final Future<void> Function(Map<String, dynamic> reward) onDeleteReward;
  final Future<void> Function(Map<String, dynamic> reward) onToggleReward;

  @override
  Widget build(BuildContext context) {
    final totalRewards = rewards.length;
    final activeRewards = rewards.where((reward) {
      return reward['is_active'] == null || reward['is_active'] == true;
    }).length;
    final availableItems = rewards.fold<int>(0, (sum, reward) {
      return sum + ((reward['available_quantity'] as num?)?.toInt() ?? 0);
    });

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionHeader(
            title: 'Rewards',
            subtitle: 'Manage redemption rewards and inventory.',
            action: ElevatedButton.icon(
              onPressed: isSavingReward ? null : onAddReward,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Add Reward'),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _statCard(
                  title: 'Total Rewards',
                  value: totalRewards.toString(),
                  icon: Icons.card_giftcard_rounded,
                  color: _primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  title: 'Active Rewards',
                  value: activeRewards.toString(),
                  icon: Icons.toggle_on_rounded,
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
                  title: 'Total Redemptions',
                  value: totalRedemptions.toString(),
                  icon: Icons.shopping_bag_rounded,
                  color: const Color(0xFFE39B35),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  title: 'Available Items',
                  value: availableItems.toString(),
                  icon: Icons.inventory_2_rounded,
                  color: const Color(0xFF3DAB6A),
                ),
              ),
            ],
          ),
          if (rewardsLoadError != null) ...[
            const SizedBox(height: 12),
            _simpleSectionCard(
              title: 'Rewards Table Issue',
              child: Text(
                rewardsLoadError!,
                style: GoogleFonts.dmSans(
                  color: const Color(0xFFE05454),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (rewards.isEmpty)
            _simpleSectionCard(
              title: 'No rewards',
              child: Text(
                'No reward records found in Supabase.',
                style: GoogleFonts.dmSans(color: Colors.grey.shade600),
              ),
            )
          else
            ...rewards.map((reward) {
              final isActive = reward['is_active'] == null
                  ? true
                  : reward['is_active'] == true;
              final pointsRequired =
                  ((reward['points_required'] as num?)?.toInt() ?? 0);
              final availableQuantity =
                  ((reward['available_quantity'] as num?)?.toInt() ?? 0);
              final redeemedCount =
                  ((reward['redeemed_count'] as num?)?.toInt() ?? 0);

              return _simpleSectionCard(
                title: reward['name']?.toString() ?? 'Unnamed Reward',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (reward['description'] ?? '-').toString(),
                      style: GoogleFonts.dmSans(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _chip(
                          Icons.workspace_premium_rounded,
                          '$pointsRequired pts',
                          const Color(0xFFE8F5EE),
                          _primary,
                        ),
                        _chip(
                          isActive
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                          isActive ? 'On' : 'Off',
                          isActive
                              ? const Color(0xFFE8F5EE)
                              : const Color(0xFFFFF0F0),
                          isActive
                              ? const Color(0xFF3DAB6A)
                              : const Color(0xFFE05454),
                        ),
                        _chip(
                          Icons.inventory_rounded,
                          'Qty: $availableQuantity',
                          const Color(0xFFE8F1FB),
                          const Color(0xFF4A90D9),
                        ),
                        _chip(
                          Icons.shopping_cart_checkout_rounded,
                          'Redeemed: $redeemedCount',
                          const Color(0xFFFFF8E9),
                          const Color(0xFFE39B35),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: isSavingReward
                                ? null
                                : () => onEditReward(reward),
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
                            onPressed: isSavingReward
                                ? null
                                : () => onDeleteReward(reward),
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
                          child: OutlinedButton.icon(
                            onPressed: isSavingReward
                                ? null
                                : () => onToggleReward(reward),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF4A90D9),
                              side: const BorderSide(color: Color(0xFF4A90D9)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: Icon(
                              isActive
                                  ? Icons.toggle_off_rounded
                                  : Icons.toggle_on_rounded,
                              size: 16,
                            ),
                            label: Text(isActive ? 'Turn Off' : 'Turn On'),
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
