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
  OrderAnalysis? _analysis;
  bool _runningAnalysis = false;

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
      ]);
      final analysis = await _api.fetchOrderAnalysis();
      setState(() {
        _perf = results[0] as PerformanceData;
        _equity = results[1] as List<EquityPoint>;
        _model = results[2] as ModelQuality;
        _analysis = analysis;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
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

  String _fmt$(double? v) => v == null ? '—' : '\$${v.round()}';
  String _fmtPct(double? v) => v == null ? '—' : '${v.toStringAsFixed(2)}%';

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
          _SectionHeader(icon: '📈', title: 'Performance Real', sub: 'Broker · Alpaca Paper'),
          Row(children: [
            Expanded(child: _KpiMain(label: 'Capital Total', value: _fmt$(_perf?.equity))),
            const SizedBox(width: 10),
            Expanded(child: _KpiMain(label: 'Retorno Total', value: _fmtPct(totalReturn), color: returnColor)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _KpiSmall(label: 'Drawdown', value: _fmtPct(_perf?.drawdownPct))),
            Expanded(child: _KpiSmall(label: 'HWM', value: _fmt$(_perf?.highWaterMark))),
            Expanded(child: _KpiSmall(label: 'Inicial', value: _fmt$(_perf?.initialEquity))),
          ]),
          const SizedBox(height: 18),
          if (_equity.isNotEmpty) _EquityChart(points: _equity) else const Text('Sin historial de equity.', style: TextStyle(color: Color(AppColors.mutedDark))),

          const SizedBox(height: 30),
          _SectionHeader(icon: '🎯', title: 'Calidad Predictiva', sub: 'Modelo · sin PnL real'),
          Row(children: [
            Expanded(child: _KpiMain(label: 'Hit Rate Histórico', value: _fmtPct(hitDir), color: hitColorOf(hitDir))),
            const SizedBox(width: 10),
            Expanded(child: _KpiMain(label: 'Error Promedio', value: _fmtPct(_model?.avgErrorPct), color: const Color(AppColors.orange))),
          ]),
          const SizedBox(height: 14),
          if (_model?.hitRate7d != null) _HitBar(label: '7 días', value: _model!.hitRate7d, sub: '${_model?.recentWindowSizes['7d'] ?? '—'} eval.'),
          if (_model?.hitRate14d != null) _HitBar(label: '14 días', value: _model!.hitRate14d, sub: '${_model?.recentWindowSizes['14d'] ?? '—'} eval.'),
          if (_model?.hitRate30d != null) _HitBar(label: '30 días', value: _model!.hitRate30d, sub: '${_model?.recentWindowSizes['30d'] ?? '—'} eval.'),

          const SizedBox(height: 14),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _CoverageStat(label: 'evaluadas', value: _model?.evaluated),
            _CoverageStat(label: 'pendientes', value: _model?.pending, color: const Color(AppColors.mutedDark)),
            _CoverageStat(label: 'total', value: _model?.total, color: const Color(0xFF475569)),
          ]),

          if (_model != null && _model!.byRecommendation.isNotEmpty) ...[
            const SizedBox(height: 18),
            const Text('Por recomendación', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
            for (final e in _model!.byRecommendation.entries) _HitBar(label: e.key, value: e.value.hitRatePct, sub: '${e.value.total ?? 0} pred.'),
          ],

          if (_model != null && _model!.byHorizon.isNotEmpty) ...[
            const SizedBox(height: 18),
            const Text('Por horizonte', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
            for (final e in _model!.byHorizon.entries) _HitBar(label: e.key, value: e.value.hitRatePct, sub: '${e.value.total ?? 0}'),
          ],

          const SizedBox(height: 30),
          _SectionHeader(icon: '⚔️', title: 'Sistema vs Manual', sub: 'Análisis de órdenes'),
          if (_analysis == null && !_runningAnalysis)
            Column(children: [
              const Text('Análisis no ejecutado aún.', style: TextStyle(color: Color(AppColors.muted))),
              const SizedBox(height: 10),
              ElevatedButton(onPressed: _runAnalysis, child: const Text('▶ Correr análisis')),
            ]),
          if (_runningAnalysis) const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('⟳ Analizando órdenes...', style: TextStyle(color: Color(AppColors.gold)))),
          if (_analysis != null) _AnalysisResult(analysis: _analysis!, onRerun: _runAnalysis, running: _runningAnalysis),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _AnalysisResult extends StatelessWidget {
  final OrderAnalysis analysis;
  final VoidCallback onRerun;
  final bool running;
  const _AnalysisResult({required this.analysis, required this.onRerun, required this.running});

  @override
  Widget build(BuildContext context) {
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
          margin: const EdgeInsets.only(top: 10),
          decoration: BoxDecoration(color: const Color(AppColors.bgCard), borderRadius: BorderRadius.circular(14), border: Border.all(color: winnerColor.withOpacity(0.4))),
          child: Row(children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(analysis.verdictText ?? '—', style: TextStyle(color: winnerColor, fontWeight: FontWeight.bold)),
                Text('Baseline universo: ${analysis.universeBaseline?.toStringAsFixed(1) ?? '—'}%', style: const TextStyle(color: Color(AppColors.mutedDark), fontSize: 12)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _CompareCard(label: '🤖 Sistema', data: analysis.systemBuys, color: const Color(AppColors.blue))),
          const SizedBox(width: 10),
          Expanded(child: _CompareCard(label: '🧠 Manual', data: analysis.manualBuys, color: const Color(AppColors.green))),
        ]),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(onPressed: running ? null : onRerun, child: const Text('↺ Actualizar análisis')),
        ),
      ],
    );
  }
}

class _CompareCard extends StatelessWidget {
  final String label;
  final OrderGroupStats? data;
  final Color color;
  const _CompareCard({required this.label, required this.data, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(AppColors.bgCard), borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: Color(AppColors.muted), fontSize: 12)),
        Text(data?.hitRateDirPct != null ? '${data!.hitRateDirPct!.toStringAsFixed(1)}%' : '—', style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
        const Text('hit rate dir.', style: TextStyle(color: Color(AppColors.mutedDark), fontSize: 11)),
        const SizedBox(height: 6),
        _MiniRow('Ret. prom.', data?.avgRealReturn != null ? '${data!.avgRealReturn!.toStringAsFixed(2)}%' : '—'),
        _MiniRow('Tickers', '${data?.tickersFound ?? '—'}'),
        _MiniRow('Evals', '${data?.totalEvaluations ?? '—'}'),
        if (data?.bestHorizon != null) _MiniRow('Mejor horiz.', data!.bestHorizon!),
      ]),
    );
  }
}

class _MiniRow extends StatelessWidget {
  final String label;
  final String value;
  const _MiniRow(this.label, this.value);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(color: Color(AppColors.mutedDark), fontSize: 11)),
        Text(value, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ]),
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
      height: 200,
      padding: const EdgeInsets.fromLTRB(6, 14, 14, 6),
      decoration: BoxDecoration(color: const Color(AppColors.bgCard), borderRadius: BorderRadius.circular(16)),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          titlesData: const FlTitlesData(
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 44)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: const Color(AppColors.blue),
              barWidth: 2,
              dotData: const FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String icon;
  final String title;
  final String sub;
  const _SectionHeader({required this.icon, required this.title, required this.sub});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Text(icon, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          Text(sub, style: const TextStyle(color: Color(AppColors.mutedDark), fontSize: 12)),
        ]),
      ]),
    );
  }
}

class _KpiMain extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _KpiMain({required this.label, required this.value, this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(AppColors.bgCard), borderRadius: BorderRadius.circular(14), border: Border.all(color: (color ?? Colors.white).withOpacity(0.15))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: Color(AppColors.muted), fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color ?? Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}

class _KpiSmall extends StatelessWidget {
  final String label;
  final String value;
  const _KpiSmall({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(label, style: const TextStyle(color: Color(AppColors.mutedDark), fontSize: 11)),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
    ]);
  }
}

class _HitBar extends StatelessWidget {
  final String label;
  final double? value;
  final String sub;
  const _HitBar({required this.label, required this.value, required this.sub});

  @override
  Widget build(BuildContext context) {
    if (value == null) return const SizedBox.shrink();
    final color = hitColorOf(value);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        SizedBox(width: 70, child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12))),
        Expanded(
          child: Stack(children: [
            Container(height: 8, decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(4))),
            FractionallySizedBox(
              widthFactor: (value! / 100).clamp(0, 1),
              child: Container(height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
            ),
          ]),
        ),
        const SizedBox(width: 8),
        Text('${value!.toStringAsFixed(1)}%', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}

class _CoverageStat extends StatelessWidget {
  final String label;
  final int? value;
  final Color? color;
  const _CoverageStat({required this.label, required this.value, this.color});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text('${value ?? '—'}', style: TextStyle(color: color ?? Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      Text(label, style: const TextStyle(color: Color(AppColors.mutedDark), fontSize: 11)),
    ]);
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
