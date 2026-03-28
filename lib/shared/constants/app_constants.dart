class AppConstants {
  AppConstants._();

  static const String appName = 'KryptoKart';
  static const String tagline = 'Scan. Pay. Track.';

  static const Duration priceRefreshInterval = Duration(seconds: 30);
  static const Duration marketRefreshInterval = Duration(seconds: 60);
  static const Duration cacheTtl = Duration(seconds: 60);
  static const Duration apiTimeout = Duration(seconds: 10);

  static const int maxApiRetries = 2;
  static const int coinGeckoRateLimit = 50; // calls per minute

  static const List<String> defaultWatchlist = ['bitcoin', 'ethereum', 'solana', 'binancecoin', 'ripple'];

  static const String razorpayKeyId = 'rzp_test_S01qKJJ0ovAUGa';

  static const Map<String, String> cryptoSymbols = {
    'bitcoin': 'BTC',
    'ethereum': 'ETH',
    'solana': 'SOL',
    'binancecoin': 'BNB',
    'ripple': 'XRP',
  };
}
