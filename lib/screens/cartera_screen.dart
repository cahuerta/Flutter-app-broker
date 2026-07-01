import 'package:flutter/material.dart';
import '../config.dart';
import '../models.dart';
import '../api_service.dart';
import '../widgets/ticker_detail_sheet.dart';

class CarteraScreen extends StatefulWidget {
  const CarteraScreen({super.key});
  @override
  State<CarteraScreen> createState() => _CarteraScreenState();
}

class _CarteraScreenState extends State<CarteraScreen> {
  final _api = ApiService();
  bool _loading = true;
  String? _error;
  PortfolioStatus? _status;
  List<Position> _positions = [];

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
      setState(() {
        _status = results[0] as PortfolioStatus;
        _positions = results[1] as List<Position>;
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

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _ErrorBox(message: _error!, onRetry: _load);

    final totalPl = _positions.fold<double>(0, (a, p) => a + (p.unrealizedPl ?? 0));
    final blocked = _status?.tradingBlocked ?? false;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(AppColors.bgCard), borderRadius: BorderRadius.circular(18)),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Mis Fondos', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: (blocked ? const Color(AppColors.red) : const Color(AppColors.green)).withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                  child: Text(blocked ? '🔒 Bloqueado' : '✓ Activo', style: TextStyle(color: blocked ? const Color(AppColors.red) : const Color(AppColors.green), fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: _Stat('Capital', _fmt$(_status?.equity))),
                Expanded(child: _Stat('Buying Power', _fmt$(_status?.buyingPower))),
                Expanded(child: _Stat('PnL', _fmt$(totalPl), color: _retColor(totalPl))),
              ]),
            ]),
          ),
          const SizedBox(height: 16),
          if (_positions.isEmpty)
            const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Text('Sin posiciones abiertas.', style: TextStyle(color: Color(AppColors.muted))))
          else
            ..._positions.map((p) {
              final currentPrice = p.currentPrice ?? (p.qty != 0 && p.marketValue != null ? p.marketValue! / p.qty : null);
              final currentRet = (p.entryPrice > 0 && currentPrice != null) ? (currentPrice / p.entryPrice - 1) * 100 : null;
              return InkWell(
                onTap: () => showTickerDetail(context, p.ticker),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: const Color(AppColors.bgTile), borderRadius: BorderRadius.circular(16)),
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(p.ticker, style: const TextStyle(color: Color(AppColors.blue), fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 4),
                        Text('Qty ${p.qty} · Entrada ${_fmt$(p.entryPrice)}', style: const TextStyle(color: Color(AppColors.mutedDark), fontSize: 12)),
                      ]),
                    ),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text(_fmt$(p.unrealizedPl), style: TextStyle(color: _retColor(p.unrealizedPl), fontWeight: FontWeight.bold)),
                      Text(_fmtPct(currentRet), style: TextStyle(color: _retColor(currentRet), fontSize: 12)),
                    ]),
                    const SizedBox(width: 6),
                    const Icon(Icons.chevron_right, color: Color(AppColors.mutedDark), size: 18),
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

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _Stat(this.label, this.value, {this.color});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: Color(AppColors.mutedDark), fontSize: 11)),
      const SizedBox(height: 2),
      Text(value, style: TextStyle(color: color ?? Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
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
