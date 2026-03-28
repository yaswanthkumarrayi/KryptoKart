import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              Expanded(child: _buildNavItem(0, Icons.home_rounded, 'Home')),
              Expanded(child: _buildNavItem(1, Icons.shopping_bag_rounded, 'Shop')),
              _buildScanFab(),
              Expanded(child: _buildNavItem(3, Icons.receipt_long_rounded, 'Activity')),
              Expanded(child: _buildNavItem(4, Icons.person_rounded, 'Profile')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isActive = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                icon,
                color: isActive ? AppColors.accent : AppColors.textSecondary,
                size: 24,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? AppColors.accent : AppColors.textSecondary,
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildScanFab() {
    return GestureDetector(
      onTap: () => onTap(2),
      child: Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(
          gradient: AppColors.accentGradient,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.qr_code_scanner_rounded,
          color: AppColors.background,
          size: 28,
        ),
      ),
    );
  }
}
