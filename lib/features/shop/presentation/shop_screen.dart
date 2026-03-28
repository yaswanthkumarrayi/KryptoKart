import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'store_session_screen.dart';

/// Supermarket data model
class SupermarketInfo {
  final String id;
  final String name;
  final String address;
  final String distance;
  final String rating;
  final String timing;
  final IconData icon;
  final Color accentColor;
  final bool isOpen;

  const SupermarketInfo({
    required this.id,
    required this.name,
    required this.address,
    required this.distance,
    required this.rating,
    required this.timing,
    required this.icon,
    required this.accentColor,
    this.isOpen = true,
  });
}

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  static const _stores = [
    SupermarketInfo(
      id: 'reliance-smart',
      name: 'Reliance Smart',
      address: 'Ameerpet, Hyderabad',
      distance: '0.5 km',
      rating: '4.3',
      timing: '7 AM – 11 PM',
      icon: Icons.storefront_rounded,
      accentColor: Color(0xFF0066FF),
    ),
    SupermarketInfo(
      id: 'dmart',
      name: 'DMart',
      address: 'Kukatpally, Hyderabad',
      distance: '1.2 km',
      rating: '4.5',
      timing: '9 AM – 10 PM',
      icon: Icons.shopping_bag_rounded,
      accentColor: Color(0xFF00C853),
    ),
    SupermarketInfo(
      id: 'bigbasket',
      name: 'BigBasket Now',
      address: 'Madhapur, Hyderabad',
      distance: '2.1 km',
      rating: '4.1',
      timing: '8 AM – 12 AM',
      icon: Icons.local_grocery_store_rounded,
      accentColor: Color(0xFFFF6D00),
    ),
    SupermarketInfo(
      id: 'more-mega',
      name: 'More Megastore',
      address: 'Begumpet, Hyderabad',
      distance: '3.0 km',
      rating: '4.0',
      timing: '8 AM – 10 PM',
      icon: Icons.store_rounded,
      accentColor: Color(0xFFAA00FF),
    ),
    SupermarketInfo(
      id: 'spar',
      name: 'SPAR Hypermarket',
      address: 'Kondapur, Hyderabad',
      distance: '3.5 km',
      rating: '4.2',
      timing: '9 AM – 11 PM',
      icon: Icons.local_mall_rounded,
      accentColor: Color(0xFFD50000),
    ),
    SupermarketInfo(
      id: 'ratnadeep',
      name: 'Ratnadeep Super Market',
      address: 'Jubilee Hills, Hyderabad',
      distance: '4.0 km',
      rating: '4.4',
      timing: '7 AM – 10 PM',
      icon: Icons.storefront_outlined,
      accentColor: Color(0xFFFFAB00),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Shop & Go'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header banner
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.accentGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Scan & Go',
                          style: AppTextStyles.title
                              .copyWith(color: AppColors.background)),
                      const SizedBox(height: 4),
                      Text(
                        'Walk in, scan items, pay & leave.\nNo queues, no cashier.',
                        style: AppTextStyles.caption.copyWith(
                            color: AppColors.background.withValues(alpha: 0.8)),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.qr_code_scanner_rounded,
                  color: AppColors.background,
                  size: 36,
                ),
              ],
            ),
          ).animate().fadeIn().slideY(begin: -0.1),

          // Section header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    color: AppColors.accent, size: 18),
                const SizedBox(width: 6),
                Text('Nearby Stores',
                    style: AppTextStyles.captionMedium
                        .copyWith(color: AppColors.accent)),
              ],
            ),
          ),

          // Store list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _stores.length,
              itemBuilder: (context, index) {
                final store = _stores[index];
                return _StoreCard(
                  store: store,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => StoreSessionScreen(store: store),
                      ),
                    );
                  },
                ).animate().fadeIn(delay: Duration(milliseconds: 80 * index));
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StoreCard extends StatelessWidget {
  final SupermarketInfo store;
  final VoidCallback onTap;

  const _StoreCard({required this.store, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // Store icon (no tinted glass backing)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Icon(store.icon, color: store.accentColor, size: 28),
            ),
            const SizedBox(width: 14),

            // Store info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(store.name,
                            style: AppTextStyles.bodyMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded,
                              color: AppColors.green, size: 14),
                          const SizedBox(width: 4),
                          Text(store.rating,
                              style: AppTextStyles.caption.copyWith(
                                  color: AppColors.green, fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(store.address, style: AppTextStyles.caption),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _chipInfo(Icons.directions_walk, store.distance),
                      const SizedBox(width: 10),
                      _chipInfo(Icons.access_time, store.timing),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: AppColors.accent, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _chipInfo(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: AppColors.textSecondary),
        const SizedBox(width: 3),
        Text(text,
            style: AppTextStyles.caption.copyWith(fontSize: 10)),
      ],
    );
  }
}
