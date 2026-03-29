import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/kk_theme_context.dart';

class ShimmerLoader extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerLoader({
    super.key,
    this.width = double.infinity,
    this.height = 80,
    this.borderRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Shimmer.fromColors(
      baseColor: p.surface,
      highlightColor: p.surface2,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }

  static Widget list({int count = 3, double itemHeight = 80}) {
    return Column(
      children: List.generate(
        count,
        (index) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: ShimmerLoader(height: itemHeight),
        ),
      ),
    );
  }

  static Widget card({double height = 160}) {
    return ShimmerLoader(height: height);
  }
}
