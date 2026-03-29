import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/kk_theme_context.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/shimmer_loader.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../shared/widgets/coin_list_tile.dart';
import '../bloc/markets_bloc.dart';

class MarketsScreen extends StatelessWidget {
  const MarketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.txt;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Markets',
          style: t.title.copyWith(color: p.accent),
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
    final p = context.palette;
    final t = context.txt;
    final featuredCoin = state.coins.isNotEmpty ? state.coins[0] : null;
    final isPositive = featuredCoin != null && state.chartData.isNotEmpty
        ? state.chartData.last.y > state.chartData.first.y
        : true;
    final chartColor = isPositive ? p.green : p.red;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: p.border),
            ),
            child: TextField(
              onChanged: (q) => context.read<MarketsBloc>().add(SearchCoins(q)),
              style: t.body,
              decoration: InputDecoration(
                hintText: 'Search markets...',
                prefixIcon: Icon(Icons.search, color: p.textSecondary),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
              ),
            ),
          ).animate().fadeIn(),
          const SizedBox(height: 16),
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
                        style: t.label.copyWith(
                          color: p.accent,
                        ),
                      ),
                      Text(
                        featuredCoin.priceFormatted,
                        style: t.numberSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          featuredCoin.name,
                          style: t.display,
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
                          color: (featuredCoin.isPositive ? p.green : p.red)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Text(
                          '${featuredCoin.isPositive ? '+' : ''}${featuredCoin.changeFormatted}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: featuredCoin.isPositive ? p.green : p.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${featuredCoin.symbol} / INR',
                    style: t.caption,
                  ),
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
                              color: chartColor,
                              barWidth: 2,
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
                ],
              ),
            ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 16),
          Row(
            children: [
              Text('Market Overview', style: t.titleSmall),
              const Spacer(),
              Text(
                '${state.filteredCoins.length} coins',
                style: t.caption,
              ),
            ],
          ),
          const SizedBox(height: 12),
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
}
