import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Local wishlist service with SharedPreferences persistence
/// This ensures wishlist works offline and syncs with backend when available
class WishlistService {
  static const String _wishlistKey = 'local_wishlist';

  List<String> _wishlist = [];
  bool _isInitialized = false;

  /// Get current wishlist (cached)
  List<String> get wishlist => List.unmodifiable(_wishlist);

  /// Initialize and load wishlist from local storage
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_wishlistKey);
      if (data != null) {
        final List<dynamic> decoded = jsonDecode(data);
        _wishlist = decoded.cast<String>();
      }
      _isInitialized = true;
    } catch (e) {
      _wishlist = [];
      _isInitialized = true;
    }
  }

  /// Check if coin is in wishlist
  bool isWishlisted(String coinId) {
    return _wishlist.contains(coinId);
  }

  /// Toggle coin in wishlist (returns new state)
  Future<bool> toggleWishlist(String coinId) async {
    await initialize();

    final isCurrentlyWishlisted = _wishlist.contains(coinId);

    if (isCurrentlyWishlisted) {
      _wishlist.remove(coinId);
    } else {
      _wishlist.add(coinId);
    }

    await _saveToStorage();
    return !isCurrentlyWishlisted;
  }

  /// Add coin to wishlist
  Future<void> addToWishlist(String coinId) async {
    await initialize();

    if (!_wishlist.contains(coinId)) {
      _wishlist.add(coinId);
      await _saveToStorage();
    }
  }

  /// Remove coin from wishlist
  Future<void> removeFromWishlist(String coinId) async {
    await initialize();

    if (_wishlist.contains(coinId)) {
      _wishlist.remove(coinId);
      await _saveToStorage();
    }
  }

  /// Get all wishlisted coin IDs
  Future<List<String>> getWishlist() async {
    await initialize();
    return List.unmodifiable(_wishlist);
  }

  /// Sync with backend wishlist (merge local + backend)
  Future<void> syncWithBackend(List<String> backendWishlist) async {
    await initialize();

    // Merge: keep all from both local and backend (union)
    final merged = {..._wishlist, ...backendWishlist}.toList();
    _wishlist = merged;
    await _saveToStorage();
  }

  /// Clear wishlist
  Future<void> clear() async {
    _wishlist = [];
    await _saveToStorage();
  }

  /// Save to local storage
  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_wishlistKey, jsonEncode(_wishlist));
    } catch (e) {
      // Silently fail - wishlist will still work in-memory
    }
  }
}
