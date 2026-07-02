import 'package:flutter/material.dart';
import '../config.dart';
import '../models.dart';
import '../api_service.dart';
import '../widgets/ticker_detail_sheet.dart';

Color _colorConfianza(double? v) {
  if (v == null) return const Color(AppColors.muted);
  if (v >= 0.70) return const Color(AppColors.green);
  if (v >= 0.55) return const Color(AppColors.amber);
  return const Color(AppColors.red);
}

class SignalsScreen extends StatefulWidget {
  const SignalsScreen({super.key});
  @override
  State<SignalsScreen> createState() => _SignalsScreenState();
}

class _SignalsScreenState extends State<SignalsScreen> {
  final _api = ApiService();
  bool _loading = true;
  String? _error;
  List<SignalRow> _signals = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final s = await _api.fetchSignals();
      setState(() {
        _signals = s;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _ErrorBox(message: _error!, onRetry: _load);
    if (_signals.isEmpty) return const Center(child: Text('No hay señales disponibles.', style: TextStyle(color: Color(AppColors.muted))));

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          const Text('Señales del Sistema', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          ..._signals.asMap().entries.map((entry) {
            final i = entry.key;
            final s = entry.value;
            return InkWell(
              onTap: () => showTickerDetail(context, s.ticker),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(color: const Color(AppColors.bgTile), borderRadius: BorderRadius.circular(14)),
                child: Row(children: [
                  SizedBox(width: 24, child: Text('${i + 1}', style: const TextStyle(color: Color(AppColors.mutedDark), fontSize: 12))),
                  Expanded(flex: 2, child: Text(s.ticker, style: const TextStyle(color: Color(AppColors.blue), fontWeight: FontWeight.w700, fontSize: 14))),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text(s.confidence != null ? s.confidence!.toStringAsFixed(3) : '—', style: TextStyle(color: _colorConfianza(s.confidence), fontWeight: FontWeight.bold, fontSize: 13)),
                      const Text('confianza', style: TextStyle(color: Color(AppColors.mutedDark), fontSize: 9)),
                    ]),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(s.qualityLabel, style: const TextStyle(color: Colors.white70, fontSize: 12), textAlign: TextAlign.right)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(s.recommendationLabel, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700), textAlign: TextAlign.right)),
                ]),
              ),
            );
          }),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBox({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('⚠ $message', style: const TextStyle(color: Color(0xFFFECACA)), textAlign: TextAlign.center),
          const SizedBox(height: 14),
          ElevatedButton(onPressed: onRetry, child: const Text('Reintentar')),
        ]),
      ),
    );
  }
}
