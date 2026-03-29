import 'package:flutter/material.dart';
import '../../core/theme/kk_theme_context.dart';
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
    final p = context.palette;
    final t = context.txt;
    final isPositive = coin.priceChange24h >= 0;

    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: p.surface2,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                coin.symbol.length > 3 ? coin.symbol.substring(0, 3) : coin.symbol,
                style: t.captionMedium.copyWith(
                  color: p.accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${coin.symbol}/INR',
                  style: t.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  inrPrice != null ? '₹${_formatInrCompact(inrPrice!)}' : coin.priceFormatted,
                  style: t.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (isPositive ? p.green : p.red).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Text(
              coin.changeFormatted,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isPositive ? p.green : p.red,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
