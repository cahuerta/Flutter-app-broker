import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart';
import 'models.dart';

class ApiService {
  Uri _u(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  Future<dynamic> _getJson(String path) async {
    final res = await http.get(_u(path), headers: {'Accept': 'application/json'});
    if (res.statusCode != 200) {
      throw Exception('$path → HTTP ${res.statusCode}');
    }
    return jsonDecode(utf8.decode(res.bodyBytes));
  }

  // ---------- GLOBAL ----------
  Future<PerformanceData> fetchPerformance() async {
    final j = await _getJson('/dashboard/performance');
    return PerformanceData.fromJson(j as Map<String, dynamic>);
  }

  Future<List<EquityPoint>> fetchEquityCurve() async {
    final j = await _getJson('/dashboard/equity-curve') as Map<String, dynamic>;
    final curve = (j['curve'] as List?) ?? [];
    return curve.map((e) => EquityPoint.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ModelQuality> fetchModelQuality() async {
    final j = await _getJson('/dashboard/model-quality');
    return ModelQuality.fromJson(j as Map<String, dynamic>);
  }

  Future<OrderAnalysis?> fetchOrderAnalysis() async {
    try {
      final j = await _getJson('/dashboard/order-analysis') as Map<String, dynamic>;
      if (j['status'] != 'ready') return null;
      return OrderAnalysis.fromJson(j);
    } catch (_) {
      return null;
    }
  }

  Future<void> runOrderAnalysis() async {
    await http.post(_u('/dashboard/order-analysis/run'));
  }

  // ---------- SCREENER ----------
  Future<List<ScreenerCandidate>> fetchScreener() async {
    final j = await _getJson('/dashboard/screener') as Map<String, dynamic>;
    final strict = (j['candidates_strict'] as List?) ?? [];
    final top20 = (j['top20_global'] as List?) ?? [];
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

  // ---------- PORTFOLIO ----------
  Future<PortfolioStatus> fetchStatus() async {
    final j = await _getJson('/trading/status');
    return PortfolioStatus.fromJson(j as Map<String, dynamic>);
  }

  Future<List<Position>> fetchPositions() async {
    final j = await _getJson('/trading/positions') as Map<String, dynamic>;
    return j.entries.map((e) => Position.fromJson(e.key, e.value as Map<String, dynamic>)).toList();
  }

  // ---------- ANALYSIS ----------
  Future<List<String>> fetchTickers() async {
    final j = await _getJson('/dashboard/tickers') as Map<String, dynamic>;
    return ((j['tickers'] as List?) ?? []).map((e) => e.toString()).toList();
  }

  Future<LatestSnapshot> fetchLatest(String ticker) async {
    final j = await _getJson('/dashboard/latest/$ticker') as Map<String, dynamic>;
    return LatestSnapshot.fromJson(j['latest'] as Map<String, dynamic>);
  }

  Future<AlphaData> fetchAlpha(String ticker) async {
    final j = await _getJson('/alpha') as Map<String, dynamic>;
    final results = j['results'] as Map<String, dynamic>?;
    return AlphaData.fromJson(results?[ticker] as Map<String, dynamic>?);
  }
}
