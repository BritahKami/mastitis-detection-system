import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';
import 'alerts_screen.dart';
import 'dashboard_screen.dart';
import 'profile_screen.dart';

/// Main container shell coordinating bottom navigation state across
/// Dash (0), Alerts (1), and Profile (2).
class MainShellScreen extends StatefulWidget {
  final int initialIndex;

  const MainShellScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabSelected(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          DashboardScreen(
            showBottomNav: false,
            onTabSelected: _onTabSelected,
          ),
          AlertsScreen(
            showBottomNav: false,
            isActive: _currentIndex == 1,
            onTabSelected: _onTabSelected,
          ),
          ProfileScreen(
            showBottomNav: false,
            onTabSelected: _onTabSelected,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        activeIndex: _currentIndex,
        onTabSelected: _onTabSelected,
      ),
    );
  }
}
