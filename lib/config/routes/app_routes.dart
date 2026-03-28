import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/service_locator.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/onboarding/presentation/kyc_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/dashboard/bloc/dashboard_bloc.dart';
import '../../features/scanner/presentation/scanner_screen.dart';
import '../../features/markets/presentation/markets_screen.dart';
import '../../features/markets/presentation/coin_detail_screen.dart';
import '../../features/markets/bloc/markets_bloc.dart';
import '../../features/payments/presentation/payment_screen.dart';
import '../../features/payments/presentation/receipt_screen.dart';
import '../../features/shop/presentation/shop_screen.dart';
import '../../features/shop/presentation/cart_screen.dart';
import '../../features/billing/presentation/checkout_screen.dart';
import '../../features/transactions/presentation/transactions_screen.dart';
import '../../features/transactions/presentation/transaction_detail_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/wishlist_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../shared/models/transaction_model.dart';
import '../../shared/widgets/bottom_nav_bar.dart';

class AppRoutes {
  static final rootNavigatorKey = GlobalKey<NavigatorState>();
  static final shellNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    routes: [
      // Splash
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),

      // Auth routes
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(path: '/kyc', builder: (context, state) => const KycScreen()),

      // Shell route for bottom nav
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) {
          return _ShellScreen(child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => BlocProvider(
              create: (_) => sl<DashboardBloc>()..add(LoadDashboard()),
              child: const DashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/home/shop',
            builder: (context, state) => const ShopScreen(),
          ),
          GoRoute(
            path: '/home/scan',
            builder: (context, state) => const ScannerScreen(),
          ),
          GoRoute(
            path: '/home/activity',
            builder: (context, state) => BlocProvider(
              create: (_) => sl<TransactionsBloc>()..add(LoadTransactions()),
              child: const TransactionsScreen(),
            ),
          ),
          GoRoute(
            path: '/home/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/home/markets',
            builder: (context, state) => BlocProvider(
              create: (_) => sl<MarketsBloc>()..add(LoadMarkets()),
              child: const MarketsScreen(),
            ),
          ),
        ],
      ),

      // Standalone routes
      GoRoute(
        path: '/payment',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>?;
          return PaymentScreen(paymentData: data);
        },
      ),
      GoRoute(
        path: '/receipt',
        builder: (context, state) {
          final txn = state.extra as TransactionModel;
          return ReceiptScreen(transaction: txn);
        },
      ),
      GoRoute(
        path: '/coin/:id',
        builder: (context, state) {
          return CoinDetailScreen(
            coinId: state.pathParameters['id'] ?? 'bitcoin',
          );
        },
      ),
      GoRoute(
        path: '/shop',
        builder: (context, state) => const ShopScreen(),
      ),
      GoRoute(path: '/cart', builder: (context, state) => const CartScreen()),
      GoRoute(
        path: '/checkout',
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/transaction/:id',
        builder: (context, state) {
          return TransactionDetailScreen(
            transactionId: state.pathParameters['id'] ?? '',
          );
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/wishlist',
        builder: (context, state) => const WishlistScreen(),
      ),
    ],
  );
}

class _ShellScreen extends StatefulWidget {
  final Widget child;
  const _ShellScreen({required this.child});

  @override
  State<_ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<_ShellScreen> {
  int _currentIndex = 0;

  static const _routes = [
    '/home',
    '/home/shop',
    '/home/scan',
    '/home/activity',
    '/home/profile',
  ];

  void _onNavTap(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    context.go(_routes[index]);
  }

  @override
  void didUpdateWidget(covariant _ShellScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final location = GoRouterState.of(context).matchedLocation;
    for (int i = 0; i < _routes.length; i++) {
      if (location == _routes[i]) {
        if (_currentIndex != i) {
          setState(() => _currentIndex = i);
        }
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }
}
