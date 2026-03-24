import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scannerFxController;

  @override
  void initState() {
    super.initState();
    _scannerFxController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scannerFxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF060812), Color(0xFF0E1121), Color(0xFF1A1433)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              children: [
                Row(
                  children: [
                    _glassIconButton(
                      icon: Icons.person_outline_rounded,
                      onTap: () => context.push('/settings'),
                    ),
                    Expanded(
                      child: Text(
                        'KryptoKart',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    _glassIconButton(
                      icon: Icons.notifications_none_rounded,
                      onTap: () =>
                          _showSoonSnack(context, 'No notifications yet'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _buildNeonScannerCard(context),
                      const SizedBox(height: 18),
                      _buildSmartShoppingCard(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _glassIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: const Color(0x281B233F),
            border: Border.all(color: AppTheme.cardBorderColor),
          ),
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildNeonScannerCard(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _scannerFxController,
      builder: (context, _) {
        final glow = 0.14 + (_scannerFxController.value * 0.22);
        return InkWell(
          onTap: () => context.push('/scan'),
          borderRadius: BorderRadius.circular(30),
          child: Ink(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: const LinearGradient(
                colors: [
                  Color(0x70231C44),
                  Color(0x70302757),
                  Color(0x703A2F68),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: AppTheme.cardBorderColor),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.2),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: AppTheme.neonColor.withValues(alpha: glow),
                  blurRadius: 26,
                  spreadRadius: 0.5,
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  height: 220,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppTheme.neonColor.withValues(alpha: 0.75),
                      width: 1.8,
                    ),
                  ),
                  child: Stack(
                    children: [
                      const _ScannerCorner(alignment: Alignment.topLeft),
                      const _ScannerCorner(alignment: Alignment.topRight),
                      const _ScannerCorner(alignment: Alignment.bottomLeft),
                      const _ScannerCorner(alignment: Alignment.bottomRight),
                      Align(
                        alignment: Alignment(
                          0,
                          -1 + (_scannerFxController.value * 2),
                        ),
                        child: Container(
                          width: 190,
                          height: 2,
                          decoration: BoxDecoration(
                            color: AppTheme.neonColor.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.neonColor.withValues(
                                  alpha: 0.5,
                                ),
                                blurRadius: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Center(
                        child: Icon(
                          Icons.qr_code_scanner_rounded,
                          size: 60,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Tap to Scan & Pay',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'UPI • ETH • Universal QR',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSmartShoppingCard(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [Color(0x66332A58), Color(0x6644376F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppTheme.cardBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Shop & Go',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Scan products and checkout instantly',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => context.push('/store'),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('Enter Store'),
          ),
        ],
      ),
    );
  }

  void _showSoonSnack(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
  }
}

class _ScannerCorner extends StatelessWidget {
  final Alignment alignment;

  const _ScannerCorner({required this.alignment});

  @override
  Widget build(BuildContext context) {
    final bool isTop =
        alignment == Alignment.topLeft || alignment == Alignment.topRight;
    final bool isLeft =
        alignment == Alignment.topLeft || alignment == Alignment.bottomLeft;

    return Align(
      alignment: alignment,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          border: Border(
            top: isTop
                ? BorderSide(
                    color: AppTheme.neonColor.withValues(alpha: 0.95),
                    width: 3.2,
                  )
                : BorderSide.none,
            bottom: !isTop
                ? BorderSide(
                    color: AppTheme.neonColor.withValues(alpha: 0.95),
                    width: 3.2,
                  )
                : BorderSide.none,
            left: isLeft
                ? BorderSide(
                    color: AppTheme.neonColor.withValues(alpha: 0.95),
                    width: 3.2,
                  )
                : BorderSide.none,
            right: !isLeft
                ? BorderSide(
                    color: AppTheme.neonColor.withValues(alpha: 0.95),
                    width: 3.2,
                  )
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
