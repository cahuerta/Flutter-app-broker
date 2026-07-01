// =========================================================
// MODELOS — mapeados a los JSON reales de dashboard.py / main.py
// =========================================================

double? _f(dynamic v) => v == null ? null : (v as num).toDouble();
int? _i(dynamic v) => v == null ? null : (v as num).toInt();

// ---------- GLOBAL: /dashboard/performance ----------
class PerformanceData {
  final double? equity;
  final double? totalReturnPct;
  final double? drawdownPct;
  final double? highWaterMark;
  final double? initialEquity;
  final String? since;

  PerformanceData({this.equity, this.totalReturnPct, this.drawdownPct, this.highWaterMark, this.initialEquity, this.since});

  factory PerformanceData.fromJson(Map<String, dynamic> j) => PerformanceData(
        equity: _f(j['equity']),
        totalReturnPct: _f(j['total_return_pct']),
        drawdownPct: _f(j['drawdown_pct']),
        highWaterMark: _f(j['high_water_mark']),
        initialEquity: _f(j['initial_equity']),
        since: j['since'] as String?,
      );
}

// ---------- GLOBAL: /dashboard/equity-curve ----------
class EquityPoint {
  final String date;
  final double equity;
  final double? returnPct;
  EquityPoint({required this.date, required this.equity, this.returnPct});

  factory EquityPoint.fromJson(Map<String, dynamic> j) => EquityPoint(
        date: j['date']?.toString() ?? '',
        equity: _f(j['equity']) ?? 0,
        returnPct: _f(j['return_pct']),
      );
}

// ---------- GLOBAL: /dashboard/model-quality ----------
class HorizonStat {
  final double? hitRatePct;
  final int? total;
  HorizonStat({this.hitRatePct, this.total});
  factory HorizonStat.fromJson(Map<String, dynamic> j) =>
      HorizonStat(hitRatePct: _f(j['hit_rate_pct']), total: _i(j['total']));
}

class ModelQuality {
  final double? hitRateDirectionPct;
  final double? avgErrorPct;
  final String? trend;
  final double? hitRate7d;
  final double? hitRate14d;
  final double? hitRate30d;
  final Map<String, int> recentWindowSizes;
  final int? evaluated;
  final int? pending;
  final int? total;
  final Map<String, HorizonStat> byRecommendation;
  final Map<String, HorizonStat> byHorizon;

  ModelQuality({
    this.hitRateDirectionPct,
    this.avgErrorPct,
    this.trend,
    this.hitRate7d,
    this.hitRate14d,
    this.hitRate30d,
    this.recentWindowSizes = const {},
    this.evaluated,
    this.pending,
    this.total,
    this.byRecommendation = const {},
    this.byHorizon = const {},
  });

  factory ModelQuality.fromJson(Map<String, dynamic> j) {
    Map<String, HorizonStat> mapOf(dynamic raw) {
      if (raw is! Map) return {};
      return raw.map((k, v) => MapEntry(k.toString(), HorizonStat.fromJson(v as Map<String, dynamic>)));
    }

    final sizes = <String, int>{};
    final rawSizes = j['recent_window_sizes'];
    if (rawSizes is Map) {
      rawSizes.forEach((k, v) => sizes[k.toString()] = _i(v) ?? 0);
    }

    return ModelQuality(
      hitRateDirectionPct: _f(j['hit_rate_direction_pct']),
      avgErrorPct: _f(j['avg_error_pct']),
      trend: j['trend'] as String?,
      hitRate7d: _f(j['hit_rate_7d_pct']),
      hitRate14d: _f(j['hit_rate_14d_pct']),
      hitRate30d: _f(j['hit_rate_30d_pct']),
      recentWindowSizes: sizes,
      evaluated: _i(j['evaluated']),
      pending: _i(j['pending']),
      total: _i(j['total']),
      byRecommendation: mapOf(j['by_recommendation']),
      byHorizon: mapOf(j['by_horizon']),
    );
  }
}

// ---------- GLOBAL: /dashboard/order-analysis ----------
class OrderGroupStats {
  final double? hitRateDirPct;
  final double? avgRealReturn;
  final int? tickersFound;
  final int? totalEvaluations;
  final String? bestHorizon;
  final Map<String, HorizonStat> byRecommendation;

  OrderGroupStats({this.hitRateDirPct, this.avgRealReturn, this.tickersFound, this.totalEvaluations, this.bestHorizon, this.byRecommendation = const {}});

  factory OrderGroupStats.fromJson(Map<String, dynamic>? j) {
    if (j == null) return OrderGroupStats();
    Map<String, HorizonStat> mapOf(dynamic raw) {
      if (raw is! Map) return {};
      return raw.map((k, v) => MapEntry(k.toString(), HorizonStat.fromJson(v as Map<String, dynamic>)));
    }

    return OrderGroupStats(
      hitRateDirPct: _f(j['hit_rate_dir_pct']),
      avgRealReturn: _f(j['avg_real_return']),
      tickersFound: _i(j['tickers_found']),
      totalEvaluations: _i(j['total_evaluations']),
      bestHorizon: j['best_horizon'] as String?,
      byRecommendation: mapOf(j['by_recommendation']),
    );
  }
}

class OrderAnalysis {
  final String status;
  final OrderGroupStats? systemBuys;
  final OrderGroupStats? manualBuys;
  final double? universeBaseline;
  final String? winner;
  final String? verdictText;
  final String? generatedAt;

  OrderAnalysis({required this.status, this.systemBuys, this.manualBuys, this.universeBaseline, this.winner, this.verdictText, this.generatedAt});

  factory OrderAnalysis.fromJson(Map<String, dynamic> j) {
    final verdict = j['verdict'] as Map<String, dynamic>?;
    return OrderAnalysis(
      status: j['status']?.toString() ?? 'idle',
      systemBuys: OrderGroupStats.fromJson(j['system_buys'] as Map<String, dynamic>?),
      manualBuys: OrderGroupStats.fromJson(j['manual_buys'] as Map<String, dynamic>?),
      universeBaseline: _f(verdict?['universe_baseline']),
      winner: verdict?['winner'] as String?,
      verdictText: verdict?['text'] as String?,
      generatedAt: j['generated_at'] as String?,
    );
  }
}

// ---------- SCREENER: /dashboard/screener ----------
class ScreenerCandidate {
  final String ticker;
  final double? score;
  final double? trend3mPct;
  final double? sharpeRatio;
  final double? rsiWilder;
  final double? maxDrawdownPct;

  ScreenerCandidate({required this.ticker, this.score, this.trend3mPct, this.sharpeRatio, this.rsiWilder, this.maxDrawdownPct});

  factory ScreenerCandidate.fromJson(Map<String, dynamic> j) => ScreenerCandidate(
        ticker: (j['ticker'] ?? '').toString(),
        score: _f(j['score']),
        trend3mPct: _f(j['trend_3m_pct']),
        sharpeRatio: _f(j['sharpe_ratio']),
        rsiWilder: _f(j['rsi_wilder']),
        maxDrawdownPct: _f(j['max_drawdown_pct']),
      );
}

// ---------- PORTFOLIO: /trading/status ----------
class PortfolioStatus {
  final double? equity;
  final double? buyingPower;
  final bool paper;
  final bool tradingBlocked;

  PortfolioStatus({this.equity, this.buyingPower, this.paper = true, this.tradingBlocked = false});

  factory PortfolioStatus.fromJson(Map<String, dynamic> j) => PortfolioStatus(
        equity: _f(j['equity']),
        buyingPower: _f(j['buying_power']),
        paper: j['paper'] ?? true,
        tradingBlocked: j['trading_blocked'] ?? false,
      );
}

// ---------- PORTFOLIO: /trading/positions ----------
class Position {
  final String ticker;
  final double qty;
  final double entryPrice;
  final double? currentPrice;
  final double? marketValue;
  final double? unrealizedPl;

  Position({required this.ticker, required this.qty, required this.entryPrice, this.currentPrice, this.marketValue, this.unrealizedPl});

  factory Position.fromJson(String ticker, Map<String, dynamic> j) => Position(
        ticker: ticker,
        qty: _f(j['qty']) ?? 0,
        entryPrice: _f(j['avg_entry_price']) ?? 0,
        currentPrice: _f(j['current_price']),
        marketValue: _f(j['market_value']),
        unrealizedPl: _f(j['unrealized_pl']),
      );
}

// ---------- ANALYSIS: /dashboard/latest/{ticker} ----------
class ModelDiagnostic {
  final String model;
  final double? horizon;
  final double? predReturn;
  final double? realReturn;
  final double? errorPct;

  ModelDiagnostic({required this.model, this.horizon, this.predReturn, this.realReturn, this.errorPct});

  factory ModelDiagnostic.fromJson(String model, Map<String, dynamic> j) => ModelDiagnostic(
        model: model,
        horizon: _f(j['horizon']),
        predReturn: _f(j['pred_return']),
        realReturn: _f(j['real_return']),
        errorPct: _f(j['error_pct']),
      );
}

class PredictionData {
  final String? recommendation;
  final double? retEnsPct;
  final double? pricePred;
  final double? priceNow;
  final double? thetaDynamicPct;
  final String? dateBase;

  PredictionData({this.recommendation, this.retEnsPct, this.pricePred, this.priceNow, this.thetaDynamicPct, this.dateBase});

  factory PredictionData.fromJson(Map<String, dynamic>? j) {
    if (j == null) return PredictionData();
    return PredictionData(
      recommendation: j['recommendation'] as String?,
      retEnsPct: _f(j['ret_ens_pct']),
      pricePred: _f(j['price_pred']),
      priceNow: _f(j['price_now']),
      thetaDynamicPct: _f(j['theta_dynamic_pct']),
      dateBase: j['date_base'] as String?,
    );
  }
}

class HistoricalData {
  final double? hitRateMean;
  final double? maeMean;
  final int? nWindows;
  final String? source;

  HistoricalData({this.hitRateMean, this.maeMean, this.nWindows, this.source});

  factory HistoricalData.fromJson(Map<String, dynamic>? j) {
    if (j == null) return HistoricalData();
    return HistoricalData(
      hitRateMean: _f(j['hit_rate_mean']),
      maeMean: _f(j['mae_mean']),
      nWindows: _i(j['n_windows']),
      source: j['source'] as String?,
    );
  }
}

class LatestSnapshot {
  final PredictionData prediction;
  final HistoricalData historical;
  final List<ModelDiagnostic> diagnostics;
  final int ensembleModels;
  final double? priceNowCurve;
  final List<double> pricePath;

  LatestSnapshot({required this.prediction, required this.historical, this.diagnostics = const [], this.ensembleModels = 0, this.priceNowCurve, this.pricePath = const []});

  factory LatestSnapshot.fromJson(Map<String, dynamic> j) {
    final diagRaw = j['models_diagnostics'];
    final diags = <ModelDiagnostic>[];
    if (diagRaw is Map) {
      diagRaw.forEach((k, v) {
        if (v is Map<String, dynamic>) diags.add(ModelDiagnostic.fromJson(k.toString(), v));
      });
      diags.sort((a, b) => (a.horizon ?? 0).compareTo(b.horizon ?? 0));
    }
    final curve = j['price_curve'] as Map<String, dynamic>?;
    final pathRaw = curve?['price_path'];
    final path = <double>[];
    if (pathRaw is List) {
      for (final p in pathRaw) {
        final v = _f(p);
        if (v != null) path.add(v);
      }
    }
    return LatestSnapshot(
      prediction: PredictionData.fromJson(j['prediction'] as Map<String, dynamic>?),
      historical: HistoricalData.fromJson(j['historical'] as Map<String, dynamic>?),
      diagnostics: diags,
      ensembleModels: _i(j['ensemble_models']) ?? 0,
      priceNowCurve: _f(curve?['price_now']),
      pricePath: path,
    );
  }
}

class AlphaData {
  final double? alphaScore;
  final double? confidence;
  final bool thetaCleared;
  final String? error;

  AlphaData({this.alphaScore, this.confidence, this.thetaCleared = false, this.error});

  factory AlphaData.fromJson(Map<String, dynamic>? j) {
    if (j == null) return AlphaData();
    final components = j['components'] as Map<String, dynamic>?;
    final flags = j['flags'] as Map<String, dynamic>?;
    return AlphaData(
      alphaScore: _f(j['alpha_score']),
      confidence: _f(components?['confidence']),
      thetaCleared: flags?['v6_3_theta_cleared'] == true,
      error: j['error'] as String?,
    );
  }
}
