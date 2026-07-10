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

// ---------- GLOBAL: /dashboard/market-context ----------
class MarketContext {
  final String? marketMode;
  final double? confidence;
  final String? reason;
  final String? timestamp;

  MarketContext({this.marketMode, this.confidence, this.reason, this.timestamp});

  factory MarketContext.fromJson(Map<String, dynamic> j) => MarketContext(
        marketMode: j['market_mode'] as String?,
        confidence: _f(j['confidence']),
        reason: j['reason'] as String?,
        timestamp: j['timestamp'] as String?,
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

class ScreenerSections {
  final List<ScreenerCandidate> strict;
  final List<ScreenerCandidate> top20;
  ScreenerSections({required this.strict, required this.top20});
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

// ---------- UNIVERSE: /dashboard/universe ----------
class UniverseRow {
  final String ticker;
  final double? alpha;
  final double? confidence;
  final double positionValue;
  final bool executable;
  final String? blockReason;
  final bool hasPosition;
  final String? modeContext;

  UniverseRow({
    required this.ticker,
    this.alpha,
    this.confidence,
    this.positionValue = 0,
    this.executable = false,
    this.blockReason,
    this.hasPosition = false,
    this.modeContext,
  });

  factory UniverseRow.fromJson(Map<String, dynamic> j) => UniverseRow(
        ticker: (j['ticker'] ?? '').toString(),
        alpha: _f(j['alpha']),
        confidence: _f(j['confidence']),
        positionValue: _f(j['positionValue']) ?? 0,
        executable: j['executable'] == true,
        blockReason: j['block_reason'] as String?,
        hasPosition: j['has_position'] == true,
        modeContext: j['mode_context'] as String?,
      );

  String get blockReasonLabel {
    switch (blockReason) {
      case 'no_alpha':
        return 'Sin alpha calculado aún';
      case 'kill_switch_close':
        return 'Kill switch — cerrar posición';
      case 'kill_switch_no_open':
        return 'Kill switch — no abrir';
      case 'alpha_below_threshold':
        return 'Alpha bajo el umbral del modo actual';
      default:
        return blockReason ?? '—';
    }
  }
}

// ---------- SIGNALS: /signals ----------
class SignalRow {
  final String ticker;
  final double? confidence;
  final String? quality;
  final String? recommendation;

  SignalRow({required this.ticker, this.confidence, this.quality, this.recommendation});

  factory SignalRow.fromJson(Map<String, dynamic> j) => SignalRow(
        ticker: (j['ticker'] ?? '').toString(),
        confidence: _f(j['confidence']),
        quality: j['quality'] as String?,
        recommendation: j['recommendation'] as String?,
      );

  String get qualityLabel {
    final q = quality ?? '';
    if (q.contains('STRONG')) return '🔥 Alta';
    if (q.contains('GOOD')) return '✅ Buena';
    if (q.contains('WEAK')) return '⚠️ Débil';
    return '❌ Ruido';
  }

  String get recommendationLabel {
    final r = (recommendation ?? '').toUpperCase();
    if (r.contains('BUY')) return '🟢 Comprar';
    if (r.contains('SELL')) return '🔴 Vender';
    if (r.contains('HOLD')) return '🟡 Mantener';
    return recommendation ?? '—';
  }
}

// ---------- GLOBAL: /dashboard/real-performance ----------
class BacktestResult {
  final String label;
  final int? nTrades;
  final int? nDays;
  final int? nEvaluations;
  final double? sharpeClassic;
  final double? sharpeNeweyWest;
  final double? maxDrawdown;
  final double? winRate;
  final double? totalReturnPct;
  final double? avgDailyReturnPct;

  BacktestResult({
    required this.label,
    this.nTrades,
    this.nDays,
    this.nEvaluations,
    this.sharpeClassic,
    this.sharpeNeweyWest,
    this.maxDrawdown,
    this.winRate,
    this.totalReturnPct,
    this.avgDailyReturnPct,
  });

  factory BacktestResult.fromJson(Map<String, dynamic> j) => BacktestResult(
        label: (j['label'] ?? '').toString(),
        nTrades: _i(j['n_trades']),
        nDays: _i(j['n_days']),
        nEvaluations: _i(j['n_evaluations']),
        sharpeClassic: _f(j['sharpe_classic']),
        sharpeNeweyWest: _f(j['sharpe_newey_west']),
        maxDrawdown: _f(j['max_drawdown']),
        winRate: _f(j['win_rate']),
        totalReturnPct: _f(j['total_return_pct']),
        avgDailyReturnPct: _f(j['avg_daily_return_pct']),
      );
}

class ClosedEarlyStats {
  final int? nOportunidadPerdida;
  final double? avgOportunidadPerdidaPct;
  final int? nOportunidadGanada;
  final double? avgOportunidadGanadaPct;

  const ClosedEarlyStats({    // ← FIX: agregado "const"
    this.nOportunidadPerdida,
    this.avgOportunidadPerdidaPct,
    this.nOportunidadGanada,
    this.avgOportunidadGanadaPct,
  });

  factory ClosedEarlyStats.fromJson(Map<String, dynamic>? j) {
    if (j == null) return ClosedEarlyStats();
    return ClosedEarlyStats(
      nOportunidadPerdida: _i(j['n_oportunidad_perdida']),
      avgOportunidadPerdidaPct: _f(j['avg_oportunidad_perdida_pct']),
      nOportunidadGanada: _i(j['n_oportunidad_ganada']),
      avgOportunidadGanadaPct: _f(j['avg_oportunidad_ganada_pct']),
    );
  }
}

class RealPerformance {
  final String status;
  final BacktestResult? ensemble;              // theoretical.ensemble
  final Map<String, BacktestResult> byHorizon;  // theoretical.by_horizon (H1..H10)
  final BacktestResult? realAccount;            // real.real_account
  final Map<String, BacktestResult> byDominantH; // real.by_dominant_h
  final ClosedEarlyStats closedEarlyStats;
  final String? generatedAt;

  RealPerformance({
    required this.status,
    this.ensemble,
    this.byHorizon = const {},
    this.realAccount,
    this.byDominantH = const {},
    this.closedEarlyStats = const ClosedEarlyStats(),
    this.generatedAt,
  });

  factory RealPerformance.fromJson(Map<String, dynamic> j) {
    Map<String, BacktestResult> mapOf(dynamic raw) {
      if (raw is! Map) return {};
      return raw.map((k, v) => MapEntry(k.toString(), BacktestResult.fromJson(v as Map<String, dynamic>)));
    }

    final theoretical = j['theoretical'] as Map<String, dynamic>?;
    final real = j['real'] as Map<String, dynamic>?;

    return RealPerformance(
      status: j['status']?.toString() ?? 'idle',
      ensemble: theoretical?['ensemble'] != null
          ? BacktestResult.fromJson(theoretical!['ensemble'] as Map<String, dynamic>)
          : null,
      byHorizon: mapOf(theoretical?['by_horizon']),
      realAccount: real?['real_account'] != null
          ? BacktestResult.fromJson(real!['real_account'] as Map<String, dynamic>)
          : null,
      byDominantH: mapOf(real?['by_dominant_h']),
      closedEarlyStats: ClosedEarlyStats.fromJson(real?['closed_early_stats'] as Map<String, dynamic>?),
      generatedAt: j['generated_at'] as String?,
    );
  }
}
