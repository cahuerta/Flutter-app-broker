import 'package:flutter/material.dart';
import 'config.dart';
import 'screens/global_screen.dart';
import 'screens/universe_screen.dart';
import 'screens/signals_screen.dart';
import 'screens/screener_screen.dart';
import 'screens/portfolio_screen.dart';

void main() {
  runApp(const PredictivaApp());
}

class PredictivaApp extends StatelessWidget {
  const PredictivaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Predictiva',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(AppColors.bg),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(AppColors.blue),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const RootShell(),
    );
  }
}

class RootShell extends StatefulWidget {
  const RootShell({super.key});
  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  static const _titles = ['Global', 'Universe', 'Universe CL', 'Signals', 'Screener', 'Portfolio'];

  final _screens = const [
    GlobalScreen(),
    UniverseScreen(),
    UniverseScreen(filterChile: true),
    SignalsScreen(),
    ScreenerScreen(),
    PortfolioScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.bg),
      appBar: AppBar(
        backgroundColor: const Color(0xFF081427),
        title: Text(_titles[_index]),
        elevation: 0,
      ),
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF081427),
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.show_chart, size: 20), label: 'Global'),
          NavigationDestination(icon: Icon(Icons.public, size: 20), label: 'Universe'),
          NavigationDestination(icon: Icon(Icons.flag, size: 20), label: 'U. CL'),
          NavigationDestination(icon: Icon(Icons.sensors, size: 20), label: 'Signals'),
          NavigationDestination(icon: Icon(Icons.filter_list, size: 20), label: 'Screener'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet, size: 20), label: 'Portfolio'),
        ],
      ),
    );
  }
}
