import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/shimmer_loader.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/crypto_mini_card.dart';
import '../../../shared/widgets/transaction_tile.dart';
import '../../../shared/widgets/coin_list_tile.dart';
import '../bloc/dashboard_bloc.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'KryptoKart',
          style: AppTextStyles.title.copyWith(color: AppColors.accent),
        ),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined, color: Colors.white),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No new notifications'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
        centerTitle: false,
      ),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoading) return _shimmer();
          if (state is DashboardError)
            return KkErrorWidget(
              message: state.message,
              onRetry: () => context.read<DashboardBloc>().add(LoadDashboard()),
            );
          if (state is DashboardLoaded) return _content(context, state);
          return const SizedBox();
        },
      ),
    );
  }

  Widget _shimmer() => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        ShimmerLoader.card(height: 160),
        const SizedBox(height: 16),
        ShimmerLoader.card(height: 80),
        const SizedBox(height: 16),
        ShimmerLoader.list(count: 3),
      ],
    ),
  );

  Widget _content(BuildContext context, DashboardLoaded state) {
    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: () async => context.read<DashboardBloc>().add(LoadDashboard()),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _portfolio(
              state,
            ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.05),
            const SizedBox(height: 20),
            _quickActions(context).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 24),
            _liveRates(context, state).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 24),
            _chart(state).animate().fadeIn(delay: 400.ms),
            const SizedBox(height: 24),
            _topAssets(context, state).animate().fadeIn(delay: 500.ms),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _portfolio(DashboardLoaded s) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Stack(
        children: [
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accent.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TOTAL PORTFOLIO VALUE', style: AppTextStyles.label),
              const SizedBox(height: 4),
              Text(
                CurrencyFormatter.formatInr(s.user.portfolioValue),
                style: AppTextStyles.number,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.arrow_upward,
                      color: AppColors.green,
                      size: 14,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '+12.4%',
                      style: AppTextStyles.captionMedium.copyWith(
                        color: AppColors.green,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '🛡 Assets secured in cold storage',
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickActions(BuildContext context) {
    Widget card(IconData icon, String label, Color color, VoidCallback onTap) {
      return Expanded(
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: AppTextStyles.captionMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        card(
          Icons.qr_code_scanner_rounded,
          'Scan',
          AppColors.accent,
          () => context.go('/home/scan'),
        ),
        const SizedBox(width: 12),
        card(
          Icons.arrow_upward_rounded,
          'Send',
          AppColors.accentBlue,
          () => context.push('/payment'),
        ),
        const SizedBox(width: 12),
        card(
          Icons.shopping_bag_rounded,
          'Shop',
          AppColors.green,
          () => context.push('/shop'),
        ),
        const SizedBox(width: 12),
        card(
          Icons.star_rounded,
          'Wishlist',
          AppColors.yellow,
          () => context.push('/wishlist'),
        ),
      ],
    );
  }

  Widget _liveRates(BuildContext context, DashboardLoaded s) {
    // Define all coins to display with live prices
    final coinConfigs = [
      {'id': 'bitcoin', 'symbol': 'BTC', 'name': 'Bitcoin'},
      {'id': 'ethereum', 'symbol': 'ETH', 'name': 'Ethereum'},
      {'id': 'tether', 'symbol': 'USDT', 'name': 'Tether'},
      {'id': 'binancecoin', 'symbol': 'BNB', 'name': 'Binance Coin'},
      {'id': 'solana', 'symbol': 'SOL', 'name': 'Solana'},
      {'id': 'ripple', 'symbol': 'XRP', 'name': 'XRP'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Live Market Rates',
                style: AppTextStyles.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'LIVE',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.accent,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...coinConfigs.map((coin) {
          final data = s.livePrices?[coin['id']];
          if (data != null) {
            return _cryptoMiniCardReal(
              coin['id']!,
              coin['symbol']!,
              coin['name']!,
              data,
              context,
            );
          }
          return const SizedBox.shrink();
        }),
      ],
    );
  }

  Widget _cryptoMiniCardReal(
    String coinId,
    String symbol,
    String name,
    Map<String, dynamic> data,
    BuildContext context,
  ) {
    final inrPrice = (data['inr'] as num?)?.toDouble() ?? 0.0;
    final change24h = (data['inr_24h_change'] as num?)?.toDouble() ?? 0.0;
    final isPositive = change24h >= 0;

    return GestureDetector(
      onTap: () => context.push('/coin/$coinId'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.only(left: 14, top: 14, bottom: 14, right: 8),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            // Coin icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  symbol,
                  style: AppTextStyles.captionMedium.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Name and symbol
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$symbol/INR',
                    style: AppTextStyles.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '₹${_formatInrCompact(inrPrice)}',
                    style: AppTextStyles.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Change percentage
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (isPositive ? AppColors.green : AppColors.red)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Text(
                '${isPositive ? '+' : ''}${change24h.toStringAsFixed(2)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isPositive ? AppColors.green : AppColors.red,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatInrCompact(double value) {
    if (value >= 10000000) return '${(value / 10000000).toStringAsFixed(2)}Cr';
    if (value >= 100000) return '${(value / 100000).toStringAsFixed(2)}L';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(2)}K';
    return value.toStringAsFixed(2);
  }

  Widget _chart(DashboardLoaded s) {
    // Calculate total portfolio value from live data
    double totalValue = 0;
    List<FlSpot> portfolioSpots = [];

    if (s.livePrices != null && s.livePrices!.isNotEmpty) {
      final bitcoinPrice =
          (s.livePrices!['bitcoin']?['inr'] as num?)?.toDouble() ?? 0;
      final ethereumPrice =
          (s.livePrices!['ethereum']?['inr'] as num?)?.toDouble() ?? 0;
      final tetherPrice =
          (s.livePrices!['tether']?['inr'] as num?)?.toDouble() ?? 0;

      // Simulated portfolio holdings (you can replace with real data)
      const bitcoinHolding = 0.01; // 0.01 BTC
      const ethereumHolding = 0.5; // 0.5 ETH
      const tetherHolding = 1000; // 1000 USDT

      totalValue =
          (bitcoinPrice * bitcoinHolding) +
          (ethereumPrice * ethereumHolding) +
          (tetherPrice * tetherHolding);

      // Generate realistic portfolio growth over 30 days
      final baseValue = totalValue * 0.85; // Start from 85% of current value
      portfolioSpots = List.generate(30, (i) {
        final progress = i / 29.0;
        final growth = baseValue + (totalValue - baseValue) * progress;
        final variance =
            growth *
            0.05 *
            (0.5 - (i % 7) / 14.0); // Add some realistic variance
        return FlSpot(i.toDouble(), growth + variance);
      });
    } else {
      // Fallback spots if no live data
      totalValue = 750000;
      portfolioSpots = List.generate(30, (i) {
        return FlSpot(
          i.toDouble(),
          640000.0 + (i * 3800.0) + (i % 5 == 0 ? -8000 : 5000),
        );
      });
    }

    final isPositive =
        portfolioSpots.isNotEmpty &&
        portfolioSpots.last.y > portfolioSpots.first.y;
    final chartColor = isPositive ? AppColors.green : AppColors.red;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Portfolio Analytics',
                  style: AppTextStyles.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  'MONTHLY',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.accent,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          Text('Past 30 days growth', style: AppTextStyles.caption),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: const FlTitlesData(show: false),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (spot) => AppColors.surface2,
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: portfolioSpots,
                    isCurved: true,
                    color: chartColor,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          chartColor.withValues(alpha: 0.3),
                          chartColor.withValues(alpha: 0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              duration: const Duration(milliseconds: 400),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'PROFIT',
                      style: AppTextStyles.caption.copyWith(fontSize: 10),
                    ),
                    const SizedBox(height: 2),
                    Builder(
                      builder: (context) {
                        final profit = portfolioSpots.isNotEmpty
                            ? portfolioSpots.last.y - portfolioSpots.first.y
                            : 0.0;
                        return Text(
                          '${profit >= 0 ? '+' : ''}₹${_formatNumber(profit.abs())}',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: profit >= 0
                                ? AppColors.green
                                : AppColors.red,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        );
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'HIGH',
                      style: AppTextStyles.caption.copyWith(fontSize: 10),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₹${_formatNumber(portfolioSpots.isNotEmpty ? portfolioSpots.map((s) => s.y).reduce((a, b) => a > b ? a : b) : 0)}',
                      style: AppTextStyles.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'LOW',
                      style: AppTextStyles.caption.copyWith(fontSize: 10),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₹${_formatNumber(portfolioSpots.isNotEmpty ? portfolioSpots.map((s) => s.y).reduce((a, b) => a < b ? a : b) : 0)}',
                      style: AppTextStyles.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _topAssets(BuildContext context, DashboardLoaded s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Top Assets',
                style: AppTextStyles.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            GestureDetector(
              onTap: () => context.go('/home/markets'),
              child: Text(
                'VIEW ALL',
                style: AppTextStyles.captionMedium.copyWith(
                  color: AppColors.accent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...s.topCoins
            .take(6)
            .map(
              (c) => CoinListTile(
                coin: c,
                onTap: () => context.push('/coin/${c.id}'),
              ),
            ),
      ],
    );
  }

  Widget _recent(BuildContext context, DashboardLoaded s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Recent Activity',
                style: AppTextStyles.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            GestureDetector(
              onTap: () => context.go('/home/activity'),
              child: Text(
                'VIEW ALL',
                style: AppTextStyles.captionMedium.copyWith(
                  color: AppColors.accent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...s.recentTransactions
            .take(3)
            .map(
              (t) => TransactionTile(
                transaction: t,
                onTap: () => context.push('/transaction/${t.id}'),
              ),
            ),
      ],
    );
  }

  String _formatNumber(double value) {
    if (value >= 100000) {
      return '${(value / 100000).toStringAsFixed(2)}L';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(2)}K';
    }
    return value.toStringAsFixed(0);
  }
}
