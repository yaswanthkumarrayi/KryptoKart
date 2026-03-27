import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../shared/models/coin_model.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/services/coingecko_service.dart';

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

  MarketsLoaded({
    required this.coins,
    required this.filteredCoins,
    required this.watchlist,
    this.chartData = const [],
    this.featuredCoinId,
    this.searchQuery = '',
  });

  @override
  List<Object?> get props => [coins, filteredCoins, watchlist, chartData, featuredCoinId, searchQuery];

  MarketsLoaded copyWith({
    List<CoinModel>? coins,
    List<CoinModel>? filteredCoins,
    List<String>? watchlist,
    List<FlSpot>? chartData,
    String? featuredCoinId,
    String? searchQuery,
  }) {
    return MarketsLoaded(
      coins: coins ?? this.coins,
      filteredCoins: filteredCoins ?? this.filteredCoins,
      watchlist: watchlist ?? this.watchlist,
      chartData: chartData ?? this.chartData,
      featuredCoinId: featuredCoinId ?? this.featuredCoinId,
      searchQuery: searchQuery ?? this.searchQuery,
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
  Timer? _refreshTimer;

  MarketsBloc(this._coinGeckoService, this._apiService) : super(MarketsInitial()) {
    on<LoadMarkets>(_onLoad);
    on<RefreshMarkets>(_onRefresh);
    on<SearchCoins>(_onSearch);
    on<ToggleWatchlist>(_onToggleWatchlist);
    on<LoadCoinChart>(_onLoadChart);
  }

  Future<void> _onLoad(LoadMarkets event, Emitter<MarketsState> emit) async {
    emit(MarketsLoading());
    try {
      final coins = await _coinGeckoService.fetchMarkets(perPage: 10);
      final wlData = await _apiService.getWatchlist();
      final chartData = await _coinGeckoService.fetchMarketChart('bitcoin', days: 7);
      final watchlist = List<String>.from(wlData['coinIds'] ?? []);

      emit(MarketsLoaded(
        coins: coins,
        filteredCoins: coins,
        watchlist: watchlist,
        chartData: chartData,
        featuredCoinId: 'bitcoin',
      ));

      _refreshTimer?.cancel();
      _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
        add(RefreshMarkets());
      });
    } catch (e) {
      emit(MarketsError('Failed to load markets: ${e.toString()}'));
    }
  }

  Future<void> _onRefresh(RefreshMarkets event, Emitter<MarketsState> emit) async {
    if (state is! MarketsLoaded) return;
    final current = state as MarketsLoaded;
    try {
      final coins = await _coinGeckoService.fetchMarkets(perPage: 10);
      final filtered = current.searchQuery.isEmpty
          ? coins
          : coins.where((c) =>
              c.name.toLowerCase().contains(current.searchQuery.toLowerCase()) ||
              c.symbol.toLowerCase().contains(current.searchQuery.toLowerCase())).toList();
      emit(current.copyWith(coins: coins, filteredCoins: filtered));
    } catch (_) {}
  }

  void _onSearch(SearchCoins event, Emitter<MarketsState> emit) {
    if (state is! MarketsLoaded) return;
    final current = state as MarketsLoaded;
    final query = event.query.toLowerCase();
    final filtered = query.isEmpty
        ? current.coins
        : current.coins.where((c) =>
            c.name.toLowerCase().contains(query) ||
            c.symbol.toLowerCase().contains(query)).toList();
    emit(current.copyWith(filteredCoins: filtered, searchQuery: event.query));
  }

  Future<void> _onToggleWatchlist(ToggleWatchlist event, Emitter<MarketsState> emit) async {
    if (state is! MarketsLoaded) return;
    final current = state as MarketsLoaded;
    try {
      final result = await _apiService.toggleWatchlist(event.coinId);
      emit(current.copyWith(watchlist: List<String>.from(result['coinIds'])));
    } catch (_) {}
  }

  Future<void> _onLoadChart(LoadCoinChart event, Emitter<MarketsState> emit) async {
    if (state is! MarketsLoaded) return;
    final current = state as MarketsLoaded;
    try {
      final chartData = await _coinGeckoService.fetchMarketChart(event.coinId, days: event.days);
      emit(current.copyWith(chartData: chartData, featuredCoinId: event.coinId));
    } catch (_) {}
  }

  @override
  Future<void> close() {
    _refreshTimer?.cancel();
    return super.close();
  }
}
