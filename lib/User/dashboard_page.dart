import 'package:flutter/material.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final List<_SummaryData> _summaryItems = const <_SummaryData>[
    _SummaryData(
      title: 'Recycled Weight',
      value: '128.4 kg',
      icon: Icons.recycling,
      color: Color(0xFF4CAF50),
    ),
    _SummaryData(
      title: 'Carbon Saved',
      value: '78.2 kg CO2',
      icon: Icons.eco,
      color: Color(0xFF2E7D32),
    ),
    _SummaryData(
      title: 'Monthly Goal',
      value: '64%',
      icon: Icons.flag_rounded,
      color: Color(0xFF66BB6A),
    ),
    _SummaryData(
      title: 'Nearby Stations',
      value: '5 spots',
      icon: Icons.place_rounded,
      color: Color(0xFF43A047),
    ),
  ];

  final List<_ActivityData> _recentActivity = const <_ActivityData>[
    _ActivityData(
      title: 'Plastic bottles recycled',
      subtitle: 'Today, 10:24 AM',
      trailing: '+3.5 kg',
      icon: Icons.local_drink_rounded,
    ),
    _ActivityData(
      title: 'Paper drop-off completed',
      subtitle: 'Yesterday, 4:05 PM',
      trailing: '+2.1 kg',
      icon: Icons.description_rounded,
    ),
    _ActivityData(
      title: 'Aluminum cans collected',
      subtitle: '2 days ago, 2:15 PM',
      trailing: '+1.8 kg',
      icon: Icons.local_cafe_rounded,
    ),
  ];

  final List<double> _weeklyValues = const <double>[32, 48, 24, 60, 44, 52, 36];
  final List<String> _weekLabels = const <String>[
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun'
  ];

  @override
  Widget build(BuildContext context) {
    const Color backgroundColor = Color(0xFFF4FAF4);
    const Color primaryGreen = Color(0xFF2E7D32);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('GreenTrack'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: primaryGreen,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Welcome back 👋',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1B5E20),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Track your impact and keep the planet greener every day.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.green.shade700,
                ),
              ),
              const SizedBox(height: 18),
              _buildSummaryGrid(),
              const SizedBox(height: 20),
              _buildSectionTitle('Analytics'),
              const SizedBox(height: 10),
              _buildWeeklyChartCard(),
              const SizedBox(height: 12),
              _buildAnalyticsRow(),
              const SizedBox(height: 20),
              _buildSectionTitle('Recent Activity'),
              const SizedBox(height: 10),
              _buildRecentActivityCard(),
              const SizedBox(height: 20),
              _buildNavigationButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryGrid() {
    return GridView.builder(
      itemCount: _summaryItems.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemBuilder: (BuildContext context, int index) {
        final _SummaryData item = _summaryItems[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x11000000),
                blurRadius: 12,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: item.color, size: 22),
              ),
              const Spacer(),
              Text(
                item.value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1B5E20),
      ),
    );
  }

  Widget _buildWeeklyChartCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Weekly Recycling Trend',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.green.shade800,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children:
                  List<Widget>.generate(_weeklyValues.length, (int index) {
                final double value = _weeklyValues[index];
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    Container(
                      width: 22,
                      height: value,
                      decoration: BoxDecoration(
                        color: const Color(0xFF66BB6A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _weekLabels[index],
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsRow() {
    return Row(
      children: <Widget>[
        Expanded(
          child: _buildMiniAnalyticsCard(
            icon: Icons.trending_up_rounded,
            title: 'Best Day',
            value: 'Thu',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMiniAnalyticsCard(
            icon: Icons.bolt_rounded,
            title: 'Avg / Day',
            value: '4.6 kg',
          ),
        ),
      ],
    );
  }

  Widget _buildMiniAnalyticsCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF2E7D32), size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: List<Widget>.generate(_recentActivity.length, (int index) {
          final _ActivityData item = _recentActivity[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF2E7D32).withValues(alpha: 0.12),
              child: Icon(item.icon, color: const Color(0xFF2E7D32), size: 20),
            ),
            title: Text(
              item.title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF1B5E20),
              ),
            ),
            subtitle: Text(
              item.subtitle,
              style: TextStyle(color: Colors.green.shade700),
            ),
            trailing: Text(
              item.trailing,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      children: <Widget>[
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Analytics page - Coming soon'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(Icons.trending_up_rounded, size: 18),
                SizedBox(width: 8),
                Text('Analytics'),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Map page - Coming soon'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF66BB6A),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(Icons.map_rounded, size: 18),
                SizedBox(width: 8),
                Text('Map'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryData {
  const _SummaryData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
}

class _ActivityData {
  const _ActivityData({
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String trailing;
  final IconData icon;
}
