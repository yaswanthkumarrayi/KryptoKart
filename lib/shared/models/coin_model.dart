class CoinModel {
  final String id;
  final String symbol;
  final String name;
  final String imageUrl;
  final double currentPrice;
  final double priceChange24h;
  final double marketCap;
  final List<double> sparkline7d;
  final String currency;

  const CoinModel({
    required this.id,
    required this.symbol,
    required this.name,
    required this.imageUrl,
    required this.currentPrice,
    required this.priceChange24h,
    required this.marketCap,
    this.sparkline7d = const [],
    this.currency = 'inr',
  });

  // Keep backward compatibility
  double get currentPriceUsd => currentPrice;

  factory CoinModel.fromCoinGecko(
    Map<String, dynamic> json, {
    String currency = 'inr',
  }) {
    List<double> sparkline = [];
    if (json['sparkline_in_7d'] != null &&
        json['sparkline_in_7d']['price'] != null) {
      sparkline = (json['sparkline_in_7d']['price'] as List)
          .map((e) => (e as num).toDouble())
          .toList();
    }

    return CoinModel(
      id: json['id'] ?? '',
      symbol: (json['symbol'] ?? '').toString().toUpperCase(),
      name: json['name'] ?? '',
      imageUrl: json['image'] ?? '',
      currentPrice: (json['current_price'] ?? 0).toDouble(),
      priceChange24h: (json['price_change_percentage_24h'] ?? 0).toDouble(),
      marketCap: (json['market_cap'] ?? 0).toDouble(),
      sparkline7d: sparkline,
      currency: currency,
    );
  }

  bool get isPositive => priceChange24h >= 0;

  String get priceFormatted {
    if (currency == 'inr') {
      return _formatInr(currentPrice);
    }
    if (currentPrice >= 1000) {
      return '\$${currentPrice.toStringAsFixed(2)}';
    }
    return '\$${currentPrice.toStringAsFixed(currentPrice < 1 ? 6 : 2)}';
  }

  String _formatInr(double value) {
    if (value >= 10000000) {
      return '₹${(value / 10000000).toStringAsFixed(2)} Cr';
    } else if (value >= 100000) {
      return '₹${(value / 100000).toStringAsFixed(2)} L';
    } else if (value >= 1000) {
      return '₹${value.toStringAsFixed(0)}';
    } else if (value >= 1) {
      return '₹${value.toStringAsFixed(2)}';
    }
    return '₹${value.toStringAsFixed(6)}';
  }

  String get changeFormatted {
    final sign = priceChange24h >= 0 ? '+' : '';
    return '$sign${priceChange24h.toStringAsFixed(2)}%';
  }

  String get marketCapFormatted {
    if (currency == 'inr') {
      if (marketCap >= 1e13)
        return '₹${(marketCap / 1e13).toStringAsFixed(2)} TCr';
      if (marketCap >= 1e11)
        return '₹${(marketCap / 1e11).toStringAsFixed(2)} KCr';
      if (marketCap >= 1e7)
        return '₹${(marketCap / 1e7).toStringAsFixed(2)} Cr';
      if (marketCap >= 1e5) return '₹${(marketCap / 1e5).toStringAsFixed(2)} L';
      return '₹${marketCap.toStringAsFixed(0)}';
    }
    if (marketCap >= 1e12) return '\$${(marketCap / 1e12).toStringAsFixed(2)}T';
    if (marketCap >= 1e9) return '\$${(marketCap / 1e9).toStringAsFixed(2)}B';
    if (marketCap >= 1e6) return '\$${(marketCap / 1e6).toStringAsFixed(2)}M';
    return '\$${marketCap.toStringAsFixed(0)}';
  }
}
