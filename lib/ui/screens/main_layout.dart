import 'package:flutter/material.dart';
import 'haircut/haircuts_screen.dart';
import 'daily_income/daily_income_screen.dart';
import 'worker_account/worker_account_screen.dart';
import 'statistics/statistics_screen.dart';
import 'settings/settings_screen.dart';

class MainLayoutScreen extends StatefulWidget {
  @override
  _MainLayoutScreenState createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    HaircutsScreen(),
    DailyIncomeScreen(),
    WorkerAccountScreen(),
    StatisticsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.content_cut_outlined), selectedIcon: Icon(Icons.content_cut), label: 'الحلاقات'),
          NavigationDestination(icon: Icon(Icons.attach_money_outlined), selectedIcon: Icon(Icons.attach_money), label: 'الدخل اليومي'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: 'حسابي'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'الإحصائيات'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'الإعدادات'),
        ],
      ),
    );
  }
}
