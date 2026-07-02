import 'package:flutter/material.dart';
import '../config.dart';
import '../models.dart';
import '../api_service.dart';
import '../widgets/ticker_detail_sheet.dart';

String flagFor(String ticker) {
  final t = ticker.toUpperCase();
  if (t.endsWith('.SN') || t.endsWith('.SCL')) return '🇨🇱';
  if (t.endsWith('.MC')) return '🇪🇸';
  if (t.endsWith('.DE')) return '🇩🇪';
  if (t.endsWith('.PA')) return '🇫🇷';
  if (t.endsWith('.L')) return '🇬🇧';
  if (t.endsWith('.TO')) return '🇨🇦';
  return '🇺🇸';
}

Color colorScore(double? v) {
  if (v == null) return const Color(AppColors.muted);
  if (v >= 0.75) return const Color(AppColors.greenDark);
  if (v >= 0.70) return const Color(AppColors.green);
  if (v >= 0.55) return const Color(AppColors.amber);
  return const Color(AppColors.red);
}

Color colorMomentum(double? v) {
  if (v == null) return const Color(AppColors.muted);
  if (v >= 15) return const Color(AppColors.green);
  if (v >= 5) return const Color(AppColors.amber);
  return const Color(AppColors.red);
}

Color colorSharpe(double? v) {
  if (v == null) return const Color(AppColors.muted);
  if (v >= 2) return const Color(AppColors.green);
  if (v >= 1) return const Color(AppColors.amber);
  return const Color(AppColors.red);
}

Color colorRsi(double? v) {
  if (v == null) return const Color(AppColors.muted);
  if (v >= 70) return const Color(AppColors.red);
  if (v <= 30) return const Color(AppColors.green);
  return const Color(AppColors.muted);
}

class ScreenerScreen extends StatefulWidget {
  const ScreenerScreen({super.key});
  @override
  State<ScreenerScreen> createState() => _ScreenerScreenState();
}

class _ScreenerScreenState extends State<ScreenerScreen> {
  final _api = ApiService();
  bool _loading = true;
  String? _error;
  ScreenerSections? _sections;

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
      final s = await _api.fetchScreenerSections();
      setState(() {
        _sections = s;
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
    final s = _sections!;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          const Text('Screener', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 18),
          _Section(title: '🔥 Alta Convicción (Strict)', candidates: s.strict),
          const SizedBox(height: 22),
          _Section(title: '🌎 Top 20 Global', candidates: s.top20),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<ScreenerCandidate> candidates;
  const _Section({required this.title, required this.candidates});

  @override
  Widget build(BuildContext context) {
    if (candidates.isEmpty) {
      return Text('Sin datos para $title', style: const TextStyle(color: Color(AppColors.muted)));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Row(children: [
            Expanded(flex: 2, child: SizedBox()),
            Expanded(child: Text('Score', style: TextStyle(color: Color(AppColors.mutedDark), fontSize: 10), textAlign: TextAlign.right)),
            Expanded(child: Text('Mom 3M', style: TextStyle(color: Color(AppColors.mutedDark), fontSize: 10), textAlign: TextAlign.right)),
            Expanded(child: Text('Sharpe', style: TextStyle(color: Color(AppColors.mutedDark), fontSize: 10), textAlign: TextAlign.right)),
            Expanded(child: Text('RSI', style: TextStyle(color: Color(AppColors.mutedDark), fontSize: 10), textAlign: TextAlign.right)),
          ]),
        ),
        const SizedBox(height: 6),
        ...candidates.asMap().entries.map((entry) {
          final i = entry.key;
          final c = entry.value;
          final isTop3 = i < 3;
          final isElite = (c.score ?? 0) >= 0.75;
          return InkWell(
            onTap: () => showTickerDetail(context, c.ticker),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: isTop3 ? const Color(AppColors.green).withOpacity(0.06) : const Color(AppColors.bgTile),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(children: [
                Expanded(
                  flex: 2,
                  child: Text('${c.ticker} ${flagFor(c.ticker)}${isElite ? ' 🔥' : ''}', style: TextStyle(color: Colors.white, fontWeight: isTop3 ? FontWeight.w800 : FontWeight.w600, fontSize: 13)),
                ),
                Expanded(child: Text(c.score?.toStringAsFixed(3) ?? '—', style: TextStyle(color: colorScore(c.score), fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.right)),
                Expanded(child: Text(c.trend3mPct != null ? '${c.trend3mPct!.toStringAsFixed(1)}%' : '—', style: TextStyle(color: colorMomentum(c.trend3mPct), fontWeight: FontWeight.w600, fontSize: 12), textAlign: TextAlign.right)),
                Expanded(child: Text(c.sharpeRatio?.toStringAsFixed(2) ?? '—', style: TextStyle(color: colorSharpe(c.sharpeRatio), fontWeight: FontWeight.w600, fontSize: 12), textAlign: TextAlign.right)),
                Expanded(child: Text(c.rsiWilder?.toStringAsFixed(1) ?? '—', style: TextStyle(color: colorRsi(c.rsiWilder), fontWeight: FontWeight.w600, fontSize: 12), textAlign: TextAlign.right)),
              ]),
            ),
          );
        }),
      ],
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
