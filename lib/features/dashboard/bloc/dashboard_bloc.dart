import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../shared/models/coin_model.dart';
import '../../../shared/models/transaction_model.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/services/coingecko_service.dart';

// Events
abstract class DashboardEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadDashboard extends DashboardEvent {}
class RefreshPrices extends DashboardEvent {}

// States
abstract class DashboardState extends Equatable {
  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}
class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final UserModel user;
  final List<CoinModel> topCoins;
  final List<TransactionModel> recentTransactions;
  final Map<String, dynamic>? livePrices;

  DashboardLoaded({
    required this.user,
    required this.topCoins,
    required this.recentTransactions,
    this.livePrices,
  });

  @override
  List<Object?> get props => [user, topCoins, recentTransactions, livePrices];

  DashboardLoaded copyWith({
    UserModel? user,
    List<CoinModel>? topCoins,
    List<TransactionModel>? recentTransactions,
    Map<String, dynamic>? livePrices,
  }) {
    return DashboardLoaded(
      user: user ?? this.user,
      topCoins: topCoins ?? this.topCoins,
      recentTransactions: recentTransactions ?? this.recentTransactions,
      livePrices: livePrices ?? this.livePrices,
    );
  }
}

class DashboardError extends DashboardState {
  final String message;
  DashboardError(this.message);
  @override
  List<Object> get props => [message];
}

// Bloc
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final ApiService _apiService;
  final CoinGeckoService _coinGeckoService;
  Timer? _priceTimer;

  DashboardBloc(this._apiService, this._coinGeckoService) : super(DashboardInitial()) {
    on<LoadDashboard>(_onLoad);
    on<RefreshPrices>(_onRefreshPrices);
  }

  Future<void> _onLoad(LoadDashboard event, Emitter<DashboardState> emit) async {
    emit(DashboardLoading());
    try {
      final profileFuture = _apiService.getProfile();
      final coinsFuture = _coinGeckoService.fetchMarkets(perPage: 5);
      final txnFuture = _apiService.getTransactions(limit: 5);
      final pricesFuture = _coinGeckoService.fetchSimplePrice(['bitcoin', 'ethereum', 'solana', 'binancecoin', 'ripple']);

      final profileData = await profileFuture;
      final coins = await coinsFuture;
      final txnData = await txnFuture;
      final livePrices = await pricesFuture;

      final user = UserModel.fromJson(profileData['user']);

      final transactions = (txnData['transactions'] as List)
          .map((json) => TransactionModel.fromJson(json))
          .toList();

      emit(DashboardLoaded(
        user: user,
        topCoins: coins,
        recentTransactions: transactions,
        livePrices: livePrices,
      ));

      _priceTimer?.cancel();
      _priceTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        add(RefreshPrices());
      });
    } catch (e) {
      emit(DashboardError('Failed to load dashboard: ${e.toString()}'));
    }
  }

  Future<void> _onRefreshPrices(RefreshPrices event, Emitter<DashboardState> emit) async {
    if (state is! DashboardLoaded) return;
    final current = state as DashboardLoaded;
    try {
      final coins = await _coinGeckoService.fetchMarkets(perPage: 5);
      final prices = await _coinGeckoService.fetchSimplePrice(['bitcoin', 'ethereum', 'solana', 'binancecoin', 'ripple']);
      emit(current.copyWith(
        topCoins: coins,
        livePrices: prices,
      ));
    } catch (_) {}
  }

  @override
  Future<void> close() {
    _priceTimer?.cancel();
    return super.close();
  }
}
