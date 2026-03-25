import 'package:go_router/go_router.dart';
import '../../features/dashboard/presentation/pages/home_dashboard.dart';
import '../../features/billing/presentation/pages/home_page.dart';
import '../../features/billing/presentation/pages/checkout_page.dart';
import '../../features/billing/presentation/pages/scanner_page.dart';
import '../../features/product/domain/entities/product.dart';
import '../../features/product/presentation/pages/add_product_page.dart';
import '../../features/product/presentation/pages/edit_product_page.dart';
import '../../features/product/presentation/pages/product_list_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/shop/presentation/pages/shop_details_page.dart';
import '../../features/store/presentation/pages/store_selection_page.dart';
import '../../features/payments/presentation/pages/unified_payment_page.dart';
import '../../features/payments/presentation/pages/intelligent_qr_scan_page.dart';
import '../../features/payments/presentation/screens/payment_mode_picker_screen.dart';
import '../../features/payments/presentation/screens/upi_checkout_screen.dart';
import '../../features/payments/presentation/screens/crypto_checkout_screen.dart';
import '../../features/payments/presentation/screens/receipt_screen.dart';
import '../../features/payments/domain/entities/payment_result.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeDashboard()),
    GoRoute(
      path: '/scan',
      builder: (context, state) => const IntelligentQrScanPage(),
    ),
    GoRoute(
      path: '/store',
      builder: (context, state) => const StoreSelectionPage(),
    ),
    GoRoute(path: '/shopping', builder: (context, state) => const HomePage()),
    GoRoute(
      path: '/payment',
      builder: (context, state) {
        final amount = double.tryParse(
          state.uri.queryParameters['amount']?.trim() ?? '',
        );
        return UnifiedPaymentPage(
          initialType: state.uri.queryParameters['type'],
          initialAmount: amount,
          initialUpiId: state.uri.queryParameters['upiId'],
          initialPayeeName: state.uri.queryParameters['payeeName'],
          initialWalletAddress: state.uri.queryParameters['wallet'],
          initialRawData: state.uri.queryParameters['raw'],
        );
      },
    ),
    GoRoute(
      path: '/payment/picker',
      builder: (context, state) => const PaymentModePickerScreen(),
    ),
    GoRoute(
      path: '/payment/upi',
      builder: (context, state) {
        final extra = state.extra;
        if (extra is Map<String, dynamic>) {
          return UpiCheckoutScreen(
            upiId: extra['upiId'] as String? ?? '',
            amountInr: (extra['amountInr'] as num?)?.toDouble() ?? 0.0,
          );
        }
        final amount = (extra is double) ? extra : 0.0;
        return UpiCheckoutScreen(upiId: '', amountInr: amount);
      },
    ),
    GoRoute(
      path: '/payment/crypto',
      builder: (context, state) {
        final extra = state.extra;
        if (extra is Map<String, dynamic>) {
          return CryptoCheckoutScreen(
            ethAddress: extra['ethAddress'] as String? ?? '',
            amountInr: (extra['amountInr'] as num?)?.toDouble() ?? 0.0,
          );
        }
        final amount = (extra is double) ? extra : 0.0;
        return CryptoCheckoutScreen(ethAddress: '', amountInr: amount);
      },
    ),
    GoRoute(
      path: '/payment/receipt',
      builder: (context, state) {
        final result = state.extra as PaymentResult;
        return ReceiptScreen(result: result);
      },
    ),
    GoRoute(
      path: '/checkout',
      builder: (context, state) => const CheckoutPage(),
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
    GoRoute(path: '/scanner', builder: (context, state) => const ScannerPage()),
  ],
);
