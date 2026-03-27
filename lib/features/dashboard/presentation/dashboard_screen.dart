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
        title: Row(
          children: [
            CircleAvatar(radius: 18, backgroundColor: AppColors.surface2, child: const Icon(Icons.person, color: AppColors.accent, size: 20)),
            const SizedBox(width: 10),
            Text('KryptoKart', style: AppTextStyles.title.copyWith(color: AppColors.accent)),
          ],
        ),
        actions: [
          IconButton(
            icon: Stack(children: [
              const Icon(Icons.notifications_outlined, color: Colors.white),
              Positioned(right: 0, top: 0, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.red, shape: BoxShape.circle))),
            ]),
            onPressed: () {},
          ),
        ],
      ),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoading) return _shimmer();
          if (state is DashboardError) return KkErrorWidget(message: state.message, onRetry: () => context.read<DashboardBloc>().add(LoadDashboard()));
          if (state is DashboardLoaded) return _content(context, state);
          return const SizedBox();
        },
      ),
    );
  }

  Widget _shimmer() => SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [ShimmerLoader.card(height: 160), const SizedBox(height: 16), ShimmerLoader.card(height: 80), const SizedBox(height: 16), ShimmerLoader.list(count: 3)]));

  Widget _content(BuildContext context, DashboardLoaded state) {
    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: () async => context.read<DashboardBloc>().add(LoadDashboard()),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _portfolio(state).animate().fadeIn(duration: 500.ms).slideY(begin: 0.05),
          const SizedBox(height: 20),
          _quickActions(context).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 24),
          _liveRates(context, state).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 24),
          _chart(state).animate().fadeIn(delay: 400.ms),
          const SizedBox(height: 24),
          _topAssets(context, state).animate().fadeIn(delay: 500.ms),
          const SizedBox(height: 20),
          if (state.recentTransactions.isNotEmpty) _recent(context, state).animate().fadeIn(delay: 600.ms),
          const SizedBox(height: 80),
        ]),
      ),
    );
  }

  Widget _portfolio(DashboardLoaded s) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Stack(children: [
        Positioned(top: -20, right: -20, child: Container(width: 100, height: 100, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [AppColors.accent.withValues(alpha: 0.15), Colors.transparent])))),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('TOTAL PORTFOLIO VALUE', style: AppTextStyles.label),
          const SizedBox(height: 4),
          Text(CurrencyFormatter.formatInr(s.user.portfolioValue), style: AppTextStyles.number),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppColors.green.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(50)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.arrow_upward, color: AppColors.green, size: 14),
              const SizedBox(width: 2),
              Text('+12.4%', style: AppTextStyles.captionMedium.copyWith(color: AppColors.green)),
            ]),
          ),
          const SizedBox(height: 8),
          Text('🛡 Assets secured in cold storage', style: AppTextStyles.caption),
        ]),
      ]),
    );
  }

  Widget _quickActions(BuildContext context) {
    Widget card(IconData icon, String label, Color color, VoidCallback onTap) {
      return Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
            child: Column(children: [
              Container(width: 44, height: 44, decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: color, size: 24)),
              const SizedBox(height: 8),
              Text(label, style: AppTextStyles.captionMedium),
            ]),
          ),
        ),
      );
    }

    return Row(children: [
      card(Icons.qr_code_scanner_rounded, 'Scan', AppColors.accent, () => context.go('/home/scan')),
      const SizedBox(width: 12),
      card(Icons.arrow_upward_rounded, 'Send', AppColors.accentBlue, () => context.push('/payment')),
      const SizedBox(width: 12),
      card(Icons.shopping_bag_rounded, 'Shop', AppColors.green, () => context.push('/shop')),
    ]);
  }

  Widget _liveRates(BuildContext context, DashboardLoaded s) {
    final btc = s.topCoins.isNotEmpty ? s.topCoins[0] : null;
    final eth = s.topCoins.length > 1 ? s.topCoins[1] : null;
    double? btcInr = s.livePrices?['bitcoin']?['inr']?.toDouble();
    double? ethInr = s.livePrices?['ethereum']?['inr']?.toDouble();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('Live Market Rates', style: AppTextStyles.titleSmall),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(50)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text('LIVE UPDATES', style: AppTextStyles.caption.copyWith(color: AppColors.accent, fontSize: 9, fontWeight: FontWeight.w600)),
          ]),
        ),
      ]),
      const SizedBox(height: 12),
      if (btc != null) CryptoMiniCard(coin: btc, inrPrice: btcInr, onTap: () => context.push('/coin/bitcoin')),
      if (eth != null) CryptoMiniCard(coin: eth, inrPrice: ethInr, onTap: () => context.push('/coin/ethereum')),
    ]);
  }

  Widget _chart(DashboardLoaded s) {
    final spots = List.generate(30, (i) => FlSpot(i.toDouble(), 750000.0 + (i * 3200.0) + (i % 3 == 0 ? -5000 : 8000)));

    return GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('Portfolio Analytics', style: AppTextStyles.bodyMedium),
        const Spacer(),
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(50)), child: Text('MONTHLY', style: AppTextStyles.caption.copyWith(color: AppColors.accent, fontSize: 10))),
      ]),
      Text('Past 30 days growth', style: AppTextStyles.caption),
      const SizedBox(height: 16),
      SizedBox(height: 160, child: LineChart(LineChartData(
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        lineTouchData: LineTouchData(touchTooltipData: LineTouchTooltipData(getTooltipColor: (spot) => AppColors.surface2)),
        lineBarsData: [LineChartBarData(spots: spots, isCurved: true, color: AppColors.accent, barWidth: 2.5, isStrokeCapRound: true, dotData: const FlDotData(show: false), belowBarData: BarAreaData(show: true, gradient: AppColors.chartGradient))],
      ), duration: const Duration(milliseconds: 400))),
      const SizedBox(height: 16),
      Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        Column(children: [Text('PROFIT', style: AppTextStyles.caption.copyWith(fontSize: 10)), const SizedBox(height: 2), Text('₹45,200', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.accent))]),
        Column(children: [Text('HIGH', style: AppTextStyles.caption.copyWith(fontSize: 10)), const SizedBox(height: 2), Text('₹8,90,000', style: AppTextStyles.bodyMedium)]),
        Column(children: [Text('LOW', style: AppTextStyles.caption.copyWith(fontSize: 10)), const SizedBox(height: 2), Text('₹7,12,000', style: AppTextStyles.bodyMedium)]),
      ]),
    ]));
  }

  Widget _topAssets(BuildContext context, DashboardLoaded s) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('Top Assets', style: AppTextStyles.titleSmall),
        const Spacer(),
        GestureDetector(onTap: () => context.go('/home/markets'), child: Text('VIEW ALL →', style: AppTextStyles.captionMedium.copyWith(color: AppColors.accent))),
      ]),
      const SizedBox(height: 12),
      ...s.topCoins.take(3).map((c) => CoinListTile(coin: c, onTap: () => context.push('/coin/${c.id}'))),
    ]);
  }

  Widget _recent(BuildContext context, DashboardLoaded s) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('Recent Activity', style: AppTextStyles.titleSmall),
        const Spacer(),
        GestureDetector(onTap: () => context.go('/home/activity'), child: Text('VIEW ALL →', style: AppTextStyles.captionMedium.copyWith(color: AppColors.accent))),
      ]),
      const SizedBox(height: 12),
      ...s.recentTransactions.take(3).map((t) => TransactionTile(transaction: t, onTap: () => context.push('/transaction/${t.id}'))),
    ]);
  }
}
