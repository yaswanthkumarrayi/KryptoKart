import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/shimmer_loader.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../shared/models/coin_model.dart';
import '../../../shared/widgets/coin_list_tile.dart';
import '../bloc/markets_bloc.dart';

class MarketsScreen extends StatelessWidget {
  const MarketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.go('/home'),
        ),
        title: Text(
          'Markets',
          style: AppTextStyles.title.copyWith(color: AppColors.accent),
        ),
        centerTitle: false,
      ),
      body: BlocBuilder<MarketsBloc, MarketsState>(
        builder: (context, state) {
          if (state is MarketsLoading) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ShimmerLoader.card(height: 200),
                  const SizedBox(height: 16),
                  ShimmerLoader.list(count: 5),
                ],
              ),
            );
          }
          if (state is MarketsError) {
            return KkErrorWidget(
              message: state.message,
              onRetry: () => context.read<MarketsBloc>().add(LoadMarkets()),
            );
          }
          if (state is MarketsLoaded) {
            return _buildContent(context, state);
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, MarketsLoaded state) {
    final featuredCoin = state.coins.isNotEmpty ? state.coins[0] : null;
    final isPositive = featuredCoin != null && state.chartData.isNotEmpty
        ? state.chartData.last.y > state.chartData.first.y
        : true;
    final chartColor = isPositive ? AppColors.green : AppColors.red;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              onChanged: (q) => context.read<MarketsBloc>().add(SearchCoins(q)),
              style: AppTextStyles.body,
              decoration: const InputDecoration(
                hintText: 'Search markets...',
                prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
              ),
            ),
          ).animate().fadeIn(),

          const SizedBox(height: 16),

          // Featured Asset Card
          if (featuredCoin != null)
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'FEATURED ASSET',
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.accent,
                        ),
                      ),
                      Text(
                        featuredCoin.priceFormatted,
                        style: AppTextStyles.numberSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          featuredCoin.name,
                          style: AppTextStyles.display,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (featuredCoin.isPositive
                                      ? AppColors.green
                                      : AppColors.red)
                                  .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Text(
                          '${featuredCoin.isPositive ? '+' : ''}${featuredCoin.changeFormatted}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: featuredCoin.isPositive
                                ? AppColors.green
                                : AppColors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${featuredCoin.symbol} / INR',
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: 16),
                  _buildFeaturedChart(state, chartColor, featuredCoin),
                ],
              ),
            ).animate().fadeIn(delay: 100.ms),

          const SizedBox(height: 16),

          // Market Overview Header
          Row(
            children: [
              Text('Market Overview', style: AppTextStyles.titleSmall),
              const Spacer(),
              Text(
                '${state.filteredCoins.length} coins',
                style: AppTextStyles.caption,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Coin list
          ...state.filteredCoins.map(
            (coin) => CoinListTile(
              coin: coin,
              isWatchlisted: state.watchlist.contains(coin.id),
              onTap: () => context.push('/coin/${coin.id}'),
              onWatchlistTap: () =>
                  context.read<MarketsBloc>().add(ToggleWatchlist(coin.id)),
            ),
          ),

          if (state.filteredCoins.isEmpty)
            const KkEmptyWidget(
              message: 'No coins match your search',
              icon: Icons.search_off,
            ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }
  
  Widget _buildFeaturedChart(MarketsLoaded state, Color chartColor, CoinModel featuredCoin) {
    // Use chart data if available, otherwise fall back to sparkline
    List<FlSpot> chartData = state.chartData;
    
    // If chart data is empty, try to use sparkline
    if (chartData.isEmpty && featuredCoin.sparkline7d.isNotEmpty) {
      chartData = featuredCoin.sparkline7d
          .asMap()
          .entries
          .where((e) => e.value > 0)
          .map((e) => FlSpot(e.key.toDouble(), e.value))
          .toList();
    }
    
    // Still empty? Show placeholder
    if (chartData.length < 2) {
      return Container(
        height: 140,
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.show_chart_rounded,
                size: 32,
                color: AppColors.textSecondary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 4),
              Text(
                'Chart loading...',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // Recalculate chart color based on actual data
    final actualColor = chartData.last.y > chartData.first.y 
        ? AppColors.green 
        : AppColors.red;
    
    return SizedBox(
      height: 140,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: const FlTitlesData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              spots: chartData,
              isCurved: true,
              color: actualColor,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    actualColor.withValues(alpha: 0.3),
                    actualColor.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 400),
      ),
    );
  }
}
