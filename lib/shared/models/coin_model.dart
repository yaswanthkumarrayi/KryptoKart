class CoinModel {
  final String id;
  final String symbol;
  final String name;
  final String imageUrl;
  final double currentPriceUsd;
  final double priceChange24h;
  final double marketCap;
  final List<double> sparkline7d;

  const CoinModel({
    required this.id,
    required this.symbol,
    required this.name,
    required this.imageUrl,
    required this.currentPriceUsd,
    required this.priceChange24h,
    required this.marketCap,
    this.sparkline7d = const [],
  });

  factory CoinModel.fromCoinGecko(Map<String, dynamic> json) {
    List<double> sparkline = [];
    if (json['sparkline_in_7d'] != null && json['sparkline_in_7d']['price'] != null) {
      sparkline = (json['sparkline_in_7d']['price'] as List)
          .map((e) => (e as num).toDouble())
          .toList();
    }

    return CoinModel(
      id: json['id'] ?? '',
      symbol: (json['symbol'] ?? '').toString().toUpperCase(),
      name: json['name'] ?? '',
      imageUrl: json['image'] ?? '',
      currentPriceUsd: (json['current_price'] ?? 0).toDouble(),
      priceChange24h: (json['price_change_percentage_24h'] ?? 0).toDouble(),
      marketCap: (json['market_cap'] ?? 0).toDouble(),
      sparkline7d: sparkline,
    );
  }

  bool get isPositive => priceChange24h >= 0;

  String get priceFormatted {
    if (currentPriceUsd >= 1000) {
      return '\$${currentPriceUsd.toStringAsFixed(2)}';
    }
    return '\$${currentPriceUsd.toStringAsFixed(currentPriceUsd < 1 ? 6 : 2)}';
  }

  String get changeFormatted {
    final sign = priceChange24h >= 0 ? '+' : '';
    return '$sign${priceChange24h.toStringAsFixed(2)}%';
  }

  String get marketCapFormatted {
    if (marketCap >= 1e12) return '\$${(marketCap / 1e12).toStringAsFixed(2)}T';
    if (marketCap >= 1e9) return '\$${(marketCap / 1e9).toStringAsFixed(2)}B';
    if (marketCap >= 1e6) return '\$${(marketCap / 1e6).toStringAsFixed(2)}M';
    return '\$${marketCap.toStringAsFixed(0)}';
  }
}
