import 'package:flutter/material.dart';
import '../config.dart';
import '../models.dart';
import '../api_service.dart';
import '../widgets/ticker_detail_sheet.dart';

const _marketOrder = ['US', 'CL', 'ES', 'DE', 'FR', 'NL', 'CH', 'CA', 'UK'];

Map<String, String> _marketInfo(String ticker) {
  final t = ticker.toUpperCase();
  if (t.endsWith('.SN') || t.endsWith('.SCL')) return {'flag': '🇨🇱', 'market': 'CL'};
  if (t.endsWith('.MC')) return {'flag': '🇪🇸', 'market': 'ES'};
  if (t.endsWith('.DE') || t.endsWith('.XETRA')) return {'flag': '🇩🇪', 'market': 'DE'};
  if (t.endsWith('.PA')) return {'flag': '🇫🇷', 'market': 'FR'};
  if (t.endsWith('.AS')) return {'flag': '🇳🇱', 'market': 'NL'};
  if (t.endsWith('.SW')) return {'flag': '🇨🇭', 'market': 'CH'};
  if (t.endsWith('.TO')) return {'flag': '🇨🇦', 'market': 'CA'};
  if (t.endsWith('.L')) return {'flag': '🇬🇧', 'market': 'UK'};
  return {'flag': '🇺🇸', 'market': 'US'};
}

Color _colorAlpha(double? a) {
  if (a == null) return const Color(AppColors.muted);
  if (a >= 0.70) return const Color(AppColors.greenDark);
  if (a >= 0.55) return const Color(AppColors.amber);
  return const Color(AppColors.red);
}

Color _colorConf(double? c) {
  if (c == null) return const Color(AppColors.muted);
  if (c >= 0.75) return const Color(AppColors.greenDark);
  if (c >= 0.50) return const Color(AppColors.amber);
  return const Color(AppColors.red);
}

String _reasonLabel(String? reason) {
  const map = {
    'alpha_below_threshold': 'Alpha bajo threshold',
    'liquidity_gate_triggered': 'Liquidez insuficiente',
    'kill_switch': 'Kill switch',
    'kill_switch_close': 'Cerrar posición',
    'kill_switch_no_open': 'Kill switch',
    'no_alpha': 'Sin alpha',
  };
  return map[reason] ?? reason ?? '';
}

/// filterChile=true muestra solo el mercado chileno (equivalente a UniverseChile.jsx)
class UniverseScreen extends StatefulWidget {
  final bool filterChile;
  const UniverseScreen({super.key, this.filterChile = false});
  @override
  State<UniverseScreen> createState() => _UniverseScreenState();
}

class _UniverseScreenState extends State<UniverseScreen> {
  final _api = ApiService();
  bool _loading = true;
  String? _error;
  List<UniverseRow> _rows = [];
  bool _groupByMarket = false;

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
      var rows = await _api.fetchUniverse();
      if (widget.filterChile) {
        rows = rows.where((r) => _marketInfo(r.ticker)['market'] == 'CL').toList();
      }
      setState(() {
        _rows = rows;
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

    final exec = _rows.where((r) => r.executable).length;
    final markets = _rows.map((r) => _marketInfo(r.ticker)['flag']).toSet().join(' ');

    final sorted = [..._rows];
    if (_groupByMarket) {
      sorted.sort((a, b) {
        final mi = _marketOrder.indexOf(_marketInfo(a.ticker)['market']!);
        final mj = _marketOrder.indexOf(_marketInfo(b.ticker)['market']!);
        if (mi != mj) return mi.compareTo(mj);
        return (b.alpha ?? -99).compareTo(a.alpha ?? -99);
      });
    } else {
      sorted.sort((a, b) => (b.alpha ?? -99).compareTo(a.alpha ?? -99));
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.filterChile ? 'Universe Chile' : 'Universe Institucional', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Activos: ${_rows.length} · Ejecutables: $exec · $markets', style: const TextStyle(color: Color(AppColors.mutedDark), fontSize: 12)),
              ]),
            ),
            if (!widget.filterChile)
              TextButton(
                onPressed: () => setState(() => _groupByMarket = !_groupByMarket),
                child: Text(_groupByMarket ? '🌍 Por país' : '📊 Por alpha', style: const TextStyle(fontSize: 12)),
              ),
          ]),
          const SizedBox(height: 14),
          if (sorted.isEmpty)
            const Text('Sin datos.', style: TextStyle(color: Color(AppColors.muted)))
          else
            ..._buildRows(sorted),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  List<Widget> _buildRows(List<UniverseRow> sorted) {
    final widgets = <Widget>[];
    String? lastMarket;
    for (final r in sorted) {
      final info = _marketInfo(r.ticker);
      if (_groupByMarket && info['market'] != lastMarket) {
        lastMarket = info['market'];
        final count = sorted.where((x) => _marketInfo(x.ticker)['market'] == lastMarket).length;
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 6),
          child: Text('${info['flag']} ${info['market']} · $count activos', style: const TextStyle(color: Color(AppColors.mutedDark), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        ));
      }
      widgets.add(_UniverseRowTile(row: r, flag: info['flag']!, onTap: () => showTickerDetail(context, r.ticker)));
    }
    return widgets;
  }
}

class _UniverseRowTile extends StatelessWidget {
  final UniverseRow row;
  final String flag;
  final VoidCallback onTap;
  const _UniverseRowTile({required this.row, required this.flag, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: const Color(AppColors.bgTile), borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          Expanded(
            flex: 2,
            child: Text('${row.ticker} $flag', style: const TextStyle(color: Color(AppColors.blue), fontWeight: FontWeight.w700, fontSize: 14)),
          ),
          Expanded(
            child: Text(row.alpha != null ? row.alpha!.toStringAsFixed(3) : '—', style: TextStyle(color: _colorAlpha(row.alpha), fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.right),
          ),
          Expanded(
            child: Text(row.confidence != null ? row.confidence!.toStringAsFixed(2) : '—', style: TextStyle(color: _colorConf(row.confidence), fontWeight: FontWeight.w600, fontSize: 13), textAlign: TextAlign.right),
          ),
          Expanded(
            flex: 2,
            child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(row.executable ? '✅ Ejecutable' : '❌', style: TextStyle(color: row.executable ? const Color(AppColors.green) : const Color(AppColors.red), fontWeight: FontWeight.bold, fontSize: 12)),
              if (!row.executable && row.blockReason != null)
                Text(_reasonLabel(row.blockReason), style: const TextStyle(color: Color(AppColors.mutedDark), fontSize: 9), textAlign: TextAlign.right),
            ]),
          ),
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
