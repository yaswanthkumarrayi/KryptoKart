import 'dart:async';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:fl_chart/fl_chart.dart';
import '../constants/api_constants.dart';
import '../models/coin_model.dart';

/// Error types for better error handling
enum CoinGeckoErrorType { network, rateLimit, notFound, serverError, unknown }

class CoinGeckoException implements Exception {
  final CoinGeckoErrorType type;
  final String message;
  final int? statusCode;

  CoinGeckoException(this.type, this.message, {this.statusCode});

  @override
  String toString() => 'CoinGeckoException($type): $message';

  bool get isRetryable =>
      type == CoinGeckoErrorType.network ||
      type == CoinGeckoErrorType.serverError;
}

/// Optimized CoinGecko service with:
/// - Smart caching with stale-while-revalidate
/// - Request deduplication
/// - Automatic retry with exponential backoff + jitter
/// - Graceful fallback to cached/last-known data
/// - Rate limit awareness
class CoinGeckoService {
  final Dio _dio;
  final Random _random = Random();

  // In-memory cache with configurable TTL
  final Map<String, _CacheEntry> _cache = {};
  static const Duration _cacheTtl = Duration(seconds: 30);
  static const Duration _staleTtl = Duration(
    minutes: 5,
  ); // Stale data usable for 5 min

  // Request deduplication - prevent multiple simultaneous requests for same data
  final Map<String, Future<dynamic>> _pendingRequests = {};

  // Last successful data for fallback
  List<CoinModel>? _lastMarketData;
  Map<String, dynamic>? _lastPriceData;
  Map<String, List<FlSpot>> _lastChartData = {};

  // Rate limit tracking
  DateTime? _rateLimitedUntil;
  int _consecutiveErrors = 0;
  static const int _maxConsecutiveErrors = 5;

  CoinGeckoService()
    : _dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {'Accept': 'application/json'},
        ),
      );

  /// Check if we're rate limited
  bool get _isRateLimited {
    if (_rateLimitedUntil == null) return false;
    if (DateTime.now().isAfter(_rateLimitedUntil!)) {
      _rateLimitedUntil = null;
      return false;
    }
    return true;
  }

  /// Fetch markets with request deduplication and robust fallback
  Future<List<CoinModel>> fetchMarkets({
    String currency = 'inr',
    int perPage = 10,
  }) async {
    final cacheKey = 'markets_${currency}_$perPage';

    // Return cached data if valid
    final cached = _getFromCache<List<CoinModel>>(cacheKey);
    if (cached != null) return cached;

    // If rate limited, return stale or last known data
    if (_isRateLimited) {
      final stale = _getFromCache<List<CoinModel>>(cacheKey, ignoreExpiry: true);
      return stale ?? _lastMarketData ?? [];
    }

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
      if (coins.isNotEmpty) {
        _setCache(cacheKey, coins);
        _lastMarketData = coins;
        _consecutiveErrors = 0;
      }
      completer.complete(coins);
      return coins;
    } catch (e) {
      _consecutiveErrors++;
      // Return stale data first, then last known, then empty
      final stale = _getFromCache<List<CoinModel>>(cacheKey, ignoreExpiry: true);
      final fallback = stale ?? _lastMarketData ?? [];
      completer.complete(fallback);
      return fallback;
    } finally {
      _pendingRequests.remove(cacheKey);
    }
  }

  Future<List<CoinModel>> _fetchMarketsInternal(
    String currency,
    int perPage,
  ) async {
    final response = await _retryRequest(
      () => _dio.get(
        ApiConstants.marketsEndpoint(currency: currency, perPage: perPage),
      ),
    );

    if (response.data == null || response.data is! List) {
      return [];
    }

    return (response.data as List)
        .where((json) => json != null && json is Map<String, dynamic>)
        .map(
          (json) => CoinModel.fromCoinGecko(
            json as Map<String, dynamic>,
            currency: currency,
          ),
        )
        .toList();
  }

  /// Fetch market chart with request deduplication and sparkline fallback
  Future<List<FlSpot>> fetchMarketChart(String coinId, {int days = 7}) async {
    final cacheKey = 'chart_${coinId}_$days';

    final cached = _getFromCache<List<FlSpot>>(cacheKey);
    if (cached != null && cached.isNotEmpty) return cached;

    // If rate limited, return last known chart or empty
    if (_isRateLimited) {
      final stale = _getFromCache<List<FlSpot>>(cacheKey, ignoreExpiry: true);
      return stale ?? _lastChartData[coinId] ?? [];
    }

    // Deduplicate
    if (_pendingRequests.containsKey(cacheKey)) {
      try {
        return await _pendingRequests[cacheKey] as List<FlSpot>;
      } catch (_) {
        return _lastChartData[coinId] ?? [];
      }
    }

    final completer = Completer<List<FlSpot>>();
    _pendingRequests[cacheKey] = completer.future;

    try {
      final spots = await _fetchChartInternal(coinId, days);
      if (spots.isNotEmpty) {
        _setCache(cacheKey, spots);
        _lastChartData[coinId] = spots;
        _consecutiveErrors = 0;
      }
      completer.complete(spots);
      return spots;
    } catch (e) {
      _consecutiveErrors++;
      // Return stale or last known chart data
      final stale = _getFromCache<List<FlSpot>>(cacheKey, ignoreExpiry: true);
      final fallback = stale ?? _lastChartData[coinId] ?? [];
      completer.complete(fallback);
      return fallback;
    } finally {
      _pendingRequests.remove(cacheKey);
    }
  }

  Future<List<FlSpot>> _fetchChartInternal(String coinId, int days) async {
    final response = await _retryRequest(
      () => _dio.get(
        'https://api.coingecko.com/api/v3/coins/$coinId/market_chart?vs_currency=inr&days=$days',
      ),
    );

    if (response.data == null || response.data['prices'] == null) {
      return [];
    }

    final prices = response.data['prices'] as List;
    if (prices.isEmpty) return [];
    
    // Filter out invalid data points and normalize
    final validSpots = <FlSpot>[];
    for (int i = 0; i < prices.length; i++) {
      final value = prices[i];
      if (value is List && value.length >= 2) {
        final price = (value[1] as num?)?.toDouble();
        if (price != null && price > 0) {
          validSpots.add(FlSpot(i.toDouble(), price));
        }
      }
    }
    
    // Ensure we have at least 2 data points for a valid chart
    if (validSpots.length < 2) return [];
    
    return validSpots;
  }

  /// Fetch simple price with request deduplication
  Future<Map<String, dynamic>> fetchSimplePrice(List<String> coinIds) async {
    if (coinIds.isEmpty) return {};

    final sortedIds = List<String>.from(coinIds)..sort();
    final cacheKey = 'simple_${sortedIds.join(',')}';

    final cached = _getFromCache<Map<String, dynamic>>(cacheKey);
    if (cached != null) return cached;

    // If rate limited, return stale or last known data
    if (_isRateLimited) {
      final stale = _getFromCache<Map<String, dynamic>>(cacheKey, ignoreExpiry: true);
      return stale ?? _lastPriceData ?? {};
    }

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
      if (data.isNotEmpty) {
        _setCache(cacheKey, data);
        _lastPriceData = data;
        _consecutiveErrors = 0;
      }
      completer.complete(data);
      return data;
    } catch (e) {
      _consecutiveErrors++;
      final stale = _getFromCache<Map<String, dynamic>>(cacheKey, ignoreExpiry: true);
      final fallback = stale ?? _lastPriceData ?? {};
      completer.complete(fallback);
      return fallback;
    } finally {
      _pendingRequests.remove(cacheKey);
    }
  }

  Future<Map<String, dynamic>> _fetchPriceInternal(List<String> coinIds) async {
    final response = await _retryRequest(
      () => _dio.get(
        'https://api.coingecko.com/api/v3/simple/price?ids=${coinIds.join(',')}&vs_currencies=inr&include_24hr_change=true',
      ),
    );

    if (response.data == null) {
      return {};
    }

    return Map<String, dynamic>.from(response.data);
  }

  /// Retry request with exponential backoff + jitter
  Future<Response<T>> _retryRequest<T>(
    Future<Response<T>> Function() request, {
    int maxRetries = 3,
  }) async {
    int attempt = 0;
    while (true) {
      try {
        final response = await request();
        return response;
      } on DioException catch (e) {
        attempt++;

        // Handle rate limit - set rate limit flag and throw
        if (e.response?.statusCode == 429) {
          _rateLimitedUntil = DateTime.now().add(const Duration(seconds: 60));
          throw CoinGeckoException(
            CoinGeckoErrorType.rateLimit,
            'Rate limited by CoinGecko API',
            statusCode: 429,
          );
        }

        // Don't retry on client errors (4xx except 429)
        if (e.response?.statusCode != null &&
            e.response!.statusCode! >= 400 &&
            e.response!.statusCode! < 500) {
          throw CoinGeckoException(
            CoinGeckoErrorType.notFound,
            e.message ?? 'Client error',
            statusCode: e.response?.statusCode,
          );
        }

        if (attempt >= maxRetries) {
          if (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout ||
              e.type == DioExceptionType.connectionError) {
            throw CoinGeckoException(
              CoinGeckoErrorType.network,
              'Network error: ${e.message}',
            );
          }
          throw CoinGeckoException(
            CoinGeckoErrorType.serverError,
            'Server error after $maxRetries attempts',
            statusCode: e.response?.statusCode,
          );
        }

        // Exponential backoff with jitter (100-300ms base)
        final baseDelay = 150 * (1 << attempt); // 300, 600, 1200ms
        final jitter = _random.nextInt(100); // 0-99ms jitter
        await Future.delayed(Duration(milliseconds: baseDelay + jitter));
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
        'bitcoin',
        'ethereum',
        'tether',
        'binancecoin',
        'solana',
        'ripple',
        'cardano',
        'dogecoin',
        'matic-network',
      ]),
    ]);
  }

  // Cache helpers
  T? _getFromCache<T>(String key, {bool ignoreExpiry = false}) {
    final entry = _cache[key];
    if (entry == null) return null;
    
    // Check stale TTL for stale-while-revalidate
    if (!ignoreExpiry) {
      if (DateTime.now().isAfter(entry.expiresAt)) {
        // Check if still within stale window
        if (DateTime.now().isAfter(entry.staleAt)) {
          return null;
        }
        // Return stale data but it's marked as expired
      }
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
      staleAt: DateTime.now().add(_staleTtl),
    );
  }

  /// Clear all cache (useful for force refresh)
  void clearCache() {
    _cache.clear();
    _lastChartData.clear();
  }

  /// Get chart data from market sparkline (fallback for chart API failures)
  List<FlSpot> getSparklineAsChart(CoinModel coin) {
    if (coin.sparkline7d.isEmpty) return [];
    return coin.sparkline7d
        .asMap()
        .entries
        .where((e) => e.value > 0)
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();
  }
  
  /// Find coin by ID from last fetched market data
  CoinModel? getCoinFromCache(String coinId) {
    return _lastMarketData?.firstWhere(
      (c) => c.id == coinId,
      orElse: () => CoinModel(
        id: coinId,
        symbol: '',
        name: '',
        imageUrl: '',
        currentPrice: 0,
        priceChange24h: 0,
        marketCap: 0,
      ),
    );
  }
  
  /// Check if service has cached data available
  bool get hasCachedData => _lastMarketData != null && _lastMarketData!.isNotEmpty;
  
  /// Get status for debugging
  Map<String, dynamic> get debugStatus => {
    'isRateLimited': _isRateLimited,
    'rateLimitedUntil': _rateLimitedUntil?.toIso8601String(),
    'consecutiveErrors': _consecutiveErrors,
    'cacheSize': _cache.length,
    'hasMarketData': _lastMarketData != null,
    'marketDataCount': _lastMarketData?.length ?? 0,
    'hasPriceData': _lastPriceData != null,
    'chartDataCount': _lastChartData.length,
  };
}

class _CacheEntry {
  final dynamic data;
  final DateTime expiresAt;
  final DateTime staleAt;

  _CacheEntry({
    required this.data,
    required this.expiresAt,
    required this.staleAt,
  });
}
