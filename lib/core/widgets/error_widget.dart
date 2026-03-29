import 'package:flutter/material.dart';
import '../theme/kk_theme_context.dart';

class KkErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;

  const KkErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.icon = Icons.error_outline_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.txt;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: p.red.withValues(alpha: 0.6)),
            const SizedBox(height: 16),
            Text(
              message,
              style: t.body.copyWith(color: p.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: Icon(Icons.refresh, color: p.accent),
                label: Text(
                  'Retry',
                  style: t.bodyMedium.copyWith(color: p.accent),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: p.accent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class KkEmptyWidget extends StatelessWidget {
  final String message;
  final IconData icon;

  const KkEmptyWidget({
    super.key,
    required this.message,
    this.icon = Icons.inbox_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.txt;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: p.textSecondary.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              message,
              style: t.body.copyWith(color: p.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
