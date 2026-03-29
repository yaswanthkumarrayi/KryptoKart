import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/kk_theme_context.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/kk_button.dart';
import '../../../core/widgets/kk_text_field.dart';
import '../../../shared/models/coin_model.dart';
import '../../../shared/models/transaction_model.dart';
import '../../../shared/services/coingecko_service.dart';
import '../../../shared/services/wishlist_service.dart';
import '../../../shared/services/wallet_service.dart';
import '../../../shared/services/api_service.dart';
import '../../../core/service_locator.dart';
import '../../../core/utils/wallet_display.dart';

class CoinDetailScreen extends StatefulWidget {
  final String coinId;
  const CoinDetailScreen({super.key, required this.coinId});

  @override
  State<CoinDetailScreen> createState() => _CoinDetailScreenState();
}

class _CoinDetailScreenState extends State<CoinDetailScreen> {
  final _coinGecko = sl<CoinGeckoService>();
  final _wishlistService = sl<WishlistService>();
  final _walletService = sl<WalletService>();
  final _apiService = sl<ApiService>();
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
  String? _errorMessage;
  bool _hasPartialData = false;

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
    if (inrAmount == null) return;

    final inrPrice =
        (_liveData?['inr'] as num?)?.toDouble() ?? _coin?.currentPrice;
    if (inrPrice == null || inrPrice == 0) return;

    _isUpdatingConverter = true;
    final cryptoAmount = inrAmount / inrPrice;
    _cryptoController.text = cryptoAmount.toStringAsFixed(8);
    _isUpdatingConverter = false;
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    CoinModel? coin;
    List<FlSpot> chart = [];
    Map<String, dynamic>? liveData;

    // 1. Try to get coin from cached market data first (instant)
    coin = _coinGecko.getCoinFromCache(widget.coinId);
    if (coin != null && coin.currentPrice > 0) {
      _hasPartialData = true;
      chart = _coinGecko.getSparklineAsChart(coin);
    }

    // 2. Fetch live price data
    try {
      final priceData = await _coinGecko.fetchSimplePrice([widget.coinId]);
      liveData = priceData[widget.coinId] as Map<String, dynamic>?;
    } catch (e) {
      if (coin != null && coin.currentPrice > 0) {
        liveData = {
          'inr': coin.currentPrice,
          'inr_24h_change': coin.priceChange24h,
        };
      }
    }

    // 3. Fetch chart data for selected period
    try {
      final chartResult = await _coinGecko.fetchMarketChart(
        widget.coinId,
        days: _selectedDays,
      );
      if (chartResult.isNotEmpty) {
        chart = chartResult;
      }
    } catch (e) {
      // Keep sparkline chart as fallback
    }

    // 4. If we still don't have a coin, fetch from markets
    if (coin == null || coin.currentPrice == 0) {
      try {
        final coins = await _coinGecko.fetchMarkets(perPage: 100);
        coin = coins.firstWhere(
          (c) => c.id == widget.coinId,
          orElse: () => _createFallbackCoin(liveData),
        );
      } catch (e) {
        coin = _createFallbackCoin(liveData);
      }
    }

    // 5. Update coin with live data if available
    if (liveData != null && coin != null) {
      final livePrice = (liveData['inr'] as num?)?.toDouble();
      final liveChange = (liveData['inr_24h_change'] as num?)?.toDouble();

      if (livePrice != null && livePrice > 0) {
        coin = CoinModel(
          id: coin.id,
          symbol: coin.symbol,
          name: coin.name,
          imageUrl: coin.imageUrl,
          currentPrice: livePrice,
          priceChange24h: liveChange ?? coin.priceChange24h,
          marketCap: coin.marketCap,
          sparkline7d: coin.sparkline7d,
        );
      }
    }

    if (mounted) {
      final hasAnyData =
          (liveData != null &&
              (liveData['inr'] as num?)?.toDouble() != null &&
              (liveData['inr'] as num).toDouble() > 0) ||
          (coin != null && coin.currentPrice > 0);

      setState(() {
        _coin = coin;
        _chartData = chart;
        _liveData = liveData;
        _isLoading = false;
        _hasPartialData = hasAnyData;
        _errorMessage = hasAnyData
            ? null
            : 'Unable to load data for this coin. Please try again.';
      });
    }
  }

  CoinModel _createFallbackCoin(Map<String, dynamic>? liveData) {
    return CoinModel(
      id: widget.coinId,
      symbol: _getCoinSymbol(widget.coinId),
      name: _getCoinName(widget.coinId),
      imageUrl: '',
      currentPrice: (liveData?['inr'] as num?)?.toDouble() ?? 0,
      priceChange24h: (liveData?['inr_24h_change'] as num?)?.toDouble() ?? 0,
      marketCap: 0,
    );
  }

  /// Load only chart data with request cancellation to prevent race conditions
  Future<void> _loadChartOnly(int days) async {
    final requestId = ++_currentChartRequest;

    setState(() {
      _selectedDays = days;
      _isLoadingChart = true;
    });

    try {
      final chart = await _coinGecko.fetchMarketChart(
        widget.coinId,
        days: days,
      );

      // Only update if this is still the latest request
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
    final t = context.txt;
    final coinName = _getCoinName(widget.coinId);
    final coinSymbol = _getCoinSymbol(widget.coinId);

    return Scaffold(
      appBar: AppBar(
        title: Text('$coinName ($coinSymbol)', style: t.titleSmall),
        actions: [
          IconButton(
            icon: Icon(
              _isWishlisted ? Icons.star_rounded : Icons.star_border_rounded,
              color: _isWishlisted ? context.palette.yellow : context.palette.accent,
            ),
            onPressed: _toggleWishlist,
          ),
        ],
      ),
      body: _buildBody(coinSymbol),
    );
  }

  Widget _buildBody(String coinSymbol) {
    final p = context.palette;

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: p.accent),
      );
    }

    // Show error only if we have no data at all
    if (_errorMessage != null && !_hasPartialData) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: p.red.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: context.txt.body.copyWith(color: p.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _loadData,
                icon: Icon(Icons.refresh, color: p.accent),
                label: Text(
                  'Retry',
                  style: context.txt.bodyMedium.copyWith(color: p.accent),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: p.accent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final displayPrice =
        (_liveData?['inr'] as num?)?.toDouble() ?? _coin?.currentPrice ?? 0;
    final displayChange =
        (_liveData?['inr_24h_change'] as num?)?.toDouble() ??
        _coin?.priceChange24h ??
        0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Price hero
          Center(
            child: Column(
              children: [
                Text(
                  '₹${_formatInrPrice(displayPrice)}',
                  style: context.txt.number.copyWith(fontSize: 40),
                ).animate().fadeIn(),
                const SizedBox(height: 8),
                _buildChangeChip(displayChange),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Time filter chips
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
                    color: _selectedDays == d ? p.accent : p.border,
                  ),
                  labelStyle: TextStyle(
                    color: _selectedDays == d ? p.accent : p.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // Chart with loading state
          if (_isLoadingChart)
            SizedBox(
              height: 200,
              child: Center(
                child: CircularProgressIndicator(color: p.accent),
              ),
            )
          else if (_chartData.isNotEmpty)
            _buildChart()
          else
            _buildEmptyChart(),

          const SizedBox(height: 24),

          // Stats grid
          Row(
            children: [
              Expanded(
                child: _statCard('Market Cap', _formatMarketCap()),
              ),
              const SizedBox(width: 12),
              Expanded(child: _statCard('24h Change', _formatChange(displayChange))),
            ],
          ),

          const SizedBox(height: 24),

          // INR to Crypto Converter
          _buildConverter(coinSymbol),

          const SizedBox(height: 24),

          KkButton(
            label: 'Buy / Pay with $coinSymbol',
            onTap: () => _showPaymentModal(displayPrice),
            icon: Icons.shopping_cart_rounded,
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildEmptyChart() {
    final p = context.palette;
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: p.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border.withValues(alpha: 0.5)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.show_chart_rounded,
              size: 48,
              color: p.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 8),
            Text(
              'Chart data unavailable',
              style: context.txt.caption.copyWith(color: p.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChangeChip(double change24h) {
    final p = context.palette;
    final isPositive = change24h >= 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (isPositive ? p.green : p.red).withValues(alpha: 0.15),
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

  Widget _buildChart() {
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

  Widget _buildConverter(String coinSymbol) {
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

  Widget _statCard(String label, String value) {
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

  // Extended coin mappings for common coins
  static const Map<String, String> _coinNames = {
    'bitcoin': 'Bitcoin',
    'ethereum': 'Ethereum',
    'tether': 'Tether',
    'binancecoin': 'Binance Coin',
    'solana': 'Solana',
    'ripple': 'XRP',
    'cardano': 'Cardano',
    'dogecoin': 'Dogecoin',
    'matic-network': 'Polygon',
    'polkadot': 'Polkadot',
    'litecoin': 'Litecoin',
    'avalanche-2': 'Avalanche',
    'chainlink': 'Chainlink',
    'uniswap': 'Uniswap',
    'stellar': 'Stellar',
    'wrapped-bitcoin': 'Wrapped Bitcoin',
    'cosmos': 'Cosmos',
    'monero': 'Monero',
  };

  static const Map<String, String> _coinSymbols = {
    'bitcoin': 'BTC',
    'ethereum': 'ETH',
    'tether': 'USDT',
    'binancecoin': 'BNB',
    'solana': 'SOL',
    'ripple': 'XRP',
    'cardano': 'ADA',
    'dogecoin': 'DOGE',
    'matic-network': 'MATIC',
    'polkadot': 'DOT',
    'litecoin': 'LTC',
    'avalanche-2': 'AVAX',
    'chainlink': 'LINK',
    'uniswap': 'UNI',
    'stellar': 'XLM',
    'wrapped-bitcoin': 'WBTC',
    'cosmos': 'ATOM',
    'monero': 'XMR',
  };

  String _getCoinName(String coinId) {
    if (_coin != null && _coin!.name.isNotEmpty) {
      return _coin!.name;
    }
    return _coinNames[coinId] ??
        coinId.split('-').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
  }

  String _getCoinSymbol(String coinId) {
    if (_coin != null && _coin!.symbol.isNotEmpty) {
      return _coin!.symbol;
    }
    return _coinSymbols[coinId] ?? coinId.toUpperCase().replaceAll('-', '');
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

  String _formatChange(double change) {
    final sign = change >= 0 ? '+' : '';
    return '$sign${change.toStringAsFixed(2)}%';
  }

  /// Show payment modal for buying/paying with crypto
  void _showPaymentModal(double currentPriceInr) {
    final paymentAmountController = TextEditingController();
    final cryptoAmountController = TextEditingController();
    bool isProcessing = false;
    String? errorMessage;
    double cryptoAmount = 0;
    final p = context.palette;

    void updateCryptoAmount(String inrText) {
      final inrAmount = double.tryParse(inrText) ?? 0;
      if (inrAmount > 0 && currentPriceInr > 0) {
        cryptoAmount = inrAmount / currentPriceInr;
        cryptoAmountController.text = cryptoAmount.toStringAsFixed(8);
      } else {
        cryptoAmountController.clear();
        cryptoAmount = 0;
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Container(
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: p.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: p.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.account_balance_wallet_rounded,
                          color: p.accent,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pay with ${_getCoinSymbol(widget.coinId)}',
                              style: context.txt.titleSmall,
                            ),
                            Text(
                              'Via MetaMask',
                              style: context.txt.caption,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Wallet status
                  GlassCard(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          _walletService.isConnected
                              ? Icons.check_circle_rounded
                              : Icons.account_balance_wallet_outlined,
                          color: _walletService.isConnected
                              ? p.green
                              : p.textSecondary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _walletService.isConnected
                                ? 'Connected: ${shortenWalletAddress(_walletService.connectedAddress)}'
                                : 'Wallet not connected',
                            style: context.txt.bodyMedium,
                          ),
                        ),
                        if (!_walletService.isConnected)
                          TextButton(
                            onPressed: () async {
                              setSheetState(() => isProcessing = true);
                              try {
                                await _walletService.connectMetaMask();
                                if (ctx.mounted) {
                                  setSheetState(() {
                                    isProcessing = false;
                                    errorMessage = null;
                                  });
                                }
                              } catch (e) {
                                if (ctx.mounted) {
                                  setSheetState(() {
                                    isProcessing = false;
                                    errorMessage = 'Failed to connect wallet';
                                  });
                                }
                              }
                            },
                            child: Text(
                              'Connect',
                              style: TextStyle(color: p.accent),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Amount input
                  KkTextField(
                    label: 'Amount in INR',
                    hint: 'Enter amount',
                    controller: paymentAmountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    prefix: Text(
                      '₹',
                      style: TextStyle(
                        color: p.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onChanged: (val) {
                      setSheetState(() {
                        updateCryptoAmount(val);
                        errorMessage = null;
                      });
                    },
                  ),

                  const SizedBox(height: 12),

                  // Converted crypto amount
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('You pay', style: context.txt.caption),
                        Text(
                          '${cryptoAmountController.text.isEmpty ? "0.00000000" : cryptoAmountController.text} ${_getCoinSymbol(widget.coinId)}',
                          style: context.txt.bodyMedium.copyWith(
                            color: p.accent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Rate info
                  Text(
                    '1 ${_getCoinSymbol(widget.coinId)} = ₹${_formatInrPrice(currentPriceInr)}',
                    style: context.txt.caption.copyWith(color: p.textSecondary),
                  ),

                  if (errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: p.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: p.red, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errorMessage!,
                              style: context.txt.caption.copyWith(color: p.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Pay button
                  KkButton(
                    label: isProcessing ? 'Processing...' : 'Pay with MetaMask',
                    icon: Icons.send_rounded,
                    isLoading: isProcessing,
                    onTap: isProcessing
                        ? null
                        : () async {
                            final inrAmount =
                                double.tryParse(paymentAmountController.text) ?? 0;
                            if (inrAmount <= 0) {
                              setSheetState(
                                () => errorMessage = 'Please enter a valid amount',
                              );
                              return;
                            }

                            if (!_walletService.isConnected) {
                              setSheetState(
                                () => errorMessage =
                                    'Please connect your wallet first',
                              );
                              return;
                            }

                            if (cryptoAmount <= 0) {
                              setSheetState(
                                () => errorMessage = 'Invalid conversion amount',
                              );
                              return;
                            }

                            setSheetState(() {
                              isProcessing = true;
                              errorMessage = null;
                            });

                            final coinId = widget.coinId.toLowerCase();
                            final isEthBased = coinId == 'ethereum' ||
                                coinId == 'matic-network' ||
                                coinId == 'binancecoin';

                            double payableAmount = cryptoAmount;

                            if (!isEthBased) {
                              try {
                                final ethPrice = await _coinGecko
                                    .fetchSimplePrice(['ethereum']);
                                final ethInr =
                                    (ethPrice['ethereum']?['inr'] as num?)
                                        ?.toDouble() ??
                                    0;
                                if (ethInr > 0) {
                                  payableAmount = inrAmount / ethInr;
                                }
                              } catch (e) {
                                if (ctx.mounted) {
                                  setSheetState(() {
                                    isProcessing = false;
                                    errorMessage =
                                        'Failed to get ETH price for conversion';
                                  });
                                }
                                return;
                              }
                            }

                            final result = await _walletService.payWithCrypto(
                              cryptoAmount: payableAmount,
                            );

                            if (!ctx.mounted) return;

                            if (result.success) {
                              try {
                                final txnId =
                                    'TXN-${const Uuid().v4().substring(0, 8).toUpperCase()}';
                                final txnData =
                                    await _apiService.createTransaction({
                                  'txnId': txnId,
                                  'type': 'crypto',
                                  'amountInr': inrAmount,
                                  'cryptoCoin': widget.coinId,
                                  'cryptoAmount': cryptoAmount,
                                  'recipientName': 'Crypto Payment',
                                  'recipientAddress':
                                      _walletService.defaultReceiverWallet,
                                  'status': 'success',
                                  'txHash': result.transactionHash,
                                });

                                Navigator.pop(ctx);

                                if (mounted) {
                                  final txn = TransactionModel.fromJson(
                                    txnData['transaction'],
                                  );
                                  context.push('/receipt', extra: txn);
                                }
                              } catch (e) {
                                Navigator.pop(ctx);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Payment sent! Hash: ${result.transactionHash?.substring(0, 16)}...',
                                      ),
                                      backgroundColor: p.green,
                                    ),
                                  );
                                }
                              }
                            } else {
                              setSheetState(() {
                                isProcessing = false;
                                errorMessage =
                                    result.errorMessage ?? 'Transaction failed';
                              });
                            }
                          },
                  ),

                  const SizedBox(height: 8),

                  // Cancel button
                  TextButton(
                    onPressed: isProcessing ? null : () => Navigator.pop(ctx),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: isProcessing
                            ? p.textSecondary.withValues(alpha: 0.5)
                            : p.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
