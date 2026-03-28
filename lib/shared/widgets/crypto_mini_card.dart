import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/glass_card.dart';
import '../models/coin_model.dart';

class CryptoMiniCard extends StatelessWidget {
  final CoinModel coin;
  final double? inrPrice;
  final VoidCallback? onTap;

  const CryptoMiniCard({
    super.key,
    required this.coin,
    this.inrPrice,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = coin.priceChange24h >= 0;

    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          // Coin icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                coin.symbol.length > 3 ? coin.symbol.substring(0, 3) : coin.symbol,
                style: AppTextStyles.captionMedium.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.bold,
                ),
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
                  '${coin.symbol}/INR',
                  style: AppTextStyles.bodyMedium,
                ),
                Text(
                  inrPrice != null ? '₹${_formatInrCompact(inrPrice!)}' : coin.priceFormatted,
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          // Change percentage
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (isPositive ? AppColors.green : AppColors.red).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Text(
              coin.changeFormatted,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isPositive ? AppColors.green : AppColors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatInrCompact(double value) {
    if (value >= 10000000) return '${(value / 10000000).toStringAsFixed(2)}Cr';
    if (value >= 100000) return '${(value / 100000).toStringAsFixed(2)}L';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(2)}K';
    return value.toStringAsFixed(2);
  }
}
