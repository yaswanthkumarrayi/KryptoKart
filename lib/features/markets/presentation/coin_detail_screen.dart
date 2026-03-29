import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/kk_theme_context.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/kk_button.dart';
import '../../../core/widgets/kk_text_field.dart';
import '../../../shared/models/coin_model.dart';
import '../../../shared/services/coingecko_service.dart';
import '../../../shared/services/wishlist_service.dart';
import '../../../core/service_locator.dart';

class CoinDetailScreen extends StatefulWidget {
  final String coinId;
  const CoinDetailScreen({super.key, required this.coinId});

  @override
  State<CoinDetailScreen> createState() => _CoinDetailScreenState();
}

class _CoinDetailScreenState extends State<CoinDetailScreen> {
  final _coinGecko = sl<CoinGeckoService>();
  final _wishlistService = sl<WishlistService>();
  final _inrController = TextEditingController();
  final _cryptoController = TextEditingController();

  CoinModel? _coin;
  List<FlSpot> _chartData = [];
  Map<String, dynamic>? _liveData;
  int _selectedDays = 1;
  bool _isLoading = true;
  bool _isUpdatingConverter = false;
  bool _isWishlisted = false;
  bool _isLoadingChart = false;
  int _currentChartRequest = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _inrController.addListener(_onInrChanged);
    _checkWishlist();
  }

  @override
  void dispose() {
    _inrController.dispose();
    _cryptoController.dispose();
    super.dispose();
  }

  Future<void> _checkWishlist() async {
    final isWishlisted = _wishlistService.isWishlisted(widget.coinId);
    if (mounted) {
      setState(() => _isWishlisted = isWishlisted);
    }
  }

  Future<void> _toggleWishlist() async {
    final newState = await _wishlistService.toggleWishlist(widget.coinId);
    if (mounted) {
      setState(() => _isWishlisted = newState);
    }
  }

  void _onInrChanged() {
    if (_isUpdatingConverter) return;
    final inrText = _inrController.text.trim();
    if (inrText.isEmpty) {
      _cryptoController.clear();
      return;
    }

    final inrAmount = double.tryParse(inrText);
    if (inrAmount == null || _liveData == null) return;

    final inrPrice = (_liveData?['inr'] as num?)?.toDouble();
    if (inrPrice == null || inrPrice == 0) return;

    _isUpdatingConverter = true;
    final cryptoAmount = inrAmount / inrPrice;
    _cryptoController.text = cryptoAmount.toStringAsFixed(8);
    _isUpdatingConverter = false;
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    CoinModel? coin;
    List<FlSpot> chart = [];
    Map<String, dynamic>? liveData;

    try {
      final priceData = await _coinGecko.fetchSimplePrice([widget.coinId]);
      liveData = priceData[widget.coinId] as Map<String, dynamic>?;
    } catch (e) {
      liveData = null;
    }

    try {
      chart = await _coinGecko.fetchMarketChart(
        widget.coinId,
        days: _selectedDays,
      );
    } catch (e) {
      chart = [];
    }

    try {
      final coins = await _coinGecko.fetchMarkets(perPage: 50);
      coin = coins.firstWhere(
        (c) => c.id == widget.coinId,
        orElse: () => CoinModel(
          id: widget.coinId,
          symbol: _getCoinSymbol(widget.coinId),
          name: _getCoinName(widget.coinId),
          imageUrl: '',
          currentPrice: (liveData?['inr'] as num?)?.toDouble() ?? 0,
          priceChange24h: (liveData?['inr_24h_change'] as num?)?.toDouble() ?? 0,
          marketCap: 0,
        ),
      );
    } catch (e) {
      coin = CoinModel(
        id: widget.coinId,
        symbol: _getCoinSymbol(widget.coinId),
        name: _getCoinName(widget.coinId),
        imageUrl: '',
        currentPrice: (liveData?['inr'] as num?)?.toDouble() ?? 0,
        priceChange24h: (liveData?['inr_24h_change'] as num?)?.toDouble() ?? 0,
        marketCap: 0,
      );
    }

    if (mounted) {
      setState(() {
        _coin = coin;
        _chartData = chart;
        _liveData = liveData;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadChartOnly(int days) async {
    final requestId = ++_currentChartRequest;

    setState(() {
      _selectedDays = days;
      _isLoadingChart = true;
    });

    try {
      final chart = await _coinGecko.fetchMarketChart(widget.coinId, days: days);

      if (mounted && requestId == _currentChartRequest) {
        setState(() {
          _chartData = chart;
          _isLoadingChart = false;
        });
      }
    } catch (e) {
      if (mounted && requestId == _currentChartRequest) {
        setState(() => _isLoadingChart = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.txt;
    final coinName = _getCoinName(widget.coinId);
    final coinSymbol = _getCoinSymbol(widget.coinId);

    return Scaffold(
      appBar: AppBar(
        title: Text('$coinName ($coinSymbol)', style: t.titleSmall),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: p.accent),
            )
          : _liveData == null
              ? const Center(child: Text('Coin data not available'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            Text(
                              '₹${_formatInrPrice((_liveData!['inr'] as num?)?.toDouble() ?? 0)}',
                              style: t.number.copyWith(fontSize: 40),
                            ).animate().fadeIn(),
                            const SizedBox(height: 8),
                            _buildChangeChip(context),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [1, 7, 30, 90, 365].map((d) {
                          final label = d == 1
                              ? '1D'
                              : d == 7
                                  ? '7D'
                                  : d == 30
                                      ? '1M'
                                      : d == 90
                                          ? '3M'
                                          : '1Y';
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ChoiceChip(
                              label: Text(label),
                              selected: _selectedDays == d,
                              selectedColor: p.accent.withValues(alpha: 0.2),
                              onSelected: (_) {
                                if (_selectedDays != d) {
                                  _loadChartOnly(d);
                                }
                              },
                              side: BorderSide(
                                color: _selectedDays == d
                                    ? p.accent
                                    : p.border,
                              ),
                              labelStyle: TextStyle(
                                color: _selectedDays == d
                                    ? p.accent
                                    : p.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      if (_chartData.isNotEmpty) _buildChart(context),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: _statCard(
                              context,
                              'Market Cap',
                              _formatMarketCap(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _statCard(
                              context,
                              '24h Change',
                              _formatChange(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildConverter(context, coinSymbol),
                      const SizedBox(height: 24),
                      KkButton(
                        label: 'Buy / Pay with $coinSymbol',
                        onTap: () {},
                        icon: Icons.shopping_cart_rounded,
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
    );
  }

  Widget _buildChangeChip(BuildContext context) {
    final p = context.palette;
    final change24h = (_liveData!['inr_24h_change'] as num?)?.toDouble() ?? 0.0;
    final isPositive = change24h >= 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (isPositive ? p.green : p.red).withValues(
          alpha: 0.15,
        ),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        '${isPositive ? '+' : ''}${change24h.toStringAsFixed(2)}%',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isPositive ? p.green : p.red,
        ),
      ),
    );
  }

  Widget _buildChart(BuildContext context) {
    final p = context.palette;
    final isPositive = _chartData.last.y > _chartData.first.y;
    final chartColor = isPositive ? p.green : p.red;

    return SizedBox(
      height: 200,
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
              spots: _chartData,
              isCurved: true,
              color: chartColor,
              barWidth: 2.5,
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
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildConverter(BuildContext context, String coinSymbol) {
    final p = context.palette;
    final t = context.txt;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.currency_exchange, color: p.accent, size: 18),
              const SizedBox(width: 8),
              Text('INR to $coinSymbol Converter', style: t.titleSmall),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Flexible(
                child: KkTextField(
                  label: 'INR',
                  hint: 'Enter amount',
                  controller: _inrController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  prefix: Text(
                    '₹',
                    style: TextStyle(
                      color: p.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward, color: p.accent, size: 20),
              ),
              Flexible(
                child: KkTextField(
                  label: coinSymbol,
                  hint: '0.00',
                  controller: _cryptoController,
                  keyboardType: TextInputType.number,
                  readOnly: true,
                  suffix: Text(
                    coinSymbol,
                    style: TextStyle(color: p.accent, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Enter INR amount to convert',
            style: t.caption.copyWith(fontSize: 11, color: p.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _statCard(BuildContext context, String label, String value) {
    final t = context.txt;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: t.caption),
          const SizedBox(height: 4),
          Text(value, style: t.bodyMedium),
        ],
      ),
    );
  }

  String _getCoinName(String coinId) {
    switch (coinId) {
      case 'bitcoin':
        return 'Bitcoin';
      case 'ethereum':
        return 'Ethereum';
      case 'tether':
        return 'Tether';
      default:
        return coinId.substring(0, 1).toUpperCase() + coinId.substring(1);
    }
  }

  String _getCoinSymbol(String coinId) {
    switch (coinId) {
      case 'bitcoin':
        return 'BTC';
      case 'ethereum':
        return 'ETH';
      case 'tether':
        return 'USDT';
      default:
        return coinId.toUpperCase();
    }
  }

  String _formatInrPrice(double price) {
    if (price >= 100000) return '${(price / 100000).toStringAsFixed(2)}L';
    if (price >= 1000) return '${(price / 1000).toStringAsFixed(2)}K';
    return price.toStringAsFixed(2);
  }

  String _formatMarketCap() {
    final marketCap = _coin?.marketCap ?? 0;
    if (marketCap >= 1e12) {
      return '₹${(marketCap / 1e12 * 83).toStringAsFixed(2)}T';
    }
    if (marketCap >= 1e9) {
      return '₹${(marketCap / 1e9 * 83).toStringAsFixed(2)}B';
    }
    if (marketCap >= 1e6) {
      return '₹${(marketCap / 1e6 * 83).toStringAsFixed(2)}M';
    }
    return '₹${(marketCap * 83).toStringAsFixed(0)}';
  }

  String _formatChange() {
    final change = (_liveData!['inr_24h_change'] as num?)?.toDouble() ?? 0.0;
    final sign = change >= 0 ? '+' : '';
    return '$sign${change.toStringAsFixed(2)}%';
  }
}
