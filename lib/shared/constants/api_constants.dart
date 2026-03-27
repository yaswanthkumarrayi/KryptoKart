class ApiConstants {
  ApiConstants._();

  // Backend base URL — change to your server IP for physical device
  static const String backendBase = 'http://10.2.16.67:4000'; // Physical device
  // static const String backendBase = 'http://10.0.2.2:4000'; // Android emulator
  // static const String backendBase = 'http://localhost:4000'; // Web/Desktop

  // Auth
  static const String register = '$backendBase/api/auth/register';
  static const String login = '$backendBase/api/auth/login';

  // User
  static const String profile = '$backendBase/api/user/profile';
  static const String kyc = '$backendBase/api/user/kyc';
  static const String balance = '$backendBase/api/user/balance';

  // Transactions
  static const String transactions = '$backendBase/api/transactions';
  static const String transactionStats = '$backendBase/api/transactions/stats';

  // Products
  static const String products = '$backendBase/api/products';
  static String productByBarcode(String barcode) =>
      '$backendBase/api/products/barcode/$barcode';

  // Cart
  static const String cart = '$backendBase/api/cart';
  static const String cartAdd = '$backendBase/api/cart/add';
  static const String cartUpdate = '$backendBase/api/cart/update';
  static const String cartRemove = '$backendBase/api/cart/remove';
  static const String cartClear = '$backendBase/api/cart/clear';

  // Watchlist
  static const String watchlist = '$backendBase/api/watchlist';
  static const String watchlistToggle = '$backendBase/api/watchlist/toggle';

  // Payments
  static const String createOrder = '$backendBase/api/payments/create-order';
  static const String verifyPayment = '$backendBase/api/payments/verify';

  // Settings
  static const String settings = '$backendBase/api/settings';

  // CoinGecko
  static const String coinGeckoBase = 'https://api.coingecko.com/api/v3';

  static String marketsEndpoint({String currency = 'usd', int perPage = 10}) =>
      '$coinGeckoBase/coins/markets?vs_currency=$currency&order=market_cap_desc&per_page=$perPage&page=1&sparkline=true&price_change_percentage=24h';

  static String marketChartEndpoint(String coinId, {int days = 7}) =>
      '$coinGeckoBase/coins/$coinId/market_chart?vs_currency=usd&days=$days';

  static String simplePriceEndpoint(List<String> coinIds) =>
      '$coinGeckoBase/simple/price?ids=${coinIds.join(',')}&vs_currencies=inr,usd&include_24hr_change=true';
}
