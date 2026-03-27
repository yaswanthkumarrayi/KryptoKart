import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/kk_button.dart';
import '../../../shared/models/coin_model.dart';
import '../../../shared/services/coingecko_service.dart';
import '../../../core/service_locator.dart';

class CoinDetailScreen extends StatefulWidget {
  final String coinId;
  const CoinDetailScreen({super.key, required this.coinId});

  @override
  State<CoinDetailScreen> createState() => _CoinDetailScreenState();
}

class _CoinDetailScreenState extends State<CoinDetailScreen> {
  final _coinGecko = sl<CoinGeckoService>();
  CoinModel? _coin;
  List<FlSpot> _chartData = [];
  int _selectedDays = 7;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final coins = await _coinGecko.fetchMarkets(perPage: 10);
      final coin = coins.firstWhere((c) => c.id == widget.coinId, orElse: () => coins.first);
      final chart = await _coinGecko.fetchMarketChart(widget.coinId, days: _selectedDays);
      setState(() {
        _coin = coin;
        _chartData = chart;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _coin != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${_coin!.name} (${_coin!.symbol})', style: AppTextStyles.titleSmall),
                ],
              )
            : const Text('Coin Details'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : _coin == null
              ? const Center(child: Text('Coin not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Price hero
                      Center(
                        child: Column(
                          children: [
                            Text(_coin!.priceFormatted, style: AppTextStyles.number.copyWith(fontSize: 40))
                                .animate().fadeIn(),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: (_coin!.isPositive ? AppColors.green : AppColors.red).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Text(
                                _coin!.changeFormatted,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: _coin!.isPositive ? AppColors.green : AppColors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Time filter chips
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [1, 7, 30, 90, 365].map((d) {
                          final label = d == 1 ? '1D' : d == 7 ? '7D' : d == 30 ? '1M' : d == 90 ? '3M' : '1Y';
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ChoiceChip(
                              label: Text(label),
                              selected: _selectedDays == d,
                              selectedColor: AppColors.accent.withValues(alpha: 0.2),
                              onSelected: (_) {
                                setState(() => _selectedDays = d);
                                _loadData();
                              },
                              side: BorderSide(
                                color: _selectedDays == d ? AppColors.accent : AppColors.border,
                              ),
                              labelStyle: TextStyle(
                                color: _selectedDays == d ? AppColors.accent : AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 20),

                      // Chart
                      if (_chartData.isNotEmpty)
                        SizedBox(
                          height: 200,
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
                                  spots: _chartData,
                                  isCurved: true,
                                  color: AppColors.accent,
                                  barWidth: 2.5,
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
                        ).animate().fadeIn(delay: 200.ms),

                      const SizedBox(height: 24),

                      // Stats grid
                      Row(
                        children: [
                          Expanded(child: _statCard('Market Cap', _coin!.marketCapFormatted)),
                          const SizedBox(width: 12),
                          Expanded(child: _statCard('24h Change', _coin!.changeFormatted)),
                        ],
                      ),

                      const SizedBox(height: 24),

                      KkButton(
                        label: 'Buy / Pay with ${_coin!.symbol}',
                        onTap: () {},
                        icon: Icons.shopping_cart_rounded,
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
    );
  }

  Widget _statCard(String label, String value) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}
