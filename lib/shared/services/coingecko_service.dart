import 'package:dio/dio.dart';
import 'package:fl_chart/fl_chart.dart';
import '../constants/api_constants.dart';
import '../models/coin_model.dart';

class CoinGeckoService {
  final Dio _dio;

  // In-memory cache
  final Map<String, _CacheEntry> _cache = {};
  static const Duration _cacheTtl = Duration(seconds: 60);

  CoinGeckoService()
      : _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ));

  Future<List<CoinModel>> fetchMarkets({String currency = 'usd', int perPage = 10}) async {
    final cacheKey = 'markets_${currency}_$perPage';
    final cached = _getFromCache<List<CoinModel>>(cacheKey);
    if (cached != null) return cached;

    try {
      final response = await _dio.get(
        ApiConstants.marketsEndpoint(currency: currency, perPage: perPage),
      );

      final List<CoinModel> coins = (response.data as List)
          .map((json) => CoinModel.fromCoinGecko(json))
          .toList();

      _setCache(cacheKey, coins);
      return coins;
    } on DioException catch (e) {
      if (e.response?.statusCode == 429) {
        // Rate limited - return cached data if available
        final stale = _getFromCache<List<CoinModel>>(cacheKey, ignoreExpiry: true);
        if (stale != null) return stale;
      }
      rethrow;
    }
  }

  Future<List<FlSpot>> fetchMarketChart(String coinId, {int days = 7}) async {
    final cacheKey = 'chart_${coinId}_$days';
    final cached = _getFromCache<List<FlSpot>>(cacheKey);
    if (cached != null) return cached;

    try {
      final response = await _dio.get(
        ApiConstants.marketChartEndpoint(coinId, days: days),
      );

      final prices = response.data['prices'] as List;
      final spots = prices.asMap().entries.map((entry) {
        return FlSpot(entry.key.toDouble(), (entry.value[1] as num).toDouble());
      }).toList();

      _setCache(cacheKey, spots);
      return spots;
    } on DioException catch (e) {
      if (e.response?.statusCode == 429) {
        final stale = _getFromCache<List<FlSpot>>(cacheKey, ignoreExpiry: true);
        if (stale != null) return stale;
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> fetchSimplePrice(List<String> coinIds) async {
    final cacheKey = 'simple_${coinIds.join(',')}';
    final cached = _getFromCache<Map<String, dynamic>>(cacheKey);
    if (cached != null) return cached;

    try {
      final response = await _dio.get(
        ApiConstants.simplePriceEndpoint(coinIds),
      );

      final data = Map<String, dynamic>.from(response.data);
      _setCache(cacheKey, data);
      return data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 429) {
        final stale = _getFromCache<Map<String, dynamic>>(cacheKey, ignoreExpiry: true);
        if (stale != null) return stale;
      }
      rethrow;
    }
  }

  Future<double> convertInrToCrypto(double inrAmount, String coinId) async {
    final prices = await fetchSimplePrice([coinId]);
    final inrPrice = (prices[coinId]?['inr'] as num?)?.toDouble();
    if (inrPrice == null || inrPrice == 0) return 0;
    return inrAmount / inrPrice;
  }

  // Cache helpers
  T? _getFromCache<T>(String key, {bool ignoreExpiry = false}) {
    final entry = _cache[key];
    if (entry == null) return null;
    if (!ignoreExpiry && DateTime.now().isAfter(entry.expiresAt)) {
      return null;
    }
    return entry.data as T;
  }

  void _setCache(String key, dynamic data) {
    _cache[key] = _CacheEntry(
      data: data,
      expiresAt: DateTime.now().add(_cacheTtl),
    );
  }
}

class _CacheEntry {
  final dynamic data;
  final DateTime expiresAt;

  _CacheEntry({required this.data, required this.expiresAt});
}
