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

class RadarScreen extends StatefulWidget {
  const RadarScreen({super.key});
  @override
  State<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends State<RadarScreen> {
  final _api = ApiService();
  bool _loading = true;
  String? _error;

  PerformanceData? _perf;
  ModelQuality? _model;
  List<ScreenerCandidate> _candidates = [];

  double _minScore = 0.55;
  double _minSharpe = 0.0;
  double _maxRsi = 100.0;

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
      final results = await Future.wait([
        _api.fetchPerformance(),
        _api.fetchModelQuality(),
        _api.fetchScreener(),
      ]);
      setState(() {
        _perf = results[0] as PerformanceData;
        _model = results[1] as ModelQuality;
        _candidates = results[2] as List<ScreenerCandidate>;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<ScreenerCandidate> get _filtered => _candidates.where((c) {
        final score = c.score ?? -1;
        final sharpe = c.sharpeRatio ?? -1;
        final rsi = c.rsiWilder ?? 50;
        return score >= _minScore && sharpe >= _minSharpe && rsi <= _maxRsi;
      }).toList();

  String _fmt$(double? v) => v == null ? '—' : '\$${v.round()}';
  String _fmtPct(double? v) => v == null ? '—' : '${v.toStringAsFixed(2)}%';

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _ErrorBox(message: _error!, onRetry: _load);

    final totalReturn = _perf?.totalReturnPct;
    final returnColor = totalReturn == null ? Colors.white : totalReturn >= 0 ? const Color(AppColors.green) : const Color(AppColors.red);
    final hit = _model?.hitRateDirectionPct;
    final hitColor = hit == null ? const Color(AppColors.muted) : hit >= 55 ? const Color(AppColors.green) : hit >= 45 ? const Color(AppColors.orange) : const Color(AppColors.red);
    final f = _filtered;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          // ── Capital + hit rate, compacto ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(AppColors.bgCard), borderRadius: BorderRadius.circular(18)),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('CAPITAL', style: TextStyle(color: Color(AppColors.mutedDark), fontSize: 11)),
                  Text(_fmt$(_perf?.equity), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  Text(_fmtPct(totalReturn), style: TextStyle(color: returnColor, fontSize: 13, fontWeight: FontWeight.w600)),
                ]),
              ),
              Container(width: 1, height: 40, color: Colors.white12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('HIT RATE', style: TextStyle(color: Color(AppColors.mutedDark), fontSize: 11)),
                    Text(hit != null ? '${hit.toStringAsFixed(1)}%' : '—', style: TextStyle(color: hitColor, fontSize: 20, fontWeight: FontWeight.bold)),
                    Text('${_model?.evaluated ?? 0} evaluadas', style: const TextStyle(color: Color(AppColors.mutedDark), fontSize: 12)),
                  ]),
                ),
              ),
            ]),
          ),

          const SizedBox(height: 16),

          // ── Filtros interactivos ──
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            decoration: BoxDecoration(color: const Color(AppColors.bgCard), borderRadius: BorderRadius.circular(18)),
            child: Column(children: [
              _SliderRow(label: 'Score mínimo', value: _minScore, display: _minScore.toStringAsFixed(2), min: 0, max: 1, color: colorScore(_minScore), onChanged: (v) => setState(() => _minScore = v)),
              _SliderRow(label: 'Sharpe mínimo', value: _minSharpe, display: _minSharpe.toStringAsFixed(1), min: 0, max: 3, color: colorSharpe(_minSharpe), onChanged: (v) => setState(() => _minSharpe = v)),
              _SliderRow(label: 'RSI máximo', value: _maxRsi, display: _maxRsi.toStringAsFixed(0), min: 0, max: 100, color: colorRsi(_maxRsi), onChanged: (v) => setState(() => _maxRsi = v)),
            ]),
          ),

          const SizedBox(height: 10),
          Text('${f.length} de ${_candidates.length} tickers', style: const TextStyle(color: Color(AppColors.mutedDark), fontSize: 13)),
          const SizedBox(height: 8),

          if (f.isEmpty)
            const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Text('Ningún ticker cumple estos filtros. Baja el score o el sharpe.', style: TextStyle(color: Color(AppColors.muted))))
          else
            ...f.map((c) => _TickerTile(candidate: c, onTap: () => showTickerDetail(context, c.ticker))),

          const SizedBox(height: 20),
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
  final Color color;
  final ValueChanged<double> onChanged;
  const _SliderRow({required this.label, required this.value, required this.display, required this.min, required this.max, required this.color, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(color: Color(AppColors.muted), fontSize: 13)),
        Text(display, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
      ]),
      SliderTheme(
        data: SliderTheme.of(context).copyWith(activeTrackColor: color, thumbColor: color, trackHeight: 3),
        child: Slider(value: value, min: min, max: max, onChanged: onChanged),
      ),
    ]);
  }
}

class _TickerTile extends StatelessWidget {
  final ScreenerCandidate candidate;
  final VoidCallback onTap;
  const _TickerTile({required this.candidate, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final isElite = (candidate.score ?? 0) >= 0.75;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(AppColors.bgTile),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isElite ? const Color(AppColors.green).withOpacity(0.3) : Colors.white.withOpacity(0.05)),
        ),
        child: Row(children: [
          Expanded(flex: 2, child: Text('${candidate.ticker} ${flagFor(candidate.ticker)}${isElite ? ' 🔥' : ''}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14))),
          Expanded(child: Text(candidate.score?.toStringAsFixed(2) ?? '—', style: TextStyle(color: colorScore(candidate.score), fontWeight: FontWeight.w700), textAlign: TextAlign.right)),
          Expanded(child: Text(candidate.sharpeRatio?.toStringAsFixed(1) ?? '—', style: TextStyle(color: colorSharpe(candidate.sharpeRatio), fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
          Expanded(child: Text(candidate.rsiWilder?.toStringAsFixed(0) ?? '—', style: TextStyle(color: colorRsi(candidate.rsiWilder), fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
          const Icon(Icons.chevron_right, color: Color(AppColors.mutedDark), size: 18),
        ]),
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
