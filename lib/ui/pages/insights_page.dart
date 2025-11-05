import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../controllers/analytics_controller.dart';
import '../../controllers/session_controller.dart';
import '../../core/localization/app_localizations.dart';
import '../../data/models/analytics.dart';
import '../../data/models/transaction.dart';
import '../widgets/sensitive_text.dart';
import '../widgets/transaction_preview_card.dart';

class InsightsPage extends StatelessWidget {
  const InsightsPage({
    super.key,
    required this.analyticsController,
    required this.sessionController,
  });

  final AnalyticsController analyticsController;
  final SessionController sessionController;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.translate('insightsTitle')),
      ),
      body: ValueListenableBuilder<AnalyticsSummary>(
        valueListenable: analyticsController.summaryNotifier,
        builder: (context, summary, _) {
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            children: [
              ValueListenableBuilder<AnalyticsRange>(
                valueListenable: analyticsController.rangeNotifier,
                builder: (context, range, __) {
                  return _RangeSelector(
                    selected: range,
                    onChanged: analyticsController.updateRange,
                    t: t,
                  );
                },
              ),
              const SizedBox(height: 16),
              _LineChartCard(
                summary: summary,
                privacyListenable: sessionController.privacyModeNotifier,
                t: t,
              ),
              const SizedBox(height: 16),
              _BarChartCard(summary: summary, t: t),
              const SizedBox(height: 16),
              _DonutChartCard(summary: summary, t: t),
              const SizedBox(height: 16),
              _HeatmapSection(
                analyticsController: analyticsController,
                sessionController: sessionController,
                t: t,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RangeSelector extends StatelessWidget {
  const _RangeSelector({
    required this.selected,
    required this.onChanged,
    required this.t,
  });

  final AnalyticsRange selected;
  final ValueChanged<AnalyticsRange> onChanged;
  final AppLocalizations t;

  @override
  Widget build(BuildContext context) {
    final labels = {
      AnalyticsRange.month: t.translate('insightsRangeMonth'),
      AnalyticsRange.quarter: t.translate('insightsRangeQuarter'),
      AnalyticsRange.year: t.translate('insightsRangeYear'),
    };

    return Wrap(
      spacing: 12,
      children: [
        for (final range in AnalyticsRange.values)
          ChoiceChip(
            label: Text(labels[range]!),
            selected: range == selected,
            onSelected: (_) => onChanged(range),
          ),
      ],
    );
  }
}

class _LineChartCard extends StatelessWidget {
  const _LineChartCard({
    required this.summary,
    required this.privacyListenable,
    required this.t,
  });

  final AnalyticsSummary summary;
  final ValueListenable<bool> privacyListenable;
  final AppLocalizations t;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final income = summary.totalIncome;
    final expense = summary.totalExpense;
    final net = income - expense;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.translate('insightsCashflowTitle'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: CustomPaint(
                painter: _DualLineChartPainter(
                  incomeSeries: summary.incomeSeries,
                  expenseSeries: summary.expenseSeries,
                  incomeColor: theme.colorScheme.primary,
                  expenseColor: theme.colorScheme.error,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    label: t.translate('analyticsIncomeLabel'),
                    value: income,
                    privacyListenable: privacyListenable,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricTile(
                    label: t.translate('analyticsExpenseLabel'),
                    value: expense,
                    privacyListenable: privacyListenable,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricTile(
                    label: t.translate('analyticsNetLabel'),
                    value: net,
                    privacyListenable: privacyListenable,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.privacyListenable,
  });

  final String label;
  final double value;
  final ValueListenable<bool> privacyListenable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium,
        ),
        const SizedBox(height: 6),
        SensitiveText(
          privacyListenable: privacyListenable,
          visibleText: value.toStringAsFixed(0),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _DualLineChartPainter extends CustomPainter {
  _DualLineChartPainter({
    required this.incomeSeries,
    required this.expenseSeries,
    required this.incomeColor,
    required this.expenseColor,
  });

  final List<ChartPoint> incomeSeries;
  final List<ChartPoint> expenseSeries;
  final Color incomeColor;
  final Color expenseColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (incomeSeries.isEmpty && expenseSeries.isEmpty) {
      return;
    }
    final all = [...incomeSeries, ...expenseSeries];
    final minX = all.map((e) => e.date.millisecondsSinceEpoch).reduce(math.min);
    final maxX = all.map((e) => e.date.millisecondsSinceEpoch).reduce(math.max);
    final maxY = all.map((e) => e.value).fold<double>(0, math.max);
    final minY = 0.0;
    final rangeX = (maxX - minX).toDouble();
    final rangeY = (maxY - minY) == 0 ? 1 : (maxY - minY);

    void drawSeries(List<ChartPoint> series, Color color) {
      if (series.isEmpty) return;
      final path = Path();
      for (var i = 0; i < series.length; i++) {
        final point = series[i];
        final dx = size.width *
            ((point.date.millisecondsSinceEpoch - minX) / rangeX.clamp(1, double.infinity));
        final dy = size.height -
            ((point.value - minY) / rangeY) * size.height;
        if (i == 0) {
          path.moveTo(dx, dy);
        } else {
          path.lineTo(dx, dy);
        }
      }
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(path, paint);
    }

    drawSeries(expenseSeries, expenseColor.withOpacity(0.85));
    drawSeries(incomeSeries, incomeColor.withOpacity(0.9));
  }

  @override
  bool shouldRepaint(covariant _DualLineChartPainter oldDelegate) {
    return oldDelegate.incomeSeries != incomeSeries ||
        oldDelegate.expenseSeries != expenseSeries;
  }
}

class _BarChartCard extends StatelessWidget {
  const _BarChartCard({required this.summary, required this.t});

  final AnalyticsSummary summary;
  final AppLocalizations t;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.translate('insightsNetTitle'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: CustomPaint(
                painter: _BarChartPainter(
                  series: summary.netSeries,
                  color: theme.colorScheme.primary,
                  negativeColor: theme.colorScheme.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  _BarChartPainter({
    required this.series,
    required this.color,
    required this.negativeColor,
  });

  final List<ChartPoint> series;
  final Color color;
  final Color negativeColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (series.isEmpty) {
      return;
    }
    final maxMagnitude = series
        .map((point) => point.value.abs())
        .fold<double>(0, math.max)
        .clamp(1, double.infinity);
    final barWidth = size.width / series.length;
    final zeroY = size.height / 2;
    final paint = Paint()..style = PaintingStyle.fill;

    for (var i = 0; i < series.length; i++) {
      final point = series[i];
      final normalized = (point.value / maxMagnitude) * (size.height / 2 - 8);
      final rect = Rect.fromLTWH(
        i * barWidth + barWidth * 0.1,
        point.value >= 0 ? zeroY - normalized : zeroY,
        barWidth * 0.8,
        point.value.abs() / maxMagnitude * (size.height / 2 - 8),
      );
      paint.color = point.value >= 0 ? color : negativeColor;
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)), paint);
    }

    final axisPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(0, zeroY), Offset(size.width, zeroY), axisPaint);
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return oldDelegate.series != series;
  }
}

class _DonutChartCard extends StatelessWidget {
  const _DonutChartCard({required this.summary, required this.t});

  final AnalyticsSummary summary;
  final AppLocalizations t;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = summary.categorySlices
        .fold<double>(0, (sum, slice) => sum + slice.value);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.translate('insightsCategoriesTitle'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: Center(
                child: CustomPaint(
                  size: const Size.square(180),
                  painter: _DonutChartPainter(summary.categorySlices),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (summary.categorySlices.isEmpty)
              Text(t.translate('analyticsEmptyCategories'))
            else
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  for (final slice in summary.categorySlices.take(6))
                    Chip(
                      avatar: CircleAvatar(
                        backgroundColor: slice.color,
                      ),
                      label: Text(
                        total == 0
                            ? slice.label
                            : '${slice.label} · ${(slice.value / total * 100).toStringAsFixed(0)}%',
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  _DonutChartPainter(this.slices);

  final List<CategorySlice> slices;

  @override
  void paint(Canvas canvas, Size size) {
    if (slices.isEmpty) {
      final paint = Paint()
        ..color = Colors.grey.withOpacity(0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 28;
      canvas.drawCircle(size.center(Offset.zero), size.width / 2.5, paint);
      return;
    }
    final total = slices.fold<double>(0, (sum, slice) => sum + slice.value);
    var start = -math.pi / 2;
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: size.width / 2.4,
    );
    for (final slice in slices) {
      final sweep = total == 0 ? 0 : (slice.value / total) * math.pi * 2;
      final paint = Paint()
        ..color = slice.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 28
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.slices != slices;
  }
}

class _HeatmapSection extends StatelessWidget {
  const _HeatmapSection({
    required this.analyticsController,
    required this.sessionController,
    required this.t,
  });

  final AnalyticsController analyticsController;
  final SessionController sessionController;
  final AppLocalizations t;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ValueListenableBuilder<List<DateTime>>(
      valueListenable: analyticsController.availableMonthsNotifier,
      builder: (context, months, _) {
        return ValueListenableBuilder<DateTime>(
          valueListenable: analyticsController.statementMonthNotifier,
          builder: (context, selectedMonth, __) {
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            t.translate('insightsHeatmapTitle'),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        DropdownButton<DateTime>(
                          value: selectedMonth,
                          items: [
                            for (final month in months)
                              DropdownMenuItem(
                                value: month,
                                child: Text(
                                  '${month.year}-${month.month.toString().padLeft(2, '0')}',
                                ),
                              ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              analyticsController.selectStatementMonth(value);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ValueListenableBuilder<List<HeatmapBucket>>(
                      valueListenable: analyticsController.heatmapNotifier,
                      builder: (context, buckets, ___) {
                        if (buckets.isEmpty) {
                          return Text(t.translate('insightsHeatmapEmpty'));
                        }
                        return _HeatmapCalendar(
                          buckets: buckets,
                          baseColor: theme.colorScheme.primary,
                          gridColor:
                              theme.colorScheme.onSurface.withOpacity(0.12),
                          onSelect: (bucket) => _showTransactions(context, bucket),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showTransactions(BuildContext context, HeatmapBucket bucket) {
    final t = AppLocalizations.of(context);
    if (bucket.transactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.translate('insightsHeatmapNoTransactions'))),
      );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.translate('insightsTransactionsForDay', params: {
                    'date': '${bucket.date.year}-${bucket.date.month.toString().padLeft(2, '0')}-${bucket.date.day.toString().padLeft(2, '0')}',
                  }),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: math.min(
                    320,
                    96.0 * bucket.transactions.length,
                  ),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: bucket.transactions.length,
                    itemBuilder: (context, index) {
                      final tx = bucket.transactions[index];
                      return TransactionPreviewCard(
                        transaction: tx,
                        privacyListenable: sessionController.privacyModeNotifier,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HeatmapCalendar extends StatelessWidget {
  const _HeatmapCalendar({
    required this.buckets,
    required this.baseColor,
    required this.gridColor,
    required this.onSelect,
  });

  final List<HeatmapBucket> buckets;
  final Color baseColor;
  final Color gridColor;
  final ValueChanged<HeatmapBucket> onSelect;

  @override
  Widget build(BuildContext context) {
    final monthStart = DateTime(
      buckets.first.date.year,
      buckets.first.date.month,
      1,
    );
    final firstWeekday = monthStart.weekday % 7;
    final days = buckets.length;
    final weeks = ((firstWeekday + days) / 7).ceil();

    return AspectRatio(
      aspectRatio: 7 / weeks,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cellWidth = constraints.maxWidth / 7;
          final cellHeight = constraints.maxHeight / weeks;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) {
              final column = (details.localPosition.dx / cellWidth).floor();
              final row = (details.localPosition.dy / cellHeight).floor();
              final index = row * 7 + column - firstWeekday;
              if (index >= 0 && index < buckets.length) {
                onSelect(buckets[index]);
              }
            },
            child: CustomPaint(
              painter: _HeatmapPainter(
                buckets: buckets,
                firstWeekday: firstWeekday,
                weeks: weeks,
                maxValue: buckets
                    .map((bucket) => bucket.total)
                    .fold<double>(0, math.max),
                baseColor: baseColor,
                gridColor: gridColor,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HeatmapPainter extends CustomPainter {
  _HeatmapPainter({
    required this.buckets,
    required this.firstWeekday,
    required this.weeks,
    required this.maxValue,
    required this.baseColor,
    required this.gridColor,
  });

  final List<HeatmapBucket> buckets;
  final int firstWeekday;
  final int weeks;
  final double maxValue;
  final Color baseColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    final cellWidth = size.width / 7;
    final cellHeight = size.height / weeks;
    final paint = Paint();

    for (var i = 0; i < buckets.length; i++) {
      final bucket = buckets[i];
      final index = i + firstWeekday;
      final row = index ~/ 7;
      final column = index % 7;
      final rect = Rect.fromLTWH(
        column * cellWidth + 4,
        row * cellHeight + 4,
        cellWidth - 8,
        cellHeight - 8,
      );
      final intensity = maxValue == 0 ? 0 : (bucket.total / maxValue);
      paint.color = baseColor.withOpacity(0.15 + 0.6 * intensity);
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));
      canvas.drawRRect(rrect, paint);
    }

    paint
      ..style = PaintingStyle.stroke
      ..color = gridColor
      ..strokeWidth = 1;
    for (var row = 0; row <= weeks; row++) {
      canvas.drawLine(
        Offset(0, row * cellHeight),
        Offset(size.width, row * cellHeight),
        paint,
      );
    }
    for (var col = 0; col <= 7; col++) {
      canvas.drawLine(
        Offset(col * cellWidth, 0),
        Offset(col * cellWidth, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HeatmapPainter oldDelegate) {
    return oldDelegate.buckets != buckets;
  }
}
