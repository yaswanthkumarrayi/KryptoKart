import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/theme/kk_theme_context.dart';

/// Line chart with reliable INR readout: shows the latest point by default and
/// updates on tap/drag. fl_chart's built-in tooltip clears on mobile tap-up;
/// this keeps a visible value via [touchCallback] + state.
class InteractiveInrLineChart extends StatefulWidget {
  const InteractiveInrLineChart({
    super.key,
    required this.spots,
    required this.lineColor,
    this.height = 160,
    this.showDragHint = false,
    this.showValueCaption = true,
  });

  final List<FlSpot> spots;
  final Color lineColor;
  final double height;
  final bool showDragHint;

  /// When false, only the chart and tooltips are shown (e.g. price already in parent header).
  final bool showValueCaption;

  @override
  State<InteractiveInrLineChart> createState() =>
      _InteractiveInrLineChartState();
}

class _InteractiveInrLineChartState extends State<InteractiveInrLineChart> {
  double? _displayY;

  static String _fmtInr(double y) {
    if (y >= 10000000) return '${(y / 10000000).toStringAsFixed(2)} Cr';
    if (y >= 100000) return '${(y / 100000).toStringAsFixed(2)} L';
    if (y >= 1000) return '${(y / 1000).toStringAsFixed(2)} K';
    return y.toStringAsFixed(2);
  }

  @override
  void initState() {
    super.initState();
    _syncDefaultY();
  }

  @override
  void didUpdateWidget(InteractiveInrLineChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.spots != widget.spots) {
      _syncDefaultY();
    }
  }

  void _syncDefaultY() {
    final spots = widget.spots;
    if (spots.isEmpty) {
      _displayY = null;
    } else {
      _displayY = spots.last.y;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.txt;
    final spots = widget.spots;
    if (spots.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: Center(
          child: Text(
            'No chart data',
            style: t.caption.copyWith(color: p.textSecondary),
          ),
        ),
      );
    }

    final y = _displayY ?? spots.last.y;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showValueCaption) ...[
          Text(
            '₹${_fmtInr(y)}',
            textAlign: TextAlign.center,
            style: t.bodyMedium.copyWith(
              color: p.accent,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (widget.showDragHint) ...[
            const SizedBox(height: 4),
            Text(
              'Tap or drag along the line',
              textAlign: TextAlign.center,
              style: t.caption.copyWith(
                fontSize: 10,
                color: p.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 8),
        ] else if (widget.showDragHint) ...[
          Text(
            'Tap or drag for price',
            textAlign: TextAlign.center,
            style: t.caption.copyWith(
              fontSize: 10,
              color: p.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
        ],
        SizedBox(
          height: widget.height,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: const FlTitlesData(show: false),
              lineTouchData: LineTouchData(
                enabled: true,
                handleBuiltInTouches: true,
                touchSpotThreshold: 48,
                touchCallback: (event, response) {
                  final touched = response?.lineBarSpots;
                  if (touched != null && touched.isNotEmpty) {
                    setState(() => _displayY = touched.first.y);
                  }
                },
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => p.surface2,
                  getTooltipItems: (List<LineBarSpot> touchedSpots) {
                    return touchedSpots
                        .map(
                          (s) => LineTooltipItem(
                            '₹${_fmtInr(s.y)}',
                            TextStyle(
                              color: p.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                        .toList();
                  },
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: widget.lineColor,
                  barWidth: 2.5,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        widget.lineColor.withValues(alpha: 0.3),
                        widget.lineColor.withValues(alpha: 0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ],
            ),
            duration: Duration.zero,
          ),
        ),
      ],
    );
  }
}
