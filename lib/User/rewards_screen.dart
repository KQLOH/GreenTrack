import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RewardsScreen extends StatefulWidget {
  final int currentPoints;
  const RewardsScreen({super.key, required this.currentPoints});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _rewardsList = [];
  Map<String, int> _userRedemptionCounts = {};
  bool _isLoading = true;
  late int _displayPoints;

  @override
  void initState() {
    super.initState();
    _displayPoints = widget.currentPoints;
    _initData();
  }

  Future<void> _initData() async {
    await _fetchAdminRewards();
    await _fetchUserRedemptionCounts();
  }

  Future<void> _fetchAdminRewards() async {
    try {
      final data = await _supabase
          .from('admin_rewards')
          .select()
          .eq('is_active', true)
          .order('points_required', ascending: true);

      if (mounted) {
        setState(() {
          _rewardsList = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchUserRedemptionCounts() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final List<dynamic> data = await _supabase
          .from('reward_redemptions')
          .select('reward_id')
          .eq('user_id', user.id);

      Map<String, int> counts = {};
      for (var item in data) {
        String rid = item['reward_id'].toString();
        counts[rid] = (counts[rid] ?? 0) + 1;
      }

      if (mounted) {
        setState(() {
          _userRedemptionCounts = counts;
        });
      }
    } catch (e) {
      debugPrint('Error fetching user counts: $e');
    }
  }

  Future<void> _processRedemption(Map<String, dynamic> reward) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final String rewardId = reward['id'].toString();
    final int ptsRequired = (reward['points_required'] as num).toInt();
    final int maxPerUser = (reward['max_per_user'] as num?)?.toInt() ?? 0;
    final int currentUsed = _userRedemptionCounts[rewardId] ?? 0;

    if (maxPerUser > 0 && currentUsed >= maxPerUser) {
      _showErrorSnackBar("You've reached the maximum limit for this reward.");
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    try {
      // 1. Try to create the redemption record first.
      // We exclude 'status' to let DB use default 'pending', but include 'provider'.
      await _supabase.from('reward_redemptions').insert({
        'user_id': user.id,
        'reward_id': rewardId,
        'points_spent': ptsRequired,
        'quantity': 1,
        'provider': reward['provider']?.toString() ?? 'generic',
      });

      // 2. Deduction only occurs if the insert above succeeded.
      final newPoints = _displayPoints - ptsRequired;
      await _supabase.from('profiles').update({'total_points': newPoints}).eq('id', user.id);

      await _supabase.from('admin_rewards').update({
        'available_quantity': (reward['available_quantity'] as int) - 1,
        'redeemed_count': ((reward['redeemed_count'] as num?)?.toInt() ?? 0) + 1,
      }).eq('id', rewardId);

      if (mounted) {
        Navigator.pop(context);
        setState(() {
          _displayPoints = newPoints;
          _userRedemptionCounts[rewardId] = currentUsed + 1;
        });
        _showSuccessDialog(reward['name']);
        _fetchAdminRewards();
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showErrorSnackBar("Redeem failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context, _displayPoints);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAF9),
        appBar: AppBar(
          title: Text('Redeem Rewards', style: GoogleFonts.dmSans(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1A4731),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.pop(context, _displayPoints),
          ),
        ),
        body: Column(
          children: [
            _buildBalanceCard(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF2D7A4F)))
                  : _rewardsList.isEmpty ? _buildEmptyState() : _buildRewardsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity, margin: const EdgeInsets.all(20), padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1A4731), Color(0xFF2D7A4F)]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(children: [
        Text('Your Balance', style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 8),
        Text('$_displayPoints pts', style: GoogleFonts.dmSans(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _buildRewardsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _rewardsList.length,
      itemBuilder: (context, index) {
        final reward = _rewardsList[index];
        final String rid = reward['id'].toString();
        final pts = (reward['points_required'] as num?)?.toInt() ?? 0;
        final qty = (reward['available_quantity'] as num?)?.toInt() ?? 0;
        final maxPerUser = (reward['max_per_user'] as num?)?.toInt() ?? 0;
        final currentUsed = _userRedemptionCounts[rid] ?? 0;

        bool isExceededLimit = maxPerUser > 0 && currentUsed >= maxPerUser;
        bool canAfford = _displayPoints >= pts && qty > 0 && !isExceededLimit;

        return Container(
          margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade100)),
          child: Row(children: [
            _buildRewardIcon(reward['provider']?.toString()),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(reward['name'] ?? 'Unnamed', style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 15)),
              if (maxPerUser > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Limit: $currentUsed/$maxPerUser used',
                    style: TextStyle(
                        color: isExceededLimit ? Colors.red : Colors.blueGrey,
                        fontSize: 11,
                        fontWeight: FontWeight.w600
                    ),
                  ),
                ),
            ])),
            ElevatedButton(
              onPressed: canAfford ? () => _showConfirmDialog(reward) : null,
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D7A4F),
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
              ),
              child: Text(
                  isExceededLimit ? 'Limit Reached' : '$pts pts',
                  style: TextStyle(color: canAfford ? Colors.white : Colors.grey.shade600, fontSize: 11)
              ),
            ),
          ]),
        );
      },
    );
  }

  Widget _buildRewardIcon(String? p) {
    IconData icon = Icons.card_giftcard_rounded;
    if (p?.toLowerCase().contains('grab') ?? false) icon = Icons.local_taxi_rounded;
    return Container(width: 52, height: 52, decoration: BoxDecoration(color: const Color(0xFFF0F6F2), borderRadius: BorderRadius.circular(15)), child: Icon(icon, color: const Color(0xFF2D7A4F)));
  }

  void _showConfirmDialog(Map<String, dynamic> reward) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Redemption'),
        content: Text('Redeem ${reward['name']} for ${reward['points_required']} pts?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () { Navigator.pop(context); _processRedemption(reward); }, child: const Text('Confirm')),
        ],
      ),
    );
  }

  void _showSuccessDialog(String name) {
    showDialog(context: context, builder: (context) => AlertDialog(title: const Text('Success!'), content: Text('Redeemed $name successfully.'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))]));
  }

  void _showErrorSnackBar(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: Colors.red));
  Widget _buildEmptyState() => const Center(child: Text('No rewards available.'));
}
