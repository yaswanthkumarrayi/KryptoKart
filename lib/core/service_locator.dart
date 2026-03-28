import 'package:get_it/get_it.dart';
import '../shared/services/api_service.dart';
import '../shared/services/coingecko_service.dart';
import '../shared/services/connectivity_service.dart';
import '../shared/services/razorpay_payment_service.dart';
import '../shared/services/wallet_service.dart';
import '../shared/services/wishlist_service.dart';
import '../features/auth/bloc/auth_bloc.dart';
import '../features/dashboard/bloc/dashboard_bloc.dart';
import '../features/markets/bloc/markets_bloc.dart';
import '../features/transactions/presentation/transactions_screen.dart';

final sl = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Services (singletons)
  sl.registerLazySingleton<ApiService>(() => ApiService());
  sl.registerLazySingleton<CoinGeckoService>(() => CoinGeckoService());
  sl.registerLazySingleton<ConnectivityService>(() => ConnectivityService());
  sl.registerLazySingleton<RazorpayPaymentService>(
    () => RazorpayPaymentService(),
  );
  sl.registerLazySingleton<WalletService>(() => WalletService());
  sl.registerLazySingleton<WishlistService>(() => WishlistService());

  // Initialize wallet service (restore any saved MetaMask connection)
  await sl<WalletService>().init();
  // Initialize wishlist service
  await sl<WishlistService>().initialize();

  // Auth Bloc (singleton — persists across app)
  sl.registerLazySingleton<AuthBloc>(() => AuthBloc(sl<ApiService>()));

  // Feature Blocs (factories — new instance per route)
  sl.registerFactory<DashboardBloc>(
    () => DashboardBloc(sl<ApiService>(), sl<CoinGeckoService>()),
  );
  sl.registerFactory<MarketsBloc>(
    () => MarketsBloc(
      sl<CoinGeckoService>(),
      sl<ApiService>(),
      sl<WishlistService>(),
    ),
  );
  sl.registerFactory<TransactionsBloc>(
    () => TransactionsBloc(sl<ApiService>()),
  );
}
