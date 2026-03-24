import 'package:go_router/go_router.dart';
import '../../features/billing/presentation/pages/home_page.dart';
import '../../features/product/presentation/pages/product_list_page.dart';
import '../../features/product/presentation/pages/add_product_page.dart';
import '../../features/product/presentation/pages/edit_product_page.dart';
import '../../features/shop/presentation/pages/shop_details_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/billing/presentation/pages/scanner_page.dart';
import '../../features/billing/presentation/pages/checkout_page.dart';
import '../../features/product/domain/entities/product.dart';
import '../../features/payment/presentation/screens/home_screen.dart';
import '../../features/payment/presentation/screens/payment_mode_picker_screen.dart';
import '../../features/payment/presentation/screens/crypto_checkout_screen.dart';
import '../../features/payment/presentation/screens/upi_checkout_screen.dart';
import '../../features/payment/presentation/screens/receipt_screen.dart';
import '../../features/payment/domain/entities/payment_result.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    // ----------------------------------------------------------------
    // KryptoKart payment routes
    // ----------------------------------------------------------------
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/payment/picker',
      name: 'payment-picker',
      builder: (context, state) => const PaymentModePickerScreen(),
    ),
    GoRoute(
      path: '/payment/crypto',
      name: 'payment-crypto',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        final ethAddress = extra['ethAddress'] as String? ?? '';
        final amountInr =
            (extra['amountInr'] as num?)?.toDouble() ?? 0.0;
        return CryptoCheckoutScreen(
          ethAddress: ethAddress,
          amountInr: amountInr,
        );
      },
    ),
    GoRoute(
      path: '/payment/upi',
      name: 'payment-upi',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        final upiId = extra['upiId'] as String? ?? '';
        final amountInr =
            (extra['amountInr'] as num?)?.toDouble() ?? 0.0;
        return UpiCheckoutScreen(
          upiId: upiId,
          amountInr: amountInr,
        );
      },
    ),
    GoRoute(
      path: '/payment/receipt',
      name: 'payment-receipt',
      builder: (context, state) {
        final result = state.extra as PaymentResult;
        return ReceiptScreen(result: result);
      },
    ),
    // ----------------------------------------------------------------
    // Existing billing routes (preserved)
    // ----------------------------------------------------------------
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
      routes: [
        GoRoute(
          path: 'scanner',
          builder: (context, state) => const ScannerPage(),
        ),
        GoRoute(
          path: 'checkout',
          builder: (context, state) => const CheckoutPage(),
        ),
      ],
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
    ),
    GoRoute(
      path: '/products',
      builder: (context, state) => const ProductListPage(),
      routes: [
        GoRoute(
          path: 'add',
          builder: (context, state) => const AddProductPage(),
        ),
        GoRoute(
          path: 'edit/:id',
          builder: (context, state) {
            final product = state.extra as Product?;
            if (product == null) {
              return const ProductListPage();
            }
            return EditProductPage(product: product);
          },
        ),
      ],
    ),
    GoRoute(
      path: '/shop',
      builder: (context, state) => const ShopDetailsPage(),
    ),
  ],
);
