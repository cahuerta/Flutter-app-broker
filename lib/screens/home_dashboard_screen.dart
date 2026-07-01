// =========================================================
// home_dashboard_screen.dart
// Dashboard interactivo: fondos + screener con filtros en vivo
// Usa SOLO endpoints existentes:
//   GET /trading/status
//   GET /trading/positions
//   GET /dashboard/screener
// Filtrado (score, sharpe, RSI) se hace 100% en el cliente,
// no pega al backend de nuevo al mover los sliders.
// =========================================================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// =========================================================
// CONFIG — reemplaza por tu URL real de Render
// =========================================================
class ApiConfig {
  static const String baseUrl = 'https://spy-2w-price-prediction.onrender.com';
}

// =========================================================
// MODELOS
// =========================================================
class ScreenerCandidate {
  final String ticker;
  final double? score;
  final double? trend3mPct;
  final double? sharpeRatio;
  final double? rsiWilder;
  final double? maxDrawdownPct;

  ScreenerCandidate({
    required this.ticker,
    this.score,
    this.trend3mPct,
    this.sharpeRatio,
    this.rsiWilder,
    this.maxDrawdownPct,
  });

  factory ScreenerCandidate.fromJson(Map<String, dynamic> j) {
    double? f(dynamic v) => v == null ? null : (v as num).toDouble();
    return ScreenerCandidate(
      ticker: (j['ticker'] ?? '').toString(),
      score: f(j['score']),
      trend3mPct: f(j['trend_3m_pct']),
      sharpeRatio: f(j['sharpe_ratio']),
      rsiWilder: f(j['rsi_wilder']),
      maxDrawdownPct: f(j['max_drawdown_pct']),
    );
  }
}

class PortfolioStatus {
  final double? equity;
  final double? buyingPower;
  final bool paper;
  final bool tradingBlocked;

  PortfolioStatus({
    this.equity,
    this.buyingPower,
    this.paper = true,
    this.tradingBlocked = false,
  });

  factory PortfolioStatus.fromJson(Map<String, dynamic> j) {
    double? f(dynamic v) => v == null ? null : (v as num).toDouble();
    return PortfolioStatus(
      equity: f(j['equity']),
      buyingPower: f(j['buying_power']),
      paper: j['paper'] ?? true,
      tradingBlocked: j['trading_blocked'] ?? false,
    );
  }
}

// =========================================================
// API SERVICE
// =========================================================
class PredictivaApi {
  Future<List<ScreenerCandidate>> fetchScreener() async {
    final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/dashboard/screener'));
    if (res.statusCode != 200) {
      throw Exception('Screener HTTP ${res.statusCode}');
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final strict = (json['candidates_strict'] as List?) ?? [];
    final top20 = (json['top20_global'] as List?) ?? [];

    final seen = <String>{};
    final all = <ScreenerCandidate>[];
    for (final raw in [...strict, ...top20]) {
      final c = ScreenerCandidate.fromJson(raw as Map<String, dynamic>);
      if (c.ticker.isEmpty || seen.contains(c.ticker)) continue;
      seen.add(c.ticker);
      all.add(c);
    }
    all.sort((a, b) => (b.score ?? -1).compareTo(a.score ?? -1));
    return all;
  }

  Future<PortfolioStatus> fetchStatus() async {
    final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/trading/status'));
    if (res.statusCode != 200) throw Exception('Status HTTP ${res.statusCode}');
    return PortfolioStatus.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<int> fetchPositionsCount() async {
    final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/trading/positions'));
    if (res.statusCode != 200) return 0;
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return json.length;
  }
}

// =========================================================
// HELPERS DE COLOR / BANDERA (equivalentes a Screener.jsx)
// =========================================================
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
  if (v == null) return const Color(0xFF94A3B8);
  if (v >= 0.75) return const Color(0xFF16A34A);
  if (v >= 0.70) return const Color(0xFF22C55E);
  if (v >= 0.55) return const Color(0xFFEAB308);
  return const Color(0xFFEF4444);
}

Color colorSharpe(double? v) {
  if (v == null) return const Color(0xFF94A3B8);
  if (v >= 2) return const Color(0xFF22C55E);
  if (v >= 1) return const Color(0xFFEAB308);
  return const Color(0xFFEF4444);
}

Color colorRsi(double? v) {
  if (v == null) return const Color(0xFF94A3B8);
  if (v >= 70) return const Color(0xFFEF4444);
  if (v <= 30) return const Color(0xFF22C55E);
  return const Color(0xFF94A3B8);
}

Color colorMomentum(double? v) {
  if (v == null) return const Color(0xFF94A3B8);
  if (v >= 15) return const Color(0xFF22C55E);
  if (v >= 5) return const Color(0xFFEAB308);
  return const Color(0xFFEF4444);
}

// =========================================================
// PANTALLA PRINCIPAL
// =========================================================
class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  final _api = PredictivaApi();

  bool _loading = true;
  String? _error;

  List<ScreenerCandidate> _candidates = [];
  PortfolioStatus? _status;
  int _positionsCount = 0;

  // Filtros en vivo (100% cliente, sin llamadas nuevas al backend)
  double _minScore = 0.0;
  double _minSharpe = 0.0;
  double _maxRsi = 100.0;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _api.fetchScreener(),
        _api.fetchStatus(),
        _api.fetchPositionsCount(),
      ]);
      setState(() {
        _candidates = results[0] as List<ScreenerCandidate>;
        _status = results[1] as PortfolioStatus;
        _positionsCount = results[2] as int;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<ScreenerCandidate> get _filtered {
    return _candidates.where((c) {
      final score = c.score ?? -1;
      final sharpe = c.sharpeRatio ?? -1;
      final rsi = c.rsiWilder ?? 50;
      return score >= _minScore && sharpe >= _minSharpe && rsi <= _maxRsi;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF06101F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF081427),
        title: const Text('Predictiva · Home'),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorBox(message: _error!, onRetry: _loadAll)
              : RefreshIndicator(
                  onRefresh: _loadAll,
                  child: ListView(
                    padding: const EdgeInsets.all(14),
                    children: [
                      _FundsCard(
                        status: _status,
                        positionsCount: _positionsCount,
                      ),
                      const SizedBox(height: 20),
                      _FilterPanel(
                        minScore: _minScore,
                        minSharpe: _minSharpe,
                        maxRsi: _maxRsi,
                        onScoreChanged: (v) => setState(() => _minScore = v),
                        onSharpeChanged: (v) => setState(() => _minSharpe = v),
                        onRsiChanged: (v) => setState(() => _maxRsi = v),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${_filtered.length} de ${_candidates.length} tickers',
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                      ),
                      const SizedBox(height: 10),
                      if (_filtered.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            'Ningún ticker cumple estos filtros.',
                            style: TextStyle(color: Color(0xFF94A3B8)),
                          ),
                        )
                      else
                        ..._filtered.map((c) => _TickerTile(candidate: c)),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
    );
  }
}

// =========================================================
// CARD DE FONDOS
// =========================================================
class _FundsCard extends StatelessWidget {
  final PortfolioStatus? status;
  final int positionsCount;

  const _FundsCard({required this.status, required this.positionsCount});

  String _fmt$(double? v) {
    if (v == null) return '—';
    return '\$${v.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => '.',
    )}';
  }

  @override
  Widget build(BuildContext context) {
    final blocked = status?.tradingBlocked ?? false;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF162338),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('💼 Mis Fondos',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: blocked ? const Color(0xFFEF4444).withOpacity(0.15) : const Color(0xFF22C55E).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  blocked ? '🔒 Bloqueado' : '✓ Activo',
                  style: TextStyle(color: blocked ? const Color(0xFFEF4444) : const Color(0xFF22C55E), fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _Stat(label: 'Capital', value: _fmt$(status?.equity))),
              Expanded(child: _Stat(label: 'Buying Power', value: _fmt$(status?.buyingPower))),
              Expanded(child: _Stat(label: 'Posiciones', value: '$positionsCount')),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

// =========================================================
// PANEL DE FILTROS (sliders en vivo)
// =========================================================
class _FilterPanel extends StatelessWidget {
  final double minScore;
  final double minSharpe;
  final double maxRsi;
  final ValueChanged<double> onScoreChanged;
  final ValueChanged<double> onSharpeChanged;
  final ValueChanged<double> onRsiChanged;

  const _FilterPanel({
    required this.minScore,
    required this.minSharpe,
    required this.maxRsi,
    required this.onScoreChanged,
    required this.onSharpeChanged,
    required this.onRsiChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      decoration: BoxDecoration(
        color: const Color(0xFF162338),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          _SliderRow(
            label: 'Score mínimo',
            value: minScore,
            display: minScore.toStringAsFixed(2),
            min: 0,
            max: 1,
            activeColor: colorScore(minScore),
            onChanged: onScoreChanged,
          ),
          _SliderRow(
            label: 'Sharpe mínimo',
            value: minSharpe,
            display: minSharpe.toStringAsFixed(1),
            min: 0,
            max: 3,
            activeColor: colorSharpe(minSharpe),
            onChanged: onSharpeChanged,
          ),
          _SliderRow(
            label: 'RSI máximo',
            value: maxRsi,
            display: maxRsi.toStringAsFixed(0),
            min: 0,
            max: 100,
            activeColor: colorRsi(maxRsi),
            onChanged: onRsiChanged,
          ),
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final double value;
  final String display;
  final double min;
  final double max;
  final Color activeColor;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.display,
    required this.min,
    required this.max,
    required this.activeColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
            Text(display, style: TextStyle(color: activeColor, fontSize: 13, fontWeight: FontWeight.w700)),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: activeColor,
            inactiveTrackColor: Colors.white.withOpacity(0.08),
            thumbColor: activeColor,
            overlayColor: activeColor.withOpacity(0.2),
            trackHeight: 3,
          ),
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
      ],
    );
  }
}

// =========================================================
// TARJETA DE TICKER (tap → detalle rápido, sin nuevo endpoint)
// =========================================================
class _TickerTile extends StatelessWidget {
  final ScreenerCandidate candidate;
  const _TickerTile({required this.candidate});

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF162338),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${candidate.ticker} ${flagFor(candidate.ticker)}',
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            _DetailRow('Score', candidate.score?.toStringAsFixed(3), colorScore(candidate.score)),
            _DetailRow('Momentum 3M', candidate.trend3mPct != null ? '${candidate.trend3mPct!.toStringAsFixed(2)}%' : null, colorMomentum(candidate.trend3mPct)),
            _DetailRow('Sharpe', candidate.sharpeRatio?.toStringAsFixed(2), colorSharpe(candidate.sharpeRatio)),
            _DetailRow('RSI', candidate.rsiWilder?.toStringAsFixed(1), colorRsi(candidate.rsiWilder)),
            _DetailRow('Drawdown Máx', candidate.maxDrawdownPct != null ? '${candidate.maxDrawdownPct!.toStringAsFixed(2)}%' : null, const Color(0xFFEF4444)),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isElite = (candidate.score ?? 0) >= 0.75;
    return InkWell(
      onTap: () => _showDetail(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF12203A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isElite ? const Color(0xFF22C55E).withOpacity(0.3) : Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                '${candidate.ticker} ${flagFor(candidate.ticker)}${isElite ? ' 🔥' : ''}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
            Expanded(
              child: Text(
                candidate.score?.toStringAsFixed(2) ?? '—',
                style: TextStyle(color: colorScore(candidate.score), fontWeight: FontWeight.w700),
                textAlign: TextAlign.right,
              ),
            ),
            Expanded(
              child: Text(
                candidate.sharpeRatio?.toStringAsFixed(1) ?? '—',
                style: TextStyle(color: colorSharpe(candidate.sharpeRatio), fontWeight: FontWeight.w600),
                textAlign: TextAlign.right,
              ),
            ),
            Expanded(
              child: Text(
                candidate.rsiWilder?.toStringAsFixed(0) ?? '—',
                style: TextStyle(color: colorRsi(candidate.rsiWilder), fontWeight: FontWeight.w600),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String? value;
  final Color color;
  const _DetailRow(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF94A3B8))),
          Text(value ?? '—', style: TextStyle(color: color, fontWeight: FontWeight.w700)),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('⚠ $message', style: const TextStyle(color: Color(0xFFFECACA)), textAlign: TextAlign.center),
            const SizedBox(height: 14),
            ElevatedButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
