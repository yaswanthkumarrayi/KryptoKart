import 'package:get_it/get_it.dart';
import '../../features/product/data/repositories/product_repository_impl.dart';
import '../../features/product/domain/repositories/product_repository.dart';
import '../../features/product/domain/usecases/product_usecases.dart';
import '../../features/product/presentation/bloc/product_bloc.dart';
import '../../features/shop/data/repositories/shop_repository_impl.dart';
import '../../features/shop/domain/repositories/shop_repository.dart';
import '../../features/shop/domain/usecases/shop_usecases.dart';
import '../../features/shop/presentation/bloc/shop_bloc.dart';
import '../../features/settings/data/repositories/printer_repository_impl.dart';
import '../../features/settings/domain/repositories/printer_repository.dart';
import '../../features/settings/presentation/bloc/printer_bloc.dart';
// Payment feature
import '../../features/payment/data/services/price_oracle_service.dart';
import '../../features/payment/data/services/wallet_service.dart';
import '../../features/payment/data/services/crypto_payment_service.dart';
import '../../features/payment/data/services/upi_payment_service.dart';
import '../../features/payment/domain/usecases/get_live_crypto_price.dart';
import '../../features/payment/domain/usecases/process_crypto_payment.dart';
import '../../features/payment/domain/usecases/process_upi_payment.dart';
import '../../features/payment/presentation/bloc/payment_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // ================================================================
  // Features - Product
  // ================================================================
  sl.registerFactory(
    () => ProductBloc(
      getProductsUseCase: sl(),
      addProductUseCase: sl(),
      updateProductUseCase: sl(),
      deleteProductUseCase: sl(),
    ),
  );

  sl.registerFactory(
    () => ShopBloc(
      getShopUseCase: sl(),
      updateShopUseCase: sl(),
    ),
  );

  sl.registerFactory(
    () => PrinterBloc(
      repository: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetProductsUseCase(sl()));
  sl.registerLazySingleton(() => AddProductUseCase(sl()));
  sl.registerLazySingleton(() => UpdateProductUseCase(sl()));
  sl.registerLazySingleton(() => DeleteProductUseCase(sl()));
  sl.registerLazySingleton(() => GetProductByBarcodeUseCase(sl()));

  // Repository
  sl.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(),
  );

  // ================================================================
  // Features - Shop
  // ================================================================
  sl.registerLazySingleton(() => GetShopUseCase(sl()));
  sl.registerLazySingleton(() => UpdateShopUseCase(sl()));

  sl.registerLazySingleton<ShopRepository>(
    () => ShopRepositoryImpl(),
  );

  // ================================================================
  // Features - Settings / Printer
  // ================================================================
  sl.registerLazySingleton<PrinterRepository>(
    () => PrinterRepositoryImpl(),
  );

  // ================================================================
  // Features - Payment
  // ================================================================
  // Services
  sl.registerLazySingleton(() => PriceOracleService());
  sl.registerLazySingleton(() => WalletService());
  sl.registerLazySingleton(() => CryptoPaymentService(
        priceOracleService: sl(),
        walletService: sl(),
      ));
  sl.registerFactory(() => UpiPaymentService());

  // Use cases
  sl.registerLazySingleton(() => GetLiveCryptoPrice(sl()));
  sl.registerLazySingleton(() => ProcessCryptoPayment(sl()));
  sl.registerLazySingleton(() => ProcessUpiPayment(sl()));

  // BLoC
  sl.registerFactory(
    () => PaymentBloc(
      processCryptoPayment: sl(),
      processUpiPayment: sl(),
      getLiveCryptoPrice: sl(),
      walletService: sl(),
    ),
  );
}
