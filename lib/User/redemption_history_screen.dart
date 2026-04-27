import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class RedemptionHistoryScreen extends StatefulWidget {
  const RedemptionHistoryScreen({super.key});

  @override
  State<RedemptionHistoryScreen> createState() => _RedemptionHistoryScreenState();
}

class _RedemptionHistoryScreenState extends State<RedemptionHistoryScreen> with SingleTickerProviderStateMixin {
  final db = Supabase.instance.client;
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _allRedemptions = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final user = db.auth.currentUser;
      if (user == null) return;

      final data = await db
          .from('reward_redemptions')
          .select('*, admin_rewards(name)')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _allRedemptions = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Fetch Error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _generateRandomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(8, (index) => chars[Random().nextInt(chars.length)]).join();
  }

  void _showUseNowDialog(Map<String, dynamic> item) {
    final String tempCode = _generateRandomCode();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Redeem Voucher', textAlign: TextAlign.center, style: GoogleFonts.dmSans(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Show this code to the staff', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F6F2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF2D7A4F).withValues(alpha:0.2)),
              ),
              child: Text(
                tempCode,
                style: GoogleFonts.dmSans(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 3, color: const Color(0xFF1A4731)),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Once you click "Complete", this voucher is used.', textAlign: TextAlign.center, style: TextStyle(color: Colors.redAccent, fontSize: 11)),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(child: TextButton(onPressed: () => Navigator.pop(context), child: const Text('Back', style: TextStyle(color: Colors.grey)))),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2D7A4F), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: () async {
                    Navigator.pop(context);
                    await _completeRedemption(item['id'], tempCode);
                  },
                  child: const Text('Complete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _completeRedemption(dynamic id, String finalCode) async {
    setState(() => _isLoading = true);
    try {
      await db.from('reward_redemptions').update({
        'redemption_code': finalCode,
        'status': 'completed',
      }).eq('id', id);

      await _fetchHistory();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            elevation: 0,
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.transparent,
            content: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF2D7A4F),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2D7A4F).withValues(alpha:0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.white, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Success!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('Voucher used successfully!', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Update Error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red)
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    final activeVouchers = _allRedemptions.where((item) {
      final createdAt = DateTime.parse(item['created_at']).toLocal();
      final expiryDate = createdAt.add(const Duration(days: 7));
      return item['status'] == 'pending' && expiryDate.isAfter(now);
    }).toList();

    final pastVouchers = _allRedemptions.where((item) {
      final createdAt = DateTime.parse(item['created_at']).toLocal();
      final expiryDate = createdAt.add(const Duration(days: 7));
      return item['status'] == 'completed' || expiryDate.isBefore(now);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: Text('My Rewards', style: GoogleFonts.dmSans(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A4731),
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: () => Navigator.pop(context)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF2D7A4F),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF2D7A4F),
          tabs: const [Tab(text: 'Active'), Tab(text: 'Past')],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2D7A4F)))
          : TabBarView(
        controller: _tabController,
        children: [
          _buildList(activeVouchers, isActive: true),
          _buildList(pastVouchers, isActive: false),
        ],
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> list, {required bool isActive}) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('No records found', style: GoogleFonts.dmSans(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        final reward = item['admin_rewards'] ?? {};
        final createdAt = DateTime.parse(item['created_at']).toLocal();
        final expiryDate = createdAt.add(const Duration(days: 7));
        final remainingDays = expiryDate.difference(DateTime.now()).inDays;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.03), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _buildProviderIcon(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(reward['name'] ?? 'Reward', style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 15)),
                        Text('Redeemed on ${DateFormat('dd MMM yyyy').format(createdAt)}', style: const TextStyle(color: Colors.black, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24, thickness: 0.5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isActive ? 'Remaining Time' : 'Redemption Code', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                      const SizedBox(height: 2),
                      isActive
                          ? Text(remainingDays <= 0 ? 'Expires today' : '$remainingDays days left',
                          style: TextStyle(fontWeight: FontWeight.bold, color: remainingDays <= 1 ? Colors.red : Colors.black))
                          : Text(item['redemption_code'] ?? '------', style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, color: Colors.grey)),
                    ],
                  ),
                  isActive
                      ? ElevatedButton(
                    onPressed: () => _showUseNowDialog(item),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D7A4F),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    child: const Text('USE NOW', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  )
                      : _buildStatusBadge(item['status'], remainingDays),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(dynamic status, int daysLeft) {
    String displayStatus = 'USED';
    Color textColor = Colors.grey.shade500;

    if (daysLeft < 0 && status == 'pending') {
      displayStatus = 'EXPIRED';
      textColor = Colors.orange.shade800;
    } else if (status == 'completed') {
      displayStatus = 'USED';
      textColor = const Color(0xFF2D7A4F);
    }

    return Text(displayStatus, style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.bold));
  }

  Widget _buildProviderIcon() {
    return Container(
        padding: const EdgeInsets.all(10),
        decoration: const BoxDecoration(color: Color(0xFFF0F6F2), shape: BoxShape.circle),
        child: const Icon(Icons.card_giftcard_rounded, color: Color(0xFF2D7A4F), size: 20));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}