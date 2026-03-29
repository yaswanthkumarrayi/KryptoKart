import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../shared/models/coin_model.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/services/coingecko_service.dart';
import '../../../shared/services/wishlist_service.dart';

// Events
abstract class MarketsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadMarkets extends MarketsEvent {}

class RefreshMarkets extends MarketsEvent {}

class SearchCoins extends MarketsEvent {
  final String query;
  SearchCoins(this.query);
  @override
  List<Object> get props => [query];
}

class ToggleWatchlist extends MarketsEvent {
  final String coinId;
  ToggleWatchlist(this.coinId);
  @override
  List<Object> get props => [coinId];
}

class LoadCoinChart extends MarketsEvent {
  final String coinId;
  final int days;
  LoadCoinChart(this.coinId, {this.days = 7});
  @override
  List<Object> get props => [coinId, days];
}

// States
abstract class MarketsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class MarketsInitial extends MarketsState {}

class MarketsLoading extends MarketsState {}

class MarketsLoaded extends MarketsState {
  final List<CoinModel> coins;
  final List<CoinModel> filteredCoins;
  final List<String> watchlist;
  final List<FlSpot> chartData;
  final String? featuredCoinId;
  final String searchQuery;
  final bool isRefreshing;

  MarketsLoaded({
    required this.coins,
    required this.filteredCoins,
    required this.watchlist,
    this.chartData = const [],
    this.featuredCoinId,
    this.searchQuery = '',
    this.isRefreshing = false,
  });

  @override
  List<Object?> get props => [
    coins,
    filteredCoins,
    watchlist,
    chartData,
    featuredCoinId,
    searchQuery,
    isRefreshing,
  ];

  MarketsLoaded copyWith({
    List<CoinModel>? coins,
    List<CoinModel>? filteredCoins,
    List<String>? watchlist,
    List<FlSpot>? chartData,
    String? featuredCoinId,
    String? searchQuery,
    bool? isRefreshing,
  }) {
    return MarketsLoaded(
      coins: coins ?? this.coins,
      filteredCoins: filteredCoins ?? this.filteredCoins,
      watchlist: watchlist ?? this.watchlist,
      chartData: chartData ?? this.chartData,
      featuredCoinId: featuredCoinId ?? this.featuredCoinId,
      searchQuery: searchQuery ?? this.searchQuery,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

class MarketsError extends MarketsState {
  final String message;
  MarketsError(this.message);
  @override
  List<Object> get props => [message];
}

// Bloc
class MarketsBloc extends Bloc<MarketsEvent, MarketsState> {
  final CoinGeckoService _coinGeckoService;
  final ApiService _apiService;
  final WishlistService _wishlistService;
  Timer? _refreshTimer;
  bool _isRefreshing = false;

  MarketsBloc(this._coinGeckoService, this._apiService, this._wishlistService)
    : super(MarketsInitial()) {
    on<LoadMarkets>(_onLoad);
    on<RefreshMarkets>(_onRefresh);
    on<SearchCoins>(_onSearch);
    on<ToggleWatchlist>(_onToggleWatchlist);
    on<LoadCoinChart>(_onLoadChart);
  }

  Future<void> _onLoad(LoadMarkets event, Emitter<MarketsState> emit) async {
    emit(MarketsLoading());

    List<CoinModel> coins = [];
    List<String> watchlist = [];
    List<FlSpot> chartData = [];

    // Fetch coins from CoinGecko (public API)
    try {
      coins = await _coinGeckoService.fetchMarkets(perPage: 30);
    } catch (e) {
      coins = [];
    }

    // Load local wishlist first (instant)
    try {
      watchlist = await _wishlistService.getWishlist();
    } catch (e) {
      watchlist = [];
    }

    // Try to sync with backend wishlist
    try {
      final wlData = await _apiService.getWatchlist();
      final coinIds = wlData['coinIds'];
      if (coinIds != null && coinIds is List) {
        final backendList = List<String>.from(coinIds);
        await _wishlistService.syncWithBackend(backendList);
        watchlist = await _wishlistService.getWishlist();
      }
    } catch (e) {
      // Backend unavailable - use local wishlist
    }

    // Fetch chart data for featured coin (with sparkline fallback)
    try {
      chartData = await _coinGeckoService.fetchMarketChart('bitcoin', days: 7);
    } catch (e) {
      chartData = [];
    }

    // If chart API failed, use sparkline from the coin data
    if (chartData.isEmpty && coins.isNotEmpty) {
      final bitcoin = coins.firstWhere(
        (c) => c.id == 'bitcoin',
        orElse: () => coins.first,
      );
      if (bitcoin.sparkline7d.isNotEmpty) {
        chartData = bitcoin.sparkline7d
            .asMap()
            .entries
            .where((e) => e.value > 0)
            .map((e) => FlSpot(e.key.toDouble(), e.value))
            .toList();
      }
    }

    // Emit loaded state even if some data is missing
    emit(
      MarketsLoaded(
        coins: coins,
        filteredCoins: coins,
        watchlist: watchlist,
        chartData: chartData,
        featuredCoinId: 'bitcoin',
      ),
    );

    // Start refresh timer with guard against concurrent refreshes
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 45), (_) {
      if (!_isRefreshing) {
        add(RefreshMarkets());
      }
    });
  }

  Future<void> _onRefresh(
    RefreshMarkets event,
    Emitter<MarketsState> emit,
  ) async {
    if (state is! MarketsLoaded) return;
    if (_isRefreshing) return; // Prevent concurrent refreshes

    final current = state as MarketsLoaded;
    _isRefreshing = true;

    try {
      final coins = await _coinGeckoService.fetchMarkets(perPage: 30);

      // Only update if we got valid data
      if (coins.isNotEmpty) {
        final filtered = current.searchQuery.isEmpty
            ? coins
            : coins
                  .where(
                    (c) =>
                        c.name.toLowerCase().contains(
                          current.searchQuery.toLowerCase(),
                        ) ||
                        c.symbol.toLowerCase().contains(
                          current.searchQuery.toLowerCase(),
                        ),
                  )
                  .toList();
        emit(current.copyWith(coins: coins, filteredCoins: filtered));
      }
    } catch (_) {
      // Keep current data on error
    } finally {
      _isRefreshing = false;
    }
  }

  void _onSearch(SearchCoins event, Emitter<MarketsState> emit) {
    if (state is! MarketsLoaded) return;
    final current = state as MarketsLoaded;
    final query = event.query.toLowerCase();
    final filtered = query.isEmpty
        ? current.coins
        : current.coins
              .where(
                (c) =>
                    c.name.toLowerCase().contains(query) ||
                    c.symbol.toLowerCase().contains(query),
              )
              .toList();
    emit(current.copyWith(filteredCoins: filtered, searchQuery: event.query));
  }

  Future<void> _onToggleWatchlist(
    ToggleWatchlist event,
    Emitter<MarketsState> emit,
  ) async {
    if (state is! MarketsLoaded) return;
    final current = state as MarketsLoaded;

    // Optimistically update UI immediately
    final isCurrentlyWishlisted = current.watchlist.contains(event.coinId);
    final newWatchlist = List<String>.from(current.watchlist);

    if (isCurrentlyWishlisted) {
      newWatchlist.remove(event.coinId);
    } else {
      newWatchlist.add(event.coinId);
    }

    // Update local wishlist and emit state immediately
    await _wishlistService.toggleWishlist(event.coinId);
    emit(current.copyWith(watchlist: newWatchlist));

    // Try to sync with backend (non-blocking)
    try {
      final result = await _apiService.toggleWatchlist(event.coinId);
      final coinIds = result['coinIds'];
      if (coinIds != null && coinIds is List) {
        await _wishlistService.syncWithBackend(List<String>.from(coinIds));
      }
    } catch (_) {
      // Backend sync failed - local state is still correct
    }
  }

  Future<void> _onLoadChart(
    LoadCoinChart event,
    Emitter<MarketsState> emit,
  ) async {
    if (state is! MarketsLoaded) return;
    final current = state as MarketsLoaded;
    
    try {
      var chartData = await _coinGeckoService.fetchMarketChart(
        event.coinId,
        days: event.days,
      );
      
      // If chart API failed, try sparkline fallback
      if (chartData.isEmpty) {
        final coin = current.coins.firstWhere(
          (c) => c.id == event.coinId,
          orElse: () => current.coins.first,
        );
        if (coin.sparkline7d.isNotEmpty) {
          chartData = coin.sparkline7d
              .asMap()
              .entries
              .where((e) => e.value > 0)
              .map((e) => FlSpot(e.key.toDouble(), e.value))
              .toList();
        }
      }
      
      if (chartData.isNotEmpty) {
        emit(
          current.copyWith(chartData: chartData, featuredCoinId: event.coinId),
        );
      }
    } catch (_) {
      // Keep existing chart data on error
    }
  }

  @override
  Future<void> close() {
    _refreshTimer?.cancel();
    return super.close();
  }
}
