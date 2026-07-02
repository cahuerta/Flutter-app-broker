import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../config.dart';
import '../models.dart';
import '../api_service.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});
  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  final _api = ApiService();
  List<String> _tickers = [];
  String? _selected;
  bool _loadingTickers = true;
  bool _loadingData = false;
  String? _error;

  LatestSnapshot? _snapshot;
  AlphaData? _alpha;

  @override
  void initState() {
    super.initState();
    _loadTickers();
  }

  Future<void> _loadTickers() async {
    try {
      final t = await _api.fetchTickers();
      setState(() {
        _tickers = t;
        _loadingTickers = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loadingTickers = false;
      });
    }
  }

  Future<void> _loadTicker(String ticker) async {
    setState(() {
      _loadingData = true;
      _error = null;
      _selected = ticker;
    });
    try {
      final results = await Future.wait([_api.fetchLatest(ticker), _api.fetchAlpha(ticker)]);
      setState(() {
        _snapshot = results[0] as LatestSnapshot;
        _alpha = results[1] as AlphaData;
        _loadingData = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loadingData = false;
      });
    }
  }

  bool get _isChile => (_selected ?? '').endsWith('.SN') || (_selected ?? '').endsWith('.CL');
  String _fmt$(double? v) => v == null ? '—' : (_isChile ? '\$${v.round()}' : '\$${v.toStringAsFixed(2)}');
  String _fmtPct(double? v) => v == null ? '—' : '${v >= 0 ? '+' : ''}${v.toStringAsFixed(2)}%';

  Color _recColor(String? rec) {
    if (rec == 'COMPRA') return const Color(AppColors.green);
    if (rec == 'VENTA' || rec == 'VENDE') return const Color(AppColors.red);
    return const Color(AppColors.amber);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: _loadingTickers
              ? const LinearProgressIndicator()
              : DropdownButtonFormField<String>(
                  value: _tickers.contains(_selected) ? _selected : null,
                  dropdownColor: const Color(AppColors.bgCard),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(AppColors.bgCard),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    hintText: 'Seleccionar activo',
                    hintStyle: const TextStyle(color: Color(AppColors.muted)),
                  ),
                  items: _tickers.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(color: Colors.white)))).toList(),
                  onChanged: (v) {
                    if (v != null) _loadTicker(v);
                  },
                ),
        ),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildBody() {
    if (_selected == null) return const Center(child: Text('Selecciona un ticker para ver el análisis.', style: TextStyle(color: Color(AppColors.muted))));
    if (_loadingData) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _ErrorBox(message: _error!, onRetry: () => _loadTicker(_selected!));
    if (_snapshot == null) return const SizedBox.shrink();

    final s = _snapshot!;
    final p = s.prediction;
    final h = s.historical;
    final hit = h.hitRateMean != null ? h.hitRateMean! * 100 : null;

    return RefreshIndicator(
      onRefresh: () => _loadTicker(_selected!),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
        children: [
          Text(_selected!, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.5,
            children: [
              _KpiCard(label: 'RECOMENDACIÓN', big: p.recommendation ?? 'HOLD', color: _recColor(p.recommendation), sub: 'Target ${_fmtPct(p.retEnsPct)}'),
              _KpiCard(
                label: 'ALPHA SCORE',
                big: _alpha?.alphaScore != null ? _alpha!.alphaScore!.toStringAsFixed(3) : '—',
                color: (_alpha?.alphaScore ?? 0) > 0 ? const Color(AppColors.green) : (_alpha?.alphaScore ?? 0) < 0 ? const Color(AppColors.red) : const Color(AppColors.muted),
                sub: _alpha?.thetaCleared == true ? '🔥 θ cleared' : null,
              ),
              _KpiCard(
                label: 'HIT RATE',
                big: hit != null ? '${hit.toStringAsFixed(1)}%' : '—',
                color: hit == null ? const Color(AppColors.muted) : hit >= 55 ? const Color(AppColors.green) : hit >= 48 ? const Color(AppColors.amber) : const Color(AppColors.red),
                sub: 'MAE ${h.maeMean != null ? '${h.maeMean!.toStringAsFixed(2)}%' : '—'}',
              ),
              _KpiCard(label: 'ENSEMBLE', big: '${s.ensembleModels}/10', color: s.diagnostics.length >= 8 ? const Color(AppColors.green) : s.diagnostics.length >= 5 ? const Color(AppColors.amber) : const Color(AppColors.red), sub: '${s.diagnostics.length} c/diagnóstico'),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: const Color(AppColors.bgCard), borderRadius: BorderRadius.circular(16)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Precio', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                _PriceStat('Actual', _fmt$(p.priceNow)),
                _PriceStat('Objetivo', _fmt$(p.pricePred)),
                _PriceStat('θ dinámico', p.thetaDynamicPct != null ? '${p.thetaDynamicPct!.toStringAsFixed(3)}%' : '—'),
              ]),
            ]),
          ),
          if (s.diagnostics.isNotEmpty) _DiagnosticsChart(diagnostics: s.diagnostics),
          if (s.pricePath.isNotEmpty) _ForecastChart(priceNow: s.priceNowCurve ?? p.priceNow ?? 0, path: s.pricePath),
        ],
      ),
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
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
      Text(label, style: const TextStyle(color: Color(AppColors.mutedDark), fontSize: 11)),
    ]);
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String big;
  final Color color;
  final String? sub;
  const _KpiCard({required this.label, required this.big, required this.color, this.sub});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(AppColors.bgCard), borderRadius: BorderRadius.circular(16), border: Border(left: BorderSide(color: color, width: 4))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(label, style: const TextStyle(color: Color(AppColors.mutedDark), fontSize: 10, letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Text(big, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
        if (sub != null) Text(sub!, style: const TextStyle(color: Color(AppColors.mutedDark), fontSize: 11)),
      ]),
    );
  }
}

class _DiagnosticsChart extends StatelessWidget {
  final List<ModelDiagnostic> diagnostics;
  const _DiagnosticsChart({required this.diagnostics});

  @override
  Widget build(BuildContext context) {
    final bars = <BarChartGroupData>[];
    for (int i = 0; i < diagnostics.length; i++) {
      final d = diagnostics[i];
      bars.add(BarChartGroupData(x: i, barRods: [
        BarChartRodData(toY: d.predReturn ?? 0, color: (d.predReturn ?? 0) >= 0 ? const Color(AppColors.blue) : const Color(AppColors.red), width: 10),
      ]));
    }
    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(10, 16, 16, 10),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: const Color(AppColors.bgCard), borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Model Diagnostics H1–H10', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        Expanded(
          child: BarChart(BarChartData(
            barGroups: bars,
            gridData: const FlGridData(show: true, drawVerticalLine: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, meta) {
                    final i = v.toInt();
                    if (i < 0 || i >= diagnostics.length) return const SizedBox.shrink();
                    return Text(diagnostics[i].model, style: const TextStyle(color: Color(AppColors.mutedDark), fontSize: 9));
                  },
                ),
              ),
            ),
          )),
        ),
      ]),
    );
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
    return Container(
      height: 240,
      padding: const EdgeInsets.fromLTRB(10, 16, 16, 10),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: const Color(AppColors.bgCard), borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Trayectoria Esperada (H1–H9)', style: TextStyle(color: Color(AppColors.gold), fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        Expanded(
          child: LineChart(LineChartData(
            gridData: const FlGridData(show: true, drawVerticalLine: false),
            borderData: FlBorderData(show: false),
            titlesData: const FlTitlesData(
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 44)),
            ),
            extraLinesData: ExtraLinesData(horizontalLines: [
              HorizontalLine(y: priceNow, color: const Color(0xFF475569), strokeWidth: 1, dashArray: [4, 4]),
            ]),
            lineBarsData: [
              LineChartBarData(spots: spots, isCurved: true, color: const Color(AppColors.gold), barWidth: 3, dotData: const FlDotData(show: true)),
            ],
          )),
        ),
      ]),
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
