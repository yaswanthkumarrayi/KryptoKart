import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/shimmer_loader.dart';
import '../../../core/service_locator.dart';
import '../../../shared/services/coingecko_service.dart';
import '../../../shared/services/wishlist_service.dart';
import '../../../shared/models/coin_model.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final _wishlistService = sl<WishlistService>();
  final _coinGeckoService = sl<CoinGeckoService>();

  List<CoinModel> _wishlistedCoins = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWishlist();
  }

  Future<void> _loadWishlist() async {
    setState(() => _isLoading = true);

    try {
      final wishlistIds = await _wishlistService.getWishlist();

      if (wishlistIds.isEmpty) {
        setState(() {
          _wishlistedCoins = [];
          _isLoading = false;
        });
        return;
      }

      // Fetch all market coins and filter by wishlist
      final allCoins = await _coinGeckoService.fetchMarkets(perPage: 100);
      final wishlisted = allCoins
          .where((c) => wishlistIds.contains(c.id))
          .toList();

      setState(() {
        _wishlistedCoins = wishlisted;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _wishlistedCoins = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _removeFromWishlist(String coinId) async {
    await _wishlistService.removeFromWishlist(coinId);
    setState(() {
      _wishlistedCoins.removeWhere((c) => c.id == coinId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            const Icon(Icons.star_rounded, color: AppColors.yellow, size: 24),
            const SizedBox(width: 8),
            Text(
              'Wishlist',
              style: AppTextStyles.title.copyWith(color: AppColors.accent),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: _isLoading
          ? _buildShimmer()
          : _wishlistedCoins.isEmpty
          ? _buildEmptyState()
          : _buildContent(),
    );
  }

  Widget _buildShimmer() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ShimmerLoader.card(height: 80),
          const SizedBox(height: 12),
          ShimmerLoader.card(height: 80),
          const SizedBox(height: 12),
          ShimmerLoader.card(height: 80),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.yellow.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(
              Icons.star_border_rounded,
              color: AppColors.yellow,
              size: 50,
            ),
          ),
          const SizedBox(height: 24),
          Text('No Wishlisted Items', style: AppTextStyles.titleSmall),
          const SizedBox(height: 8),
          Text(
            'Add coins to your wishlist by tapping\nthe star icon on any coin.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => context.go('/home/markets'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: AppColors.accentGradient,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Text(
                'Browse Markets',
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: _loadWishlist,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _wishlistedCoins.length,
        itemBuilder: (context, index) {
          final coin = _wishlistedCoins[index];
          return _buildCoinCard(coin, index);
        },
      ),
    );
  }

  Widget _buildCoinCard(CoinModel coin, int index) {
    final isPositive = coin.priceChange24h >= 0;

    return GestureDetector(
      onTap: () => context.push('/coin/${coin.id}'),
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: GlassCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Coin image
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: coin.imageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          coin.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                            child: Text(
                              coin.symbol.substring(
                                0,
                                coin.symbol.length > 2 ? 2 : coin.symbol.length,
                              ),
                              style: AppTextStyles.captionMedium.copyWith(
                                color: AppColors.accent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          coin.symbol.substring(
                            0,
                            coin.symbol.length > 2 ? 2 : coin.symbol.length,
                          ),
                          style: AppTextStyles.captionMedium.copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              // Coin info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      coin.name,
                      style: AppTextStyles.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      coin.symbol.toUpperCase(),
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              // Price and change
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(coin.priceFormatted, style: AppTextStyles.bodyMedium),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: (isPositive ? AppColors.green : AppColors.red)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      '${isPositive ? '+' : ''}${coin.priceChange24h.toStringAsFixed(2)}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isPositive ? AppColors.green : AppColors.red,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              // Remove button
              GestureDetector(
                onTap: () => _removeFromWishlist(coin.id),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.yellow.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.star_rounded,
                    color: AppColors.yellow,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ).animate(delay: Duration(milliseconds: 50 * index)).fadeIn().slideX(begin: 0.05),
    );
  }
}
