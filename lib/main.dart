import 'package:flutter/material.dart';
import 'screens/home_dashboard_screen.dart';

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
        scaffoldBackgroundColor: const Color(0xFF06101F),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF38BDF8),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomeDashboardScreen(),
    );
  }
}
