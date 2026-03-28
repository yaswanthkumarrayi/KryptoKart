import 'dart:async';
import 'package:dio/dio.dart';
import 'package:fl_chart/fl_chart.dart';
import '../constants/api_constants.dart';
import '../models/coin_model.dart';

/// Optimized CoinGecko service with:
/// - Smart caching (30s TTL)
/// - Request deduplication
/// - Automatic retry with exponential backoff
/// - Single API call optimization
class CoinGeckoService {
  final Dio _dio;

  // In-memory cache with shorter TTL for faster updates
  final Map<String, _CacheEntry> _cache = {};
  static const Duration _cacheTtl = Duration(seconds: 30);
  
  // Request deduplication - prevent multiple simultaneous requests for same data
  final Map<String, Future<dynamic>> _pendingRequests = {};
  
  // Last successful data for fallback
  List<CoinModel>? _lastMarketData;
  Map<String, dynamic>? _lastPriceData;

  CoinGeckoService()
    : _dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

  /// Fetch markets with request deduplication
  Future<List<CoinModel>> fetchMarkets({
    String currency = 'inr',
    int perPage = 10,
  }) async {
    final cacheKey = 'markets_${currency}_$perPage';
    
    // Return cached data if valid
    final cached = _getFromCache<List<CoinModel>>(cacheKey);
    if (cached != null) return cached;
    
    // Deduplicate concurrent requests
    if (_pendingRequests.containsKey(cacheKey)) {
      try {
        return await _pendingRequests[cacheKey] as List<CoinModel>;
      } catch (_) {
        return _lastMarketData ?? [];
      }
    }

    // Create new request
    final completer = Completer<List<CoinModel>>();
    _pendingRequests[cacheKey] = completer.future;

    try {
      final coins = await _fetchMarketsInternal(currency, perPage);
      _setCache(cacheKey, coins);
      _lastMarketData = coins;
      completer.complete(coins);
      return coins;
    } catch (e) {
      // Return last known data on error
      final fallback = _lastMarketData ?? [];
      completer.complete(fallback);
      return fallback;
    } finally {
      _pendingRequests.remove(cacheKey);
    }
  }

  Future<List<CoinModel>> _fetchMarketsInternal(String currency, int perPage) async {
    final response = await _retryRequest(() => _dio.get(
      ApiConstants.marketsEndpoint(currency: currency, perPage: perPage),
    ));

    if (response.data == null || response.data is! List) {
      return [];
    }

    return (response.data as List)
        .where((json) => json != null && json is Map<String, dynamic>)
        .map((json) => CoinModel.fromCoinGecko(json as Map<String, dynamic>, currency: currency))
        .toList();
  }

  /// Fetch market chart with request deduplication
  Future<List<FlSpot>> fetchMarketChart(String coinId, {int days = 7}) async {
    final cacheKey = 'chart_${coinId}_$days';
    
    final cached = _getFromCache<List<FlSpot>>(cacheKey);
    if (cached != null) return cached;
    
    // Deduplicate
    if (_pendingRequests.containsKey(cacheKey)) {
      try {
        return await _pendingRequests[cacheKey] as List<FlSpot>;
      } catch (_) {
        return [];
      }
    }

    final completer = Completer<List<FlSpot>>();
    _pendingRequests[cacheKey] = completer.future;

    try {
      final spots = await _fetchChartInternal(coinId, days);
      _setCache(cacheKey, spots);
      completer.complete(spots);
      return spots;
    } catch (e) {
      completer.complete([]);
      return [];
    } finally {
      _pendingRequests.remove(cacheKey);
    }
  }

  Future<List<FlSpot>> _fetchChartInternal(String coinId, int days) async {
    final response = await _retryRequest(() => _dio.get(
      'https://api.coingecko.com/api/v3/coins/$coinId/market_chart?vs_currency=inr&days=$days',
    ));

    if (response.data == null || response.data['prices'] == null) {
      return [];
    }

    final prices = response.data['prices'] as List;
    return prices.asMap().entries.map((entry) {
      final value = entry.value;
      if (value is List && value.length >= 2) {
        return FlSpot(entry.key.toDouble(), (value[1] as num).toDouble());
      }
      return FlSpot(entry.key.toDouble(), 0);
    }).toList();
  }

  /// Fetch simple price with request deduplication
  Future<Map<String, dynamic>> fetchSimplePrice(List<String> coinIds) async {
    if (coinIds.isEmpty) return {};
    
    final sortedIds = List<String>.from(coinIds)..sort();
    final cacheKey = 'simple_${sortedIds.join(',')}';
    
    final cached = _getFromCache<Map<String, dynamic>>(cacheKey);
    if (cached != null) return cached;
    
    // Deduplicate
    if (_pendingRequests.containsKey(cacheKey)) {
      try {
        return await _pendingRequests[cacheKey] as Map<String, dynamic>;
      } catch (_) {
        return _lastPriceData ?? {};
      }
    }

    final completer = Completer<Map<String, dynamic>>();
    _pendingRequests[cacheKey] = completer.future;

    try {
      final data = await _fetchPriceInternal(sortedIds);
      _setCache(cacheKey, data);
      _lastPriceData = data;
      completer.complete(data);
      return data;
    } catch (e) {
      final fallback = _lastPriceData ?? {};
      completer.complete(fallback);
      return fallback;
    } finally {
      _pendingRequests.remove(cacheKey);
    }
  }

  Future<Map<String, dynamic>> _fetchPriceInternal(List<String> coinIds) async {
    final response = await _retryRequest(() => _dio.get(
      'https://api.coingecko.com/api/v3/simple/price?ids=${coinIds.join(',')}&vs_currencies=inr&include_24hr_change=true',
    ));

    if (response.data == null) {
      return {};
    }

    return Map<String, dynamic>.from(response.data);
  }

  /// Retry request with exponential backoff
  Future<Response<T>> _retryRequest<T>(Future<Response<T>> Function() request, {int maxRetries = 2}) async {
    int attempt = 0;
    while (true) {
      try {
        return await request();
      } on DioException catch (e) {
        attempt++;
        
        // Don't retry on 429 rate limit - use cache
        if (e.response?.statusCode == 429) {
          rethrow;
        }
        
        // Don't retry on client errors (4xx)
        if (e.response?.statusCode != null && 
            e.response!.statusCode! >= 400 && 
            e.response!.statusCode! < 500) {
          rethrow;
        }
        
        if (attempt >= maxRetries) {
          rethrow;
        }
        
        // Exponential backoff
        await Future.delayed(Duration(milliseconds: 200 * attempt));
      }
    }
  }

  /// Convert INR to crypto
  Future<double> convertInrToCrypto(double inrAmount, String coinId) async {
    try {
      final prices = await fetchSimplePrice([coinId]);
      final inrPrice = (prices[coinId]?['inr'] as num?)?.toDouble();
      if (inrPrice == null || inrPrice == 0) return 0;
      return inrAmount / inrPrice;
    } catch (e) {
      return 0;
    }
  }

  /// Convert crypto to INR
  Future<double> convertCryptoToInr(double cryptoAmount, String coinId) async {
    try {
      final prices = await fetchSimplePrice([coinId]);
      final inrPrice = (prices[coinId]?['inr'] as num?)?.toDouble();
      if (inrPrice == null) return 0;
      return cryptoAmount * inrPrice;
    } catch (e) {
      return 0;
    }
  }

  /// Preload data for faster initial load
  Future<void> preloadData() async {
    // Preload common data in parallel
    await Future.wait([
      fetchMarkets(perPage: 30),
      fetchSimplePrice([
        'bitcoin', 'ethereum', 'tether', 'binancecoin', 'solana',
        'ripple', 'cardano', 'dogecoin', 'matic-network',
      ]),
    ]);
  }

  // Cache helpers
  T? _getFromCache<T>(String key, {bool ignoreExpiry = false}) {
    final entry = _cache[key];
    if (entry == null) return null;
    if (!ignoreExpiry && DateTime.now().isAfter(entry.expiresAt)) {
      return null;
    }
    try {
      return entry.data as T;
    } catch (e) {
      return null;
    }
  }

  void _setCache(String key, dynamic data) {
    _cache[key] = _CacheEntry(
      data: data,
      expiresAt: DateTime.now().add(_cacheTtl),
    );
  }

  /// Clear all cache (useful for force refresh)
  void clearCache() {
    _cache.clear();
  }
}

class _CacheEntry {
  final dynamic data;
  final DateTime expiresAt;

  _CacheEntry({required this.data, required this.expiresAt});
}
