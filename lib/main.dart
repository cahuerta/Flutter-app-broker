import 'package:flutter/material.dart';
import 'config.dart';
import 'screens/radar_screen.dart';
import 'screens/cartera_screen.dart';

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
  static const _titles = ['Radar', 'Cartera'];

  final _screens = const [
    RadarScreen(),
    CarteraScreen(),
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
        destinations: const [
          NavigationDestination(icon: Icon(Icons.radar), label: 'Radar'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet), label: 'Cartera'),
        ],
      ),
    );
  }
}
