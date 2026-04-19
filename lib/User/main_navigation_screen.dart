import 'package:flutter/material.dart';

import 'dashboard_screen.dart';
import 'profile_screen.dart';
import 'recycle_map_screen.dart';
import 'recycle_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final List<int> _pageRefreshTokens = <int>[0, 0, 0, 0];

  List<Widget> _buildPages() {
    return <Widget>[
      DashboardScreen(key: ValueKey('dashboard-${_pageRefreshTokens[0]}')),
      RecyclePage(key: ValueKey('recycle-${_pageRefreshTokens[1]}')),
      ExplorePage(key: ValueKey('explore-${_pageRefreshTokens[2]}')),
      ProfilePage(key: ValueKey('profile-${_pageRefreshTokens[3]}')),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final pages = _buildPages();
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF2D7A4F),
        indicatorColor: const Color(0xFF7EEDB0),
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
                color: Color(0xFF1A4731), fontWeight: FontWeight.w700);
          }
          return const TextStyle(color: Colors.white70);
        }),
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          setState(() {
            if (_currentIndex == index) {
              _pageRefreshTokens[index]++;
            } else {
              _currentIndex = index;
            }
          });
        },
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.dashboard_rounded, color: Colors.white70),
            selectedIcon:
                Icon(Icons.dashboard_rounded, color: Color(0xFF1A4731)),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.recycling_rounded, color: Colors.white70),
            selectedIcon:
                Icon(Icons.recycling_rounded, color: Color(0xFF1A4731)),
            label: 'Recycle',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_rounded, color: Colors.white70),
            selectedIcon: Icon(Icons.explore_rounded, color: Color(0xFF1A4731)),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_rounded, color: Colors.white70),
            selectedIcon: Icon(Icons.person_rounded, color: Color(0xFF1A4731)),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class RecyclePage extends StatelessWidget {
  const RecyclePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const RecycleScreen();
  }
}

class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const RecycleMapScreen();
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProfileScreen();
  }
}
