import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/service_locator.dart';
import '../../../core/theme/kk_theme_context.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/shimmer_loader.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/coin_list_tile.dart';
import '../bloc/dashboard_bloc.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'KryptoKart',
          style: context.txt.title.copyWith(color: p.accent),
        ),
        actions: [
          IconButton(
            tooltip: Theme.of(context).brightness == Brightness.dark
                ? 'Light mode'
                : 'Dark mode',
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
              color: p.accent,
            ),
            onPressed: () => sl<ThemeController>().toggle(),
          ),
        ],
        centerTitle: false,
      ),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoading) return _shimmer();
          if (state is DashboardError) {
            return KkErrorWidget(
              message: state.message,
              onRetry: () => context.read<DashboardBloc>().add(LoadDashboard()),
            );
          }
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
    final p = context.palette;
    return RefreshIndicator(
      color: p.accent,
      onRefresh: () async => context.read<DashboardBloc>().add(LoadDashboard()),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _portfolio(context, state)
                .animate()
                .fadeIn(duration: 500.ms)
                .slideY(begin: 0.05),
            const SizedBox(height: 20),
            _quickActions(context).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 24),
            _liveRates(context, state).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 24),
            _chart(context, state).animate().fadeIn(delay: 400.ms),
            const SizedBox(height: 24),
            _topAssets(context, state).animate().fadeIn(delay: 500.ms),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _portfolio(BuildContext context, DashboardLoaded s) {
    final p = context.palette;
    final t = context.txt;
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
                    p.accent.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TOTAL PORTFOLIO VALUE', style: t.label),
              const SizedBox(height: 4),
              Text(
                CurrencyFormatter.formatInr(s.user.portfolioValue),
                style: t.number,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: p.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_upward,
                      color: p.green,
                      size: 14,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '+12.4%',
                      style: t.captionMedium.copyWith(
                        color: p.green,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '🛡 Assets secured in cold storage',
                style: t.caption,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickActions(BuildContext context) {
    final p = context.palette;
    final t = context.txt;
    Widget card(IconData icon, String label, Color color, VoidCallback onTap) {
      return Expanded(
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: p.border),
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
                  style: t.captionMedium,
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
          p.accent,
          () => context.go('/home/scan'),
        ),
        const SizedBox(width: 12),
        card(
          Icons.arrow_upward_rounded,
          'Send',
          p.accentBlue,
          () => context.push('/payment'),
        ),
        const SizedBox(width: 12),
        card(
          Icons.shopping_bag_rounded,
          'Shop',
          p.green,
          () => context.push('/shop'),
        ),
        const SizedBox(width: 12),
        card(
          Icons.star_rounded,
          'Wishlist',
          p.yellow,
          () => context.push('/wishlist'),
        ),
      ],
    );
  }

  Widget _liveRates(BuildContext context, DashboardLoaded s) {
    final p = context.palette;
    final t = context.txt;
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
                style: t.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: p.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: p.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'LIVE',
                    style: t.caption.copyWith(
                      color: p.accent,
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
    final p = context.palette;
    final t = context.txt;
    final inrPrice = (data['inr'] as num?)?.toDouble() ?? 0.0;
    final change24h = (data['inr_24h_change'] as num?)?.toDouble() ?? 0.0;
    final isPositive = change24h >= 0;

    return GestureDetector(
      onTap: () => context.push('/coin/$coinId'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: p.surface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: p.border.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: p.surface2,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  symbol,
                  style: t.captionMedium.copyWith(
                    color: p.accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$symbol/INR',
                    style: t.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '₹${_formatInrCompact(inrPrice)}',
                    style: t.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isPositive ? p.green : p.red).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  '${isPositive ? '+' : ''}${change24h.toStringAsFixed(2)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isPositive ? p.green : p.red,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
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

  Widget _chart(BuildContext context, DashboardLoaded s) {
    final p = context.palette;
    final t = context.txt;
    double totalValue = 0;
    List<FlSpot> portfolioSpots = [];

    if (s.livePrices != null && s.livePrices!.isNotEmpty) {
      final bitcoinPrice =
          (s.livePrices!['bitcoin']?['inr'] as num?)?.toDouble() ?? 0;
      final ethereumPrice =
          (s.livePrices!['ethereum']?['inr'] as num?)?.toDouble() ?? 0;
      final tetherPrice =
          (s.livePrices!['tether']?['inr'] as num?)?.toDouble() ?? 0;

      const bitcoinHolding = 0.01;
      const ethereumHolding = 0.5;
      const tetherHolding = 1000;

      totalValue =
          (bitcoinPrice * bitcoinHolding) +
          (ethereumPrice * ethereumHolding) +
          (tetherPrice * tetherHolding);

      final baseValue = totalValue * 0.85;
      portfolioSpots = List.generate(30, (i) {
        final progress = i / 29.0;
        final growth = baseValue + (totalValue - baseValue) * progress;
        final variance =
            growth * 0.05 * (0.5 - (i % 7) / 14.0);
        return FlSpot(i.toDouble(), growth + variance);
      });
    } else {
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
    final chartColor = isPositive ? p.green : p.red;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Portfolio Analytics',
                  style: t.bodyMedium,
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
                  color: p.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  'MONTHLY',
                  style: t.caption.copyWith(
                    color: p.accent,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          Text('Past 30 days growth', style: t.caption),
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
                    getTooltipColor: (spot) => p.surface2,
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
                      style: t.caption.copyWith(fontSize: 10),
                    ),
                    const SizedBox(height: 2),
                    Builder(
                      builder: (ctx) {
                        final profit = portfolioSpots.isNotEmpty
                            ? portfolioSpots.last.y - portfolioSpots.first.y
                            : 0.0;
                        final pp = ctx.palette;
                        return Text(
                          '${profit >= 0 ? '+' : ''}₹${_formatNumber(profit.abs())}',
                          style: t.bodyMedium.copyWith(
                            color: profit >= 0 ? pp.green : pp.red,
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
                      style: t.caption.copyWith(fontSize: 10),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₹${_formatNumber(portfolioSpots.isNotEmpty ? portfolioSpots.map((s) => s.y).reduce((a, b) => a > b ? a : b) : 0)}',
                      style: t.bodyMedium,
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
                      style: t.caption.copyWith(fontSize: 10),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₹${_formatNumber(portfolioSpots.isNotEmpty ? portfolioSpots.map((s) => s.y).reduce((a, b) => a < b ? a : b) : 0)}',
                      style: t.bodyMedium,
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
    final p = context.palette;
    final t = context.txt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Top Assets',
                style: t.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            GestureDetector(
              onTap: () => context.go('/home/markets'),
              child: Text(
                'VIEW ALL',
                style: t.captionMedium.copyWith(
                  color: p.accent,
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

  String _formatNumber(double value) {
    if (value >= 100000) {
      return '${(value / 100000).toStringAsFixed(2)}L';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(2)}K';
    }
    return value.toStringAsFixed(0);
  }
}
