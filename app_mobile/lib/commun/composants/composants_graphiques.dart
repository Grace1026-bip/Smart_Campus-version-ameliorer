import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../coeur/theme/couleurs_application.dart';
import '../../donnees/modeles/modeles_faculte.dart';

const _chartPalette = [
  AppColors.primary,
  AppColors.cyan,
  AppColors.success,
  AppColors.warning,
  AppColors.violet,
  AppColors.danger,
];

class BarChartCard extends StatelessWidget {
  const BarChartCard({
    super.key,
    required this.title,
    required this.data,
    this.height = 210,
  });

  final String title;
  final List<ChartPoint> data;
  final double height;

  @override
  Widget build(BuildContext context) {
    return _ChartFrame(
      title: title,
      child: SizedBox(
        height: height,
        child: CustomPaint(
          painter: _BarChartPainter(data),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class LineChartCard extends StatelessWidget {
  const LineChartCard({
    super.key,
    required this.title,
    required this.data,
    this.height = 210,
  });

  final String title;
  final List<ChartPoint> data;
  final double height;

  @override
  Widget build(BuildContext context) {
    return _ChartFrame(
      title: title,
      child: SizedBox(
        height: height,
        child: CustomPaint(
          painter: _LineChartPainter(data),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class DonutChartCard extends StatelessWidget {
  const DonutChartCard({
    super.key,
    required this.title,
    required this.data,
    required this.centerLabel,
  });

  final String title;
  final List<ChartPoint> data;
  final String centerLabel;

  @override
  Widget build(BuildContext context) {
    return _ChartFrame(
      title: title,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 380;
          return Wrap(
            spacing: 18,
            runSpacing: 14,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: compact ? 160 : 190,
                height: compact ? 160 : 190,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      painter: _DonutPainter(data),
                      child: const SizedBox.expand(),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          centerLabel,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Text(
                          'total',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: compact ? constraints.maxWidth : 220,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < data.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: _chartPalette[i % _chartPalette.length],
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                data[i].label,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Text(
                              data[i].value.toStringAsFixed(0),
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ChartFrame extends StatelessWidget {
  const _ChartFrame({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.04),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  _BarChartPainter(this.data);

  final List<ChartPoint> data;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final axisPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    final maxValue = data.map((e) => e.value).reduce(math.max);
    final chartHeight = size.height - 36;
    final barArea = size.width / data.length;

    for (var i = 0; i < 4; i++) {
      final y = (chartHeight / 3) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), axisPaint);
    }

    for (var i = 0; i < data.length; i++) {
      final barWidth = math.min(42.0, barArea * 0.46);
      final x = (barArea * i) + (barArea - barWidth) / 2;
      final barHeight = (data[i].value / maxValue) * (chartHeight - 8);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, chartHeight - barHeight, barWidth, barHeight),
        const Radius.circular(6),
      );
      final paint = Paint()..color = _chartPalette[i % _chartPalette.length];
      canvas.drawRRect(rect, paint);
      _drawLabel(
        canvas,
        data[i].label,
        Offset(barArea * i, chartHeight + 10),
        Size(barArea, 20),
      );
    }
  }

  void _drawLabel(Canvas canvas, String label, Offset offset, Size size) {
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '...',
      textAlign: TextAlign.center,
    )..layout(maxWidth: size.width);
    painter.paint(
      canvas,
      Offset(offset.dx + (size.width - painter.width) / 2, offset.dy),
    );
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) =>
      oldDelegate.data != data;
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter(this.data);

  final List<ChartPoint> data;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final gridPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    final maxValue = data.map((e) => e.value).reduce(math.max);
    final minValue = data.map((e) => e.value).reduce(math.min);
    final chartHeight = size.height - 32;
    final stepX = size.width / (data.length - 1);

    for (var i = 0; i < 4; i++) {
      final y = (chartHeight / 3) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final path = Path();
    for (var i = 0; i < data.length; i++) {
      final range = math.max(1.0, maxValue - minValue);
      final normalized = (data[i].value - minValue) / range;
      final point = Offset(
        stepX * i,
        chartHeight - normalized * (chartHeight - 8),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawCircle(point, 4, Paint()..color = AppColors.primary);
      _drawLabel(
        canvas,
        data[i].label,
        Offset(stepX * i - 22, chartHeight + 10),
      );
    }

    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, paint);
  }

  void _drawLabel(Canvas canvas, String label, Offset offset) {
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '...',
    )..layout(maxWidth: 44);
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) =>
      oldDelegate.data != data;
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.data);

  final List<ChartPoint> data;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final total = data.fold<double>(0, (sum, item) => sum + item.value);
    if (total == 0) return;
    final rect = Offset.zero & size;
    var start = -math.pi / 2;
    final stroke = math.max(18.0, size.shortestSide * 0.12);

    for (var i = 0; i < data.length; i++) {
      final sweep = (data[i].value / total) * math.pi * 2;
      final paint = Paint()
        ..color = _chartPalette[i % _chartPalette.length]
        ..strokeWidth = stroke
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect.deflate(stroke / 2), start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.data != data;
}
