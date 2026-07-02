import 'package:flutter/material.dart';
import '../config.dart';
import '../models.dart';
import '../api_service.dart';
import '../widgets/ticker_detail_sheet.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});
  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  final _api = ApiService();
  bool _loading = true;
  String? _error;
  PortfolioStatus? _status;
  List<Position> _positions = [];
  Map<String, PredictionData> _preds = {};

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
      final results = await Future.wait([_api.fetchStatus(), _api.fetchPositions()]);
      final status = results[0] as PortfolioStatus;
      final positions = results[1] as List<Position>;

      final preds = <String, PredictionData>{};
      await Future.wait(positions.map((p) async {
        try {
          final snap = await _api.fetchLatest(p.ticker);
          preds[p.ticker] = snap.prediction;
        } catch (_) {}
      }));

      setState(() {
        _status = status;
        _positions = positions;
        _preds = preds;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _fmt$(double? v) => v == null ? '—' : '\$${v.toStringAsFixed(2)}';
  String _fmtPct(double? v) => v == null ? '—' : '${v >= 0 ? '+' : ''}${v.toStringAsFixed(2)}%';
  Color _retColor(double? v) => v == null ? const Color(AppColors.muted) : v > 0 ? const Color(AppColors.green) : v < 0 ? const Color(AppColors.red) : const Color(AppColors.muted);

  int? _daysAgo(String? iso) {
    if (iso == null) return null;
    try {
      final d = DateTime.parse(iso);
      return DateTime.now().difference(d).inDays;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _ErrorBox(message: _error!, onRetry: _load);

    final totalPl = _positions.fold<double>(0, (a, p) => a + (p.unrealizedPl ?? 0));
    final inProfit = _positions.where((p) => (p.unrealizedPl ?? 0) > 0).length;
    final expired = _positions.where((p) {
      final d = _daysAgo(_preds[p.ticker]?.dateBase);
      return (d ?? 0) >= 10;
    }).length;
    final blocked = _status?.tradingBlocked ?? false;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Row(children: [
            const Text('💼', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Portafolio', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                Text('Paper Trading · Alpaca', style: TextStyle(color: Color(AppColors.mutedDark), fontSize: 12)),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: (blocked ? const Color(AppColors.red) : const Color(AppColors.green)).withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
              child: Text(blocked ? '🔒 Bloqueado' : '✓ Activo', style: TextStyle(color: blocked ? const Color(AppColors.red) : const Color(AppColors.green), fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _Kpi(label: 'Capital Total', value: _fmt$(_status?.equity))),
            Expanded(child: _Kpi(label: 'Buying Power', value: _fmt$(_status?.buyingPower))),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _KpiSmall(label: 'Posiciones', value: '${_positions.length}')),
            Expanded(child: _KpiSmall(label: 'PnL No Real.', value: _fmt$(totalPl), color: _retColor(totalPl))),
            Expanded(child: _KpiSmall(label: 'En Positivo', value: '$inProfit', color: const Color(AppColors.green))),
            Expanded(child: _KpiSmall(label: 'Horiz. Vencido', value: '$expired', color: expired > 0 ? const Color(AppColors.orange) : const Color(AppColors.muted))),
          ]),
          const SizedBox(height: 22),
          if (_positions.isEmpty)
            const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Text('Sin posiciones abiertas.', style: TextStyle(color: Color(AppColors.muted))))
          else
            ..._positions.map((p) {
              final currentPrice = p.currentPrice ?? (p.qty != 0 && p.marketValue != null ? p.marketValue! / p.qty : null);
              final currentRet = (p.entryPrice > 0 && currentPrice != null) ? (currentPrice / p.entryPrice - 1) * 100 : null;
              final pred = _preds[p.ticker];
              final days = _daysAgo(pred?.dateBase);

              return InkWell(
                onTap: () => showTickerDetail(context, p.ticker),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: const Color(AppColors.bgTile), borderRadius: BorderRadius.circular(16)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(p.ticker, style: const TextStyle(color: Color(AppColors.blue), fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(_fmt$(p.unrealizedPl), style: TextStyle(color: _retColor(p.unrealizedPl), fontWeight: FontWeight.bold)),
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(child: _MiniStat('Qty', '${p.qty}')),
                      Expanded(child: _MiniStat('Entrada', _fmt$(p.entryPrice))),
                      Expanded(child: _MiniStat('Actual', _fmt$(currentPrice))),
                      Expanded(child: _MiniStat('Ret %', _fmtPct(currentRet), color: _retColor(currentRet))),
                    ]),
                    if (pred != null) ...[
                      const Divider(color: Colors.white12, height: 18),
                      Row(children: [
                        Expanded(child: _MiniStat('Target', pred.pricePred != null ? _fmt$(pred.pricePred) : '—')),
                        Expanded(child: _MiniStat('Predicción', pred.retEnsPct != null ? _fmtPct(pred.retEnsPct) : '—', color: _retColor(pred.retEnsPct))),
                        Expanded(child: _MiniStat('Días', days != null ? '${days}d' : '—', color: (days ?? 0) >= 10 ? const Color(AppColors.orange) : const Color(AppColors.muted))),
                      ]),
                    ],
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

class _Kpi extends StatelessWidget {
  final String label;
  final String value;
  const _Kpi({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(AppColors.bgCard), borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: Color(AppColors.muted), fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}

class _KpiSmall extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _KpiSmall({required this.label, required this.value, this.color});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value, style: TextStyle(color: color ?? Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
      Text(label, style: const TextStyle(color: Color(AppColors.mutedDark), fontSize: 10), textAlign: TextAlign.center),
    ]);
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _MiniStat(this.label, this.value, {this.color});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: Color(AppColors.mutedDark), fontSize: 10)),
      Text(value, style: TextStyle(color: color ?? Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
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
