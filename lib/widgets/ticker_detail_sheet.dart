import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../config.dart';
import '../models.dart';
import '../api_service.dart';

Future<void> showTickerDetail(BuildContext context, String ticker) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _TickerDetailSheet(ticker: ticker),
  );
}

class _TickerDetailSheet extends StatefulWidget {
  final String ticker;
  const _TickerDetailSheet({required this.ticker});
  @override
  State<_TickerDetailSheet> createState() => _TickerDetailSheetState();
}

class _TickerDetailSheetState extends State<_TickerDetailSheet> {
  final _api = ApiService();
  bool _loading = true;
  String? _error;
  LatestSnapshot? _snapshot;
  AlphaData? _alpha;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([_api.fetchLatest(widget.ticker), _api.fetchAlpha(widget.ticker)]);
      setState(() {
        _snapshot = results[0] as LatestSnapshot;
        _alpha = results[1] as AlphaData;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Color _recColor(String? rec) {
    if (rec == 'COMPRA') return const Color(AppColors.green);
    if (rec == 'VENTA' || rec == 'VENDE') return const Color(AppColors.red);
    return const Color(AppColors.amber);
  }

  String _fmt$(double? v, bool cl) => v == null ? '—' : (cl ? '\$${v.round()}' : '\$${v.toStringAsFixed(2)}');
  String _fmtPct(double? v) => v == null ? '—' : '${v >= 0 ? '+' : ''}${v.toStringAsFixed(2)}%';

  @override
  Widget build(BuildContext context) {
    final isChile = widget.ticker.endsWith('.SN') || widget.ticker.endsWith('.CL');

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(AppColors.bgCard),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('⚠ $_error', style: const TextStyle(color: Color(0xFFFECACA)))))
                  : ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
                      children: [
                        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
                        const SizedBox(height: 16),
                        Text(widget.ticker, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        _buildContent(isChile),
                      ],
                    ),
        );
      },
    );
  }

  Widget _buildContent(bool isChile) {
    final s = _snapshot!;
    final p = s.prediction;
    final h = s.historical;
    final hit = h.hitRateMean != null ? h.hitRateMean! * 100 : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.6,
          children: [
            _MiniKpi(label: 'RECOMENDACIÓN', big: p.recommendation ?? 'HOLD', color: _recColor(p.recommendation), sub: 'Target ${_fmtPct(p.retEnsPct)}'),
            _MiniKpi(
              label: 'ALPHA SCORE',
              big: _alpha?.alphaScore != null ? _alpha!.alphaScore!.toStringAsFixed(3) : '—',
              color: (_alpha?.alphaScore ?? 0) > 0 ? const Color(AppColors.green) : (_alpha?.alphaScore ?? 0) < 0 ? const Color(AppColors.red) : const Color(AppColors.muted),
            ),
            _MiniKpi(
              label: 'HIT RATE',
              big: hit != null ? '${hit.toStringAsFixed(1)}%' : '—',
              color: hit == null ? const Color(AppColors.muted) : hit >= 55 ? const Color(AppColors.green) : hit >= 48 ? const Color(AppColors.amber) : const Color(AppColors.red),
              sub: 'MAE ${h.maeMean != null ? '${h.maeMean!.toStringAsFixed(2)}%' : '—'}',
            ),
            _MiniKpi(label: 'ENSEMBLE', big: '${s.ensembleModels}/10', color: const Color(AppColors.blue), sub: '${s.diagnostics.length} c/diagnóstico'),
          ],
        ),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _PriceStat('Actual', _fmt$(p.priceNow, isChile)),
          _PriceStat('Objetivo', _fmt$(p.pricePred, isChile)),
        ]),
        if (s.diagnostics.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text('Diagnóstico por modelo', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 10),
          SizedBox(height: 160, child: _DiagChart(diagnostics: s.diagnostics)),
        ],
        if (s.pricePath.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text('Trayectoria esperada', style: TextStyle(color: Color(AppColors.gold), fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 10),
          SizedBox(height: 160, child: _ForecastChart(priceNow: s.priceNowCurve ?? p.priceNow ?? 0, path: s.pricePath)),
        ],
      ],
    );
  }
}

class _PriceStat extends StatelessWidget {
  final String label;
  final String value;
  const _PriceStat(this.label, this.value);
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      Text(label, style: const TextStyle(color: Color(AppColors.mutedDark), fontSize: 11)),
    ]);
  }
}

class _MiniKpi extends StatelessWidget {
  final String label;
  final String big;
  final Color color;
  final String? sub;
  const _MiniKpi({required this.label, required this.big, required this.color, this.sub});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(AppColors.bgTile), borderRadius: BorderRadius.circular(14), border: Border(left: BorderSide(color: color, width: 3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(label, style: const TextStyle(color: Color(AppColors.mutedDark), fontSize: 9)),
        Text(big, style: TextStyle(color: color, fontSize: 17, fontWeight: FontWeight.bold)),
        if (sub != null) Text(sub!, style: const TextStyle(color: Color(AppColors.mutedDark), fontSize: 10)),
      ]),
    );
  }
}

class _DiagChart extends StatelessWidget {
  final List<ModelDiagnostic> diagnostics;
  const _DiagChart({required this.diagnostics});
  @override
  Widget build(BuildContext context) {
    final bars = <BarChartGroupData>[];
    for (int i = 0; i < diagnostics.length; i++) {
      final d = diagnostics[i];
      bars.add(BarChartGroupData(x: i, barRods: [BarChartRodData(toY: d.predReturn ?? 0, color: (d.predReturn ?? 0) >= 0 ? const Color(AppColors.blue) : const Color(AppColors.red), width: 8)]));
    }
    return BarChart(BarChartData(
      barGroups: bars,
      gridData: const FlGridData(show: true, drawVerticalLine: false),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (v, meta) {
              final i = v.toInt();
              if (i < 0 || i >= diagnostics.length) return const SizedBox.shrink();
              return Text(diagnostics[i].model, style: const TextStyle(color: Color(AppColors.mutedDark), fontSize: 8));
            },
          ),
        ),
      ),
    ));
  }
}

class _ForecastChart extends StatelessWidget {
  final double priceNow;
  final List<double> path;
  const _ForecastChart({required this.priceNow, required this.path});
  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[FlSpot(0, priceNow)];
    for (int i = 0; i < path.length; i++) {
      spots.add(FlSpot((i + 1).toDouble(), path[i]));
    }
    return LineChart(LineChartData(
      gridData: const FlGridData(show: true, drawVerticalLine: false),
      borderData: FlBorderData(show: false),
      titlesData: const FlTitlesData(
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
      ),
      extraLinesData: ExtraLinesData(horizontalLines: [HorizontalLine(y: priceNow, color: const Color(0xFF475569), strokeWidth: 1, dashArray: [4, 4])]),
      lineBarsData: [LineChartBarData(spots: spots, isCurved: true, color: const Color(AppColors.gold), barWidth: 3, dotData: const FlDotData(show: true))],
    ));
  }
}
