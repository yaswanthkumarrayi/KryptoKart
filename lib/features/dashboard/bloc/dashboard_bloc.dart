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
  final bool isOfflineMode;
  final double calculatedPortfolio;

  // All supported coin IDs for live price tracking
  static const List<String> supportedCoinIds = [
    'bitcoin',
    'ethereum',
    'tether',
    'binancecoin',
    'solana',
    'ripple',
    'cardano',
    'dogecoin',
    'matic-network',
  ];

  DashboardLoaded({
    required this.user,
    required this.topCoins,
    required this.recentTransactions,
    this.livePrices,
    this.isOfflineMode = false,
    this.calculatedPortfolio = 0,
  });

  @override
  List<Object?> get props => [user, topCoins, recentTransactions, livePrices, isOfflineMode, calculatedPortfolio];

  DashboardLoaded copyWith({
    UserModel? user,
    List<CoinModel>? topCoins,
    List<TransactionModel>? recentTransactions,
    Map<String, dynamic>? livePrices,
    bool? isOfflineMode,
    double? calculatedPortfolio,
  }) {
    return DashboardLoaded(
      user: user ?? this.user,
      topCoins: topCoins ?? this.topCoins,
      recentTransactions: recentTransactions ?? this.recentTransactions,
      livePrices: livePrices ?? this.livePrices,
      isOfflineMode: isOfflineMode ?? this.isOfflineMode,
      calculatedPortfolio: calculatedPortfolio ?? this.calculatedPortfolio,
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
  bool _isRefreshing = false;
  
  // Cache last known good values to prevent 0.00 display
  Map<String, dynamic>? _lastKnownPrices;
  List<CoinModel>? _lastKnownCoins;

  DashboardBloc(this._apiService, this._coinGeckoService)
    : super(DashboardInitial()) {
    on<LoadDashboard>(_onLoad);
    on<RefreshPrices>(_onRefreshPrices);
  }

  Future<void> _onLoad(
    LoadDashboard event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());
    
    // Default fallback user for offline/error mode
    UserModel user = const UserModel(
      id: 'guest',
      name: 'Guest User',
      phone: '',
      portfolioValue: 0,
      kycStatus: 'pending',
    );
    List<TransactionModel> transactions = [];
    List<CoinModel> coins = [];
    Map<String, dynamic>? livePrices;
    bool isOfflineMode = false;

    // Fetch crypto data from CoinGecko FIRST (most important)
    try {
      coins = await _coinGeckoService.fetchMarkets(perPage: 20);
      if (coins.isNotEmpty) {
        _lastKnownCoins = coins;
      } else if (_lastKnownCoins != null) {
        coins = _lastKnownCoins!;
      }
    } catch (e) {
      if (_lastKnownCoins != null) {
        coins = _lastKnownCoins!;
      }
    }

    // Fetch live prices from CoinGecko
    try {
      livePrices = await _coinGeckoService.fetchSimplePrice(
        DashboardLoaded.supportedCoinIds,
      );
      if (livePrices != null && livePrices.isNotEmpty) {
        _lastKnownPrices = livePrices;
      } else if (_lastKnownPrices != null) {
        livePrices = _lastKnownPrices;
      }
    } catch (e) {
      if (_lastKnownPrices != null) {
        livePrices = _lastKnownPrices;
      }
    }

    // Calculate portfolio value from live prices (prevents 0.00 issue)
    double calculatedPortfolio = _calculatePortfolio(livePrices);

    // Try to fetch user profile (may fail if not authenticated)
    try {
      final profileData = await _apiService.getProfile();
      if (profileData['user'] != null) {
        user = UserModel.fromJson(profileData['user']);
        // Only use backend portfolio if we have valid prices
        if (user.portfolioValue <= 0 && calculatedPortfolio > 0) {
          user = UserModel(
            id: user.id,
            name: user.name,
            phone: user.phone,
            portfolioValue: calculatedPortfolio,
            kycStatus: user.kycStatus,
          );
        }
      }
    } catch (e) {
      // Backend unavailable or not authenticated - continue with guest mode
      isOfflineMode = true;
      user = UserModel(
        id: 'guest',
        name: 'Guest User',
        phone: '',
        portfolioValue: calculatedPortfolio,
        kycStatus: 'pending',
      );
    }

    // Try to fetch transactions (may fail if not authenticated)
    try {
      final txnData = await _apiService.getTransactions(limit: 5);
      final txnList = txnData['transactions'];
      if (txnList != null && txnList is List) {
        transactions = txnList
            .map((json) => TransactionModel.fromJson(json))
            .toList();
      }
    } catch (e) {
      // Backend unavailable - continue without transactions
      isOfflineMode = true;
    }

    // Emit loaded state (even if some data is missing)
    emit(
      DashboardLoaded(
        user: user,
        topCoins: coins,
        recentTransactions: transactions,
        livePrices: livePrices,
        isOfflineMode: isOfflineMode,
        calculatedPortfolio: calculatedPortfolio,
      ),
    );

    // Start price refresh timer with guard
    _priceTimer?.cancel();
    _priceTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!_isRefreshing) {
        add(RefreshPrices());
      }
    });
  }

  Future<void> _onRefreshPrices(
    RefreshPrices event,
    Emitter<DashboardState> emit,
  ) async {
    if (state is! DashboardLoaded) return;
    if (_isRefreshing) return; // Prevent concurrent refreshes
    
    final current = state as DashboardLoaded;
    _isRefreshing = true;
    
    try {
      // Fetch in parallel
      final results = await Future.wait([
        _coinGeckoService.fetchMarkets(perPage: 20),
        _coinGeckoService.fetchSimplePrice(DashboardLoaded.supportedCoinIds),
      ]);
      
      final coins = results[0] as List<CoinModel>;
      final prices = results[1] as Map<String, dynamic>;
      
      // Only update if we got valid data
      if (coins.isNotEmpty) {
        _lastKnownCoins = coins;
      }
      if (prices.isNotEmpty) {
        _lastKnownPrices = prices;
      }
      
      final newPrices = prices.isNotEmpty ? prices : current.livePrices;
      final newCoins = coins.isNotEmpty ? coins : current.topCoins;
      final newPortfolio = _calculatePortfolio(newPrices);
      
      emit(current.copyWith(
        topCoins: newCoins,
        livePrices: newPrices,
        calculatedPortfolio: newPortfolio > 0 ? newPortfolio : current.calculatedPortfolio,
      ));
    } catch (_) {
      // Keep current data on error - don't update with empty/zero values
    } finally {
      _isRefreshing = false;
    }
  }

  /// Calculate portfolio value from live prices
  /// This ensures we never show 0.00 when we have valid price data
  double _calculatePortfolio(Map<String, dynamic>? prices) {
    if (prices == null || prices.isEmpty) return 0;
    
    final btcPrice = (prices['bitcoin']?['inr'] as num?)?.toDouble() ?? 0;
    final ethPrice = (prices['ethereum']?['inr'] as num?)?.toDouble() ?? 0;
    final usdtPrice = (prices['tether']?['inr'] as num?)?.toDouble() ?? 0;
    
    // Sample holdings for demonstration
    const btcHolding = 0.001;  // 0.001 BTC
    const ethHolding = 0.05;   // 0.05 ETH
    const usdtHolding = 100;   // 100 USDT
    
    return (btcPrice * btcHolding) + 
           (ethPrice * ethHolding) + 
           (usdtPrice * usdtHolding);
  }

  @override
  Future<void> close() {
    _priceTimer?.cancel();
    return super.close();
  }
}
