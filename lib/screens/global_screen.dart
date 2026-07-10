import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../config.dart';
import '../models.dart';
import '../api_service.dart';

Color hitColorOf(double? v) {
  if (v == null) return const Color(AppColors.muted);
  if (v >= 55) return const Color(AppColors.green);
  if (v >= 45) return const Color(AppColors.orange);
  return const Color(AppColors.red);
}

class GlobalScreen extends StatefulWidget {
  const GlobalScreen({super.key});
  @override
  State<GlobalScreen> createState() => _GlobalScreenState();
}

class _GlobalScreenState extends State<GlobalScreen> {
  final _api = ApiService();
  bool _loading = true;
  String? _error;
  PerformanceData? _perf;
  List<EquityPoint> _equity = [];
  ModelQuality? _model;
  MarketContext? _market; // [MKT] estado del régimen de mercado
  OrderAnalysis? _analysis;
  bool _runningAnalysis = false;

  RealPerformance? _realPerf;
  bool _runningRealPerf = false;

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
        _api.fetchEquityCurve(),
        _api.fetchModelQuality(),
        _api.fetchMarketContext(), // [MKT]
      ]);
      setState(() {
        _perf = results[0] as PerformanceData;
        _equity = results[1] as List<EquityPoint>;
        _model = results[2] as ModelQuality;
        _market = results[3] as MarketContext?; // [MKT]
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadAnalysisLazy() async {
    if (_analysis != null) return;
    final a = await _api.fetchOrderAnalysis();
    if (mounted) setState(() => _analysis = a);
  }

  Future<void> _runAnalysis() async {
    setState(() => _runningAnalysis = true);
    try {
      await _api.runOrderAnalysis();
      for (int i = 0; i < 20; i++) {
        await Future.delayed(const Duration(seconds: 1));
        final res = await _api.fetchOrderAnalysis();
        if (res != null) {
          setState(() {
            _analysis = res;
            _runningAnalysis = false;
          });
          return;
        }
      }
    } catch (_) {}
    setState(() => _runningAnalysis = false);
  }

  Future<void> _loadRealPerfLazy() async {
    if (_realPerf != null) return;
    final r = await _api.fetchRealPerformance();
    if (mounted) setState(() => _realPerf = r);
  }

  Future<void> _runRealPerformance() async {
    setState(() => _runningRealPerf = true);
    try {
      await _api.runRealPerformance();
      for (int i = 0; i < 35; i++) {
        await Future.delayed(const Duration(seconds: 1));
        final res = await _api.fetchRealPerformance();
        if (res != null) {
          setState(() {
            _realPerf = res;
            _runningRealPerf = false;
          });
          return;
        }
      }
    } catch (_) {}
    setState(() => _runningRealPerf = false);
  }

  String _fmt$(double? v) => v == null ? '—' : '\$${v.round()}';
  String _fmtPct(double? v) => v == null ? '—' : '${v.toStringAsFixed(2)}%';

  String _trendLabel(String? t) {
    if (t == 'mejorando') return '▲ Mejorando';
    if (t == 'empeorando') return '▼ Empeorando';
    return '→ Estable';
  }

  Color _trendColor(String? t) {
    if (t == 'mejorando') return const Color(AppColors.green);
    if (t == 'empeorando') return const Color(AppColors.red);
    return const Color(AppColors.muted);
  }

  // [MKT] Color según régimen de mercado
  Color _marketColor(String? mode) {
    if (mode == 'growth') return const Color(AppColors.green);
    if (mode == 'defensive') return const Color(AppColors.red);
    if (mode == 'neutral') return const Color(AppColors.orange);
    return const Color(AppColors.muted);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _ErrorBox(message: _error!, onRetry: _load);

    final totalReturn = _perf?.totalReturnPct;
    final returnColor = totalReturn == null ? Colors.white : totalReturn >= 0 ? const Color(AppColors.green) : const Color(AppColors.red);
    final hitDir = _model?.hitRateDirectionPct;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          // ════════════════════════════════
          // [MKT] ESTADO DEL MERCADO
          // ════════════════════════════════
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(AppColors.bgCard), borderRadius: BorderRadius.circular(18)),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('MODO MERCADO', style: TextStyle(color: Color(AppColors.mutedDark), fontSize: 11)),
                  Text(
                    _market?.marketMode?.toUpperCase() ?? '—',
                    style: TextStyle(color: _marketColor(_market?.marketMode), fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                const Text('CONFIANZA', style: TextStyle(color: Color(AppColors.mutedDark), fontSize: 11)),
                Text(
                  _market?.confidence != null ? '${(_market!.confidence! * 100).round()}%' : '—',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ]),
            ]),
          ),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(AppColors.bgCard), borderRadius: BorderRadius.circular(18)),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('CAPITAL', style: TextStyle(color: Color(AppColors.mutedDark), fontSize: 11)),
                  Text(_fmt$(_perf?.equity), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                const Text('RETORNO', style: TextStyle(color: Color(AppColors.mutedDark), fontSize: 11)),
                Text(_fmtPct(totalReturn), style: TextStyle(color: returnColor, fontSize: 22, fontWeight: FontWeight.bold)),
              ]),
            ]),
          ),

          if (_equity.isNotEmpty) ...[
            const SizedBox(height: 10),
            _EquityChart(points: _equity),
          ],

          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _SmallStat('Drawdown', _fmtPct(_perf?.drawdownPct))),
            Expanded(child: _SmallStat('Capital inicial', _fmt$(_perf?.initialEquity))),
          ]),

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(AppColors.bgCard), borderRadius: BorderRadius.circular(18)),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('TASA DE ACIERTO', style: TextStyle(color: Color(AppColors.mutedDark), fontSize: 11)),
                  Text(hitDir != null ? '${hitDir.toStringAsFixed(1)}%' : '—', style: TextStyle(color: hitColorOf(hitDir), fontSize: 22, fontWeight: FontWeight.bold)),
                ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                const Text('TENDENCIA', style: TextStyle(color: Color(AppColors.mutedDark), fontSize: 11)),
                Text(_trendLabel(_model?.trend), style: TextStyle(color: _trendColor(_model?.trend), fontSize: 16, fontWeight: FontWeight.bold)),
              ]),
            ]),
          ),

          const SizedBox(height: 20),

          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('Ver más detalle', style: TextStyle(color: Color(AppColors.muted), fontSize: 13)),
              iconColor: const Color(AppColors.muted),
              collapsedIconColor: const Color(AppColors.muted),
              children: [
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: _SmallStat('Error promedio', _fmtPct(_model?.avgErrorPct))),
                  Expanded(child: _SmallStat('Evaluadas', '${_model?.evaluated ?? 0}')),
                  Expanded(child: _SmallStat('Pendientes', '${_model?.pending ?? 0}')),
                ]),
                if (_model?.hitRate7d != null || _model?.hitRate14d != null || _model?.hitRate30d != null) ...[
                  const SizedBox(height: 14),
                  const Text('Tendencia reciente', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  if (_model?.hitRate7d != null) _HitBar(label: '7 días', value: _model!.hitRate7d),
                  if (_model?.hitRate14d != null) _HitBar(label: '14 días', value: _model!.hitRate14d),
                  if (_model?.hitRate30d != null) _HitBar(label: '30 días', value: _model!.hitRate30d),
                ],
                if (_model != null && _model!.byRecommendation.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text('Por recomendación', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  for (final e in _model!.byRecommendation.entries) _HitBar(label: e.key, value: e.value.hitRatePct),
                ],
                if (_model != null && _model!.byHorizon.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text('Por horizonte', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  for (final e in _model!.byHorizon.entries) _HitBar(label: e.key, value: e.value.hitRatePct),
                ],
                const SizedBox(height: 18),
                const Text('Sistema vs Manual', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                FutureBuilder(
                  future: _loadAnalysisLazy(),
                  builder: (context, snapshot) {
                    if (_analysis == null && !_runningAnalysis) {
                      return ElevatedButton(onPressed: _runAnalysis, child: const Text('▶ Correr análisis'));
                    }
                    if (_runningAnalysis) {
                      return const Text('⟳ Analizando...', style: TextStyle(color: Color(AppColors.gold)));
                    }
                    return _AnalysisResult(analysis: _analysis!, onRerun: _runAnalysis, running: _runningAnalysis);
                  },
                ),
                const SizedBox(height: 18),
                const Text('Performance Real (Sharpe/Drawdown)', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                FutureBuilder(
                  future: _loadRealPerfLazy(),
                  builder: (context, snapshot) {
                    if (_realPerf == null && !_runningRealPerf) {
                      return ElevatedButton(onPressed: _runRealPerformance, child: const Text('▶ Correr análisis'));
                    }
                    if (_runningRealPerf) {
                      return const Text('⟳ Calculando Sharpe/Drawdown...', style: TextStyle(color: Color(AppColors.gold)));
                    }
                    return _RealPerformanceResult(perf: _realPerf!, onRerun: _runRealPerformance, running: _runningRealPerf);
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _SmallStat extends StatelessWidget {
  final String label;
  final String value;
  const _SmallStat(this.label, this.value);
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: Color(AppColors.mutedDark), fontSize: 11)),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
    ]);
  }
}

class _AnalysisResult extends StatelessWidget {
  final OrderAnalysis analysis;
  final VoidCallback onRerun;
  final bool running;
  const _AnalysisResult({required this.analysis, required this.onRerun, required this.running});

  @override
  Widget build(BuildContext context) {
    if (analysis.status != 'ready') {
      return ElevatedButton(onPressed: onRerun, child: const Text('▶ Correr análisis'));
    }
    final winnerColor = analysis.winner == 'manual'
        ? const Color(AppColors.green)
        : analysis.winner == 'system'
            ? const Color(AppColors.blue)
            : const Color(AppColors.muted);
    final icon = analysis.winner == 'manual' ? '🧠' : analysis.winner == 'system' ? '🤖' : '🤝';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(AppColors.bgTile), borderRadius: BorderRadius.circular(14), border: Border.all(color: winnerColor.withOpacity(0.4))),
          child: Row(children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(analysis.verdictText ?? '—', style: TextStyle(color: winnerColor, fontWeight: FontWeight.bold, fontSize: 13)),
                Text('Baseline: ${analysis.universeBaseline?.toStringAsFixed(1) ?? '—'}%', style: const TextStyle(color: Color(AppColors.mutedDark), fontSize: 11)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 10),
        TextButton(onPressed: running ? null : onRerun, child: const Text('↺ Actualizar', style: TextStyle(fontSize: 12))),
      ],
    );
  }
}

class _RealPerformanceResult extends StatelessWidget {
  final RealPerformance perf;
  final VoidCallback onRerun;
  final bool running;
  const _RealPerformanceResult({required this.perf, required this.onRerun, required this.running});

  @override
  Widget build(BuildContext context) {
    if (perf.status != 'ready') {
      return ElevatedButton(onPressed: onRerun, child: const Text('▶ Correr análisis'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (perf.ensemble != null) ...[
          const Text('Teórico (ensemble COMPRA/VENDE)', style: TextStyle(color: Color(AppColors.mutedDark), fontSize: 11)),
          const SizedBox(height: 6),
          _BacktestStatRow(result: perf.ensemble!),
          const SizedBox(height: 14),
        ],
        if (perf.realAccount != null) ...[
          const Text('Cuenta real (Alpaca)', style: TextStyle(color: Color(AppColors.mutedDark), fontSize: 11)),
          const SizedBox(height: 6),
          _BacktestStatRow(result: perf.realAccount!),
        ],
        const SizedBox(height: 10),
        TextButton(onPressed: running ? null : onRerun, child: const Text('↺ Actualizar', style: TextStyle(fontSize: 12))),
      ],
    );
  }
}

class _BacktestStatRow extends StatelessWidget {
  final BacktestResult result;
  const _BacktestStatRow({required this.result});

  String _fmt(double? v, {int decimals = 2}) => v == null ? '—' : v.toStringAsFixed(decimals);

  @override
  Widget build(BuildContext context) {
    final sharpeNw = result.sharpeNeweyWest;
    final sharpeColor = sharpeNw == null
        ? const Color(AppColors.muted)
        : sharpeNw >= 1
            ? const Color(AppColors.green)
            : sharpeNw >= 0
                ? const Color(AppColors.orange)
                : const Color(AppColors.red);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(AppColors.bgTile), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('SHARPE (NW)', style: TextStyle(color: Color(AppColors.mutedDark), fontSize: 10)),
                Text(_fmt(sharpeNw), style: TextStyle(color: sharpeColor, fontSize: 18, fontWeight: FontWeight.bold)),
              ]),
            ),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('SHARPE CLÁSICO', style: TextStyle(color: Color(AppColors.mutedDark), fontSize: 10)),
                Text(_fmt(result.sharpeClassic), style: const TextStyle(color: Colors.white70, fontSize: 14)),
              ]),
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _SmallStat('Max Drawdown', result.maxDrawdown != null ? '${(result.maxDrawdown! * 100).toStringAsFixed(1)}%' : '—')),
            Expanded(child: _SmallStat('Win Rate', result.winRate != null ? '${(result.winRate! * 100).toStringAsFixed(1)}%' : '—')),
            Expanded(child: _SmallStat('Retorno total', result.totalReturnPct != null ? '${result.totalReturnPct!.toStringAsFixed(1)}%' : '—')),
          ]),
          const SizedBox(height: 4),
          Text('${result.nTrades ?? 0} trades · ${result.nDays ?? 0} días', style: const TextStyle(color: Color(AppColors.mutedDark), fontSize: 10)),
        ],
      ),
    );
  }
}

class _EquityChart extends StatelessWidget {
  final List<EquityPoint> points;
  const _EquityChart({required this.points});

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[];
    for (int i = 0; i < points.length; i++) {
      spots.add(FlSpot(i.toDouble(), points[i].equity));
    }
    return Container(
      height: 160,
      padding: const EdgeInsets.fromLTRB(6, 14, 14, 6),
      decoration: BoxDecoration(color: const Color(AppColors.bgCard), borderRadius: BorderRadius.circular(16)),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          titlesData: const FlTitlesData(
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(spots: spots, isCurved: true, color: const Color(AppColors.blue), barWidth: 2, dotData: const FlDotData(show: false)),
          ],
        ),
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
