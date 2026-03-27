import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class ApiService {
  late final Dio _dio;
  String? _authToken;

  ApiService() {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_authToken != null) {
          options.headers['Authorization'] = 'Bearer $_authToken';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          // Token expired — could auto-logout here
        }
        return handler.next(error);
      },
    ));

    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (o) => print('[API] $o'),
    ));
  }

  void setToken(String token) {
    _authToken = token;
  }

  void clearToken() {
    _authToken = null;
  }

  String? get token => _authToken;
  bool get isAuthenticated => _authToken != null;

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
  }

  Future<void> saveToken(String token) async {
    _authToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> removeToken() async {
    _authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // Generic request methods
  Future<Response> get(String url, {Map<String, dynamic>? queryParams}) async {
    return _dio.get(url, queryParameters: queryParams);
  }

  Future<Response> post(String url, {dynamic data}) async {
    return _dio.post(url, data: data);
  }

  Future<Response> put(String url, {dynamic data}) async {
    return _dio.put(url, data: data);
  }

  Future<Response> delete(String url) async {
    return _dio.delete(url);
  }

  // Auth methods
  Future<Map<String, dynamic>> register({
    required String name,
    required String phone,
    required String password,
    String? upiId,
  }) async {
    final response = await post(ApiConstants.register, data: {
      'name': name,
      'phone': phone,
      'password': password,
      'upiId': upiId,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) async {
    final response = await post(ApiConstants.login, data: {
      'phone': phone,
      'password': password,
    });
    return response.data;
  }

  // User methods
  Future<Map<String, dynamic>> getProfile() async {
    final response = await get(ApiConstants.profile);
    return response.data;
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final response = await put(ApiConstants.profile, data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> updateKyc(Map<String, dynamic> data) async {
    final response = await put(ApiConstants.kyc, data: data);
    return response.data;
  }

  // Transaction methods
  Future<Map<String, dynamic>> getTransactions({String? type, int limit = 50}) async {
    final params = <String, dynamic>{'limit': limit};
    if (type != null && type != 'all') params['type'] = type;
    final response = await get(ApiConstants.transactions, queryParams: params);
    return response.data;
  }

  Future<Map<String, dynamic>> createTransaction(Map<String, dynamic> data) async {
    final response = await post(ApiConstants.transactions, data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> getTransactionStats() async {
    final response = await get(ApiConstants.transactionStats);
    return response.data;
  }

  // Product methods
  Future<Map<String, dynamic>> getProducts({String? search}) async {
    final params = <String, dynamic>{};
    if (search != null) params['search'] = search;
    final response = await get(ApiConstants.products, queryParams: params);
    return response.data;
  }

  Future<Map<String, dynamic>> getProductByBarcode(String barcode) async {
    final response = await get(ApiConstants.productByBarcode(barcode));
    return response.data;
  }

  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> data) async {
    final response = await post(ApiConstants.products, data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> deleteProduct(String productId) async {
    final response = await delete('${ApiConstants.products}/$productId');
    return response.data;
  }

  // Cart methods
  Future<Map<String, dynamic>> getCart() async {
    final response = await get(ApiConstants.cart);
    return response.data;
  }

  Future<Map<String, dynamic>> addToCart(String productId, {int quantity = 1}) async {
    final response = await post(ApiConstants.cartAdd, data: {
      'productId': productId,
      'quantity': quantity,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> updateCartItem(String productId, int quantity) async {
    final response = await post(ApiConstants.cartUpdate, data: {
      'productId': productId,
      'quantity': quantity,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> removeFromCart(String productId) async {
    final response = await post(ApiConstants.cartRemove, data: {
      'productId': productId,
    });
    return response.data;
  }

  Future<void> clearCart() async {
    await delete(ApiConstants.cartClear);
  }

  // Watchlist methods
  Future<Map<String, dynamic>> getWatchlist() async {
    final response = await get(ApiConstants.watchlist);
    return response.data;
  }

  Future<Map<String, dynamic>> toggleWatchlist(String coinId) async {
    final response = await post(ApiConstants.watchlistToggle, data: {
      'coinId': coinId,
    });
    return response.data;
  }

  // Payment methods
  Future<Map<String, dynamic>> createPaymentOrder(int amountPaise) async {
    final response = await post(ApiConstants.createOrder, data: {
      'amount': amountPaise,
      'currency': 'INR',
    });
    return response.data;
  }

  Future<Map<String, dynamic>> verifyPayment({
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    final response = await post(ApiConstants.verifyPayment, data: {
      'razorpay_order_id': orderId,
      'razorpay_payment_id': paymentId,
      'razorpay_signature': signature,
    });
    return response.data;
  }

  // Settings methods
  Future<Map<String, dynamic>> getSettings() async {
    final response = await get(ApiConstants.settings);
    return response.data;
  }

  Future<Map<String, dynamic>> updateSettings(Map<String, dynamic> data) async {
    final response = await put(ApiConstants.settings, data: data);
    return response.data;
  }
}
