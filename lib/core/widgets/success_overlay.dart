import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import '../theme/kk_theme_context.dart';

class SuccessOverlay extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onDone;

  const SuccessOverlay({
    super.key,
    required this.title,
    required this.message,
    required this.onDone,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (ctx) => SuccessOverlay(
        title: title,
        message: message,
        onDone: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.txt;

    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.symmetric(horizontal: 40),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: p.accent.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: p.accent.withValues(alpha: 0.2),
              blurRadius: 40,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 160,
              width: 160,
              child: Animate(
                effects: [
                  ScaleEffect(
                    begin: const Offset(0.5, 0.5),
                    end: const Offset(1, 1),
                    duration: 600.ms,
                    curve: Curves.elasticOut,
                  ),
                ],
                child: Lottie.asset(
                  'assets/animations/crypto.json',
                  repeat: false,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: t.titleSmall.copyWith(color: p.accent),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
            const SizedBox(height: 8),
            Text(
              message,
              style: t.caption,
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),
            const SizedBox(height: 30),
            GestureDetector(
              onTap: onDone,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [p.accent, p.accentBlue]),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  'Finish',
                  style: TextStyle(
                    color: p.textOnAccentButton,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 800.ms).scale(begin: const Offset(0.8, 0.8)),
          ],
        ),
      ),
    );
  }
}
