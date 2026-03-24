import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  final double elevation;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final bool isFullWidth;
  final TextStyle? textStyle;
  final bool isLoading;

  const PrimaryButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.elevation = 8.0,
    this.borderRadius = 16.0,
    this.padding = const EdgeInsets.symmetric(vertical: 16),
    this.isFullWidth = true,
    this.textStyle,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onPressed != null && !isLoading;
    final Color primary = Theme.of(context).colorScheme.primary;
    final BorderRadius radius = BorderRadius.circular(borderRadius);

    final buttonChild = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLoading)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          )
        else if (icon != null)
          Icon(icon, color: Colors.white),
        if (icon != null || isLoading) const SizedBox(width: 8),
        Text(
          label,
          style: (textStyle ?? const TextStyle(fontWeight: FontWeight.w700))
              .copyWith(color: Colors.white),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        width: isFullWidth ? double.infinity : null,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              colors: isEnabled
                  ? [primary, const Color(0xFF7C3AED)]
                  : [Colors.grey.shade400, Colors.grey.shade500],
            ),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: isEnabled ? 0.35 : 0.1),
                blurRadius: elevation * 2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: isEnabled ? onPressed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              disabledBackgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: radius),
              minimumSize: isFullWidth ? const Size.fromHeight(52) : null,
              padding: padding,
            ),
            child: buttonChild,
          ),
        ),
      ),
    );
  }
}
