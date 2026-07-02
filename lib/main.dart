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

class _RootShellState extends State<RootShell> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Analysis NO es pestaña — se activa tocando un ticker (igual que en la web)
  static const _tabs = [
    'Global',
    'Universe',
    'Universe CL',
    'Signals',
    'Screener',
    'Portfolio',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.bg),
      appBar: AppBar(
        backgroundColor: const Color(0xFF081427),
        title: const Text('Predictiva'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: const Color(AppColors.blue),
          labelColor: Colors.white,
          unselectedLabelColor: const Color(AppColors.mutedDark),
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          GlobalScreen(),
          UniverseScreen(),
          UniverseScreen(filterChile: true),
          SignalsScreen(),
          ScreenerScreen(),
          PortfolioScreen(),
        ],
      ),
    );
  }
}
