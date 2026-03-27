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
import '../../../shared/widgets/coin_list_tile.dart';
import '../bloc/markets_bloc.dart';

class MarketsScreen extends StatelessWidget {
  const MarketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.surface2,
              child: const Icon(Icons.person, color: AppColors.accent, size: 20),
            ),
            const SizedBox(width: 10),
            Text('KryptoKart', style: AppTextStyles.title.copyWith(color: AppColors.accent)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
        ],
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
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                      Text('FEATURED ASSET', style: AppTextStyles.label.copyWith(color: AppColors.accent)),
                      Text(featuredCoin.priceFormatted, style: AppTextStyles.numberSmall),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(featuredCoin.name, style: AppTextStyles.display),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (featuredCoin.isPositive ? AppColors.green : AppColors.red).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Text(
                          '↑ ${featuredCoin.changeFormatted}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: featuredCoin.isPositive ? AppColors.green : AppColors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text('${featuredCoin.symbol} / USD', style: AppTextStyles.caption),
                  const SizedBox(height: 16),
                  if (state.chartData.isNotEmpty)
                    SizedBox(
                      height: 140,
                      child: LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          titlesData: const FlTitlesData(show: false),
                          lineTouchData: const LineTouchData(enabled: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: state.chartData,
                              isCurved: true,
                              color: AppColors.accent,
                              barWidth: 2,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: AppColors.chartGradient,
                              ),
                            ),
                          ],
                        ),
                        duration: const Duration(milliseconds: 400),
                      ),
                    ),
                ],
              ),
            ).animate().fadeIn(delay: 100.ms),

          const SizedBox(height: 16),

          // Market Overview Header
          Row(
            children: [
              Text('Market Overview', style: AppTextStyles.titleSmall),
              const Spacer(),
              Text('${state.filteredCoins.length} coins', style: AppTextStyles.caption),
            ],
          ),

          const SizedBox(height: 12),

          // Coin list
          ...state.filteredCoins.map((coin) => CoinListTile(
                coin: coin,
                isWatchlisted: state.watchlist.contains(coin.id),
                onTap: () => context.push('/coin/${coin.id}'),
                onWatchlistTap: () => context.read<MarketsBloc>().add(ToggleWatchlist(coin.id)),
              )),

          if (state.filteredCoins.isEmpty)
            const KkEmptyWidget(message: 'No coins match your search', icon: Icons.search_off),

          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
