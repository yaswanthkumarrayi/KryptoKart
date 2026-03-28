import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../models/coin_model.dart';

class CoinListTile extends StatelessWidget {
  final CoinModel coin;
  final bool isWatchlisted;
  final VoidCallback? onTap;
  final VoidCallback? onWatchlistTap;

  const CoinListTile({
    super.key,
    required this.coin,
    this.isWatchlisted = false,
    this.onTap,
    this.onWatchlistTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = coin.priceChange24h >= 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // Coin logo
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: coin.imageUrl,
                width: 36,
                height: 36,
                placeholder: (_, __) => Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.surface2,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      coin.symbol.substring(0, coin.symbol.length > 1 ? 2 : 1),
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  width: 36,
                  height: 36,
                  color: AppColors.surface2,
                  child: const Icon(Icons.currency_bitcoin, color: AppColors.accent, size: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Name and symbol
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    coin.symbol,
                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    coin.name,
                    style: AppTextStyles.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Price and change
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    coin.priceFormatted,
                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                  ),
                  Text(
                    coin.changeFormatted,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isPositive ? AppColors.green : AppColors.red,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Watchlist star
            GestureDetector(
              onTap: onWatchlistTap,
              child: Icon(
                isWatchlisted ? Icons.star_rounded : Icons.star_border_rounded,
                color: isWatchlisted ? AppColors.yellow : AppColors.textSecondary,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
