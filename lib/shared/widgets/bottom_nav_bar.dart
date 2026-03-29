import 'package:flutter/material.dart';
import '../../core/theme/kk_theme_context.dart';

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
    final p = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(top: BorderSide(color: p.border, width: 1)),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              Expanded(child: _buildNavItem(context, 0, Icons.home_rounded, 'Home')),
              Expanded(child: _buildNavItem(context, 1, Icons.shopping_bag_rounded, 'Shop')),
              _buildScanFab(context),
              Expanded(child: _buildNavItem(context, 3, Icons.receipt_long_rounded, 'Activity')),
              Expanded(child: _buildNavItem(context, 4, Icons.person_rounded, 'Profile')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, IconData icon, String label) {
    final p = context.palette;
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
              color: isActive ? p.accent : p.textSecondary,
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
              color: isActive ? p.accent : p.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanFab(BuildContext context) {
    final p = context.palette;
    return GestureDetector(
      onTap: () => onTap(2),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: p.accentGradient,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.qr_code_scanner_rounded,
          color: p.textOnAccentButton,
          size: 28,
        ),
      ),
    );
  }
}
