import 'dart:math' show min, max;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../database/database.dart';
import '../providers/analytics_provider.dart';
import '../providers/widget_manager_provider.dart';

// ─── Entry Point ─────────────────────────────────────────────────────────────

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => AnalyticsProvider(ctx.read<AppDatabase>()),
      child: const _AnalyticsBody(),
    );
  }
}

// ─── Main Body with Tabs ─────────────────────────────────────────────────────

class _AnalyticsBody extends StatelessWidget {
  const _AnalyticsBody();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnalyticsProvider>();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Analytics'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: () => context.read<AnalyticsProvider>().loadData(),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.timeline), text: 'Timeline'),
              Tab(icon: Icon(Icons.bar_chart), text: 'Charts'),
              Tab(icon: Icon(Icons.grid_on), text: 'Correlation'),
            ],
          ),
        ),
        body: provider.loading
            ? const Center(child: CircularProgressIndicator())
            : provider.error != null
                ? _ErrorView(
                    error: provider.error!,
                    onRetry: () => context.read<AnalyticsProvider>().loadData(),
                  )
                : const TabBarView(
                    children: [
                      _TimelineTab(),
                      _ChartsTab(),
                      _CorrelationTab(),
                    ],
                  ),
      ),
    );
  }
}

// ─── Error View ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 12),
            Text('Error: $error',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Timeline Tab ─────────────────────────────────────────────────────────────

class _TimelineTab extends StatelessWidget {
  const _TimelineTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnalyticsProvider>();
    final timeline = provider.timeline;

    if (timeline.isEmpty) {
      return _EmptyState(
        icon: Icons.timeline,
        message: 'No events yet.',
        subtitle: 'Start tracking on the Track tab.',
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive: wide layout shows more info per row
        final isWide = constraints.maxWidth >= 600;

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          itemCount: timeline.length,
          separatorBuilder: (_, __) => const SizedBox(height: 4),
          itemBuilder: (context, index) {
            final item = timeline[index];
            return _EventTile(item: item, isWide: isWide);
          },
        );
      },
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.item, required this.isWide});
  final EventWithWidget item;
  final bool isWide;

  IconData _iconForType(String type) {
    switch (type) {
      case 'slider':
        return Icons.linear_scale;
      case 'checkbox':
        return Icons.check_box_outlined;
      default:
        return Icons.pin_outlined;
    }
  }

  String _formatValue(TrackingEvent event, String fieldType) {
    switch (fieldType) {
      case 'checkbox':
        return event.value == 'true' ? '✓ Yes' : '✗ No';
      case 'slider':
        final v = double.tryParse(event.value);
        return v != null ? v.toStringAsFixed(1) : event.value;
      default:
        return event.value;
    }
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(eventDay).inDays;

    final timeStr = DateFormat('HH:mm').format(dt);
    if (diff == 0) return 'Today $timeStr';
    if (diff == 1) return 'Yesterday $timeStr';
    return DateFormat('MMM d, y • HH:mm').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final event = item.event;
    final widget = item.widget;

    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // Field type icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_iconForType(widget.fieldType),
                  color: cs.onPrimaryContainer, size: 18),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: isWide
                  ? Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            widget.name,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            _formatValue(event, widget.fieldType),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: cs.primary),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            _formatTimestamp(event.timestamp),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: cs.outline),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.name,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              _formatValue(event, widget.fieldType),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                      color: cs.primary,
                                      fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatTimestamp(event.timestamp),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: cs.outline),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),

            // Delete button
            IconButton(
              icon: Icon(Icons.delete_outline, color: cs.error, size: 20),
              tooltip: 'Delete event',
              onPressed: () => _confirmDelete(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final provider = context.read<AnalyticsProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Event?'),
        content: Text(
            'Remove "${item.widget.name}" event from ${DateFormat('MMM d, y HH:mm').format(item.event.timestamp)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await provider.deleteEvent(item.event.id, item.widget.id);
    }
  }
}

// ─── Charts Tab ───────────────────────────────────────────────────────────────

class _ChartsTab extends StatelessWidget {
  const _ChartsTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnalyticsProvider>();
    final widgets = provider.widgets;

    if (widgets.isEmpty) {
      return _EmptyState(
        icon: Icons.bar_chart,
        message: 'No widgets yet.',
        subtitle: 'Create widgets on the Widgets tab.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widgets.length,
      itemBuilder: (context, i) {
        final w = widgets[i];
        final events = provider.eventsForWidget(w.id);
        return _WidgetChartCard(widget: w, events: events);
      },
    );
  }
}

class _WidgetChartCard extends StatelessWidget {
  const _WidgetChartCard({required this.widget, required this.events});
  final CustomWidget widget;
  final List<TrackingEvent> events;

  IconData get _icon {
    switch (widget.fieldType) {
      case 'slider':
        return Icons.linear_scale;
      case 'checkbox':
        return Icons.check_box_outlined;
      default:
        return Icons.pin_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ft = FieldType.fromDb(widget.fieldType);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(_icon,
                    color: Theme.of(context).colorScheme.primary, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.name,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Chip(
                  label: Text(ft.label, style: const TextStyle(fontSize: 11)),
                  padding: EdgeInsets.zero,
                  labelPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  backgroundColor:
                      Theme.of(context).colorScheme.secondaryContainer,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${events.length} event${events.length == 1 ? '' : 's'}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.outline),
            ),
            const SizedBox(height: 16),

            // Chart
            if (events.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('No data yet')),
              )
            else
              SizedBox(
                height: 200,
                child: ft == FieldType.checkbox
                    ? _CheckboxChart(events: events)
                    : _LineChartWidget(
                        events: events,
                        isSlider: ft == FieldType.slider,
                      ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LineChartWidget extends StatelessWidget {
  const _LineChartWidget({required this.events, required this.isSlider});
  final List<TrackingEvent> events;
  final bool isSlider;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Sort ascending for chart
    final sorted = [...events]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final spots = <FlSpot>[];
    for (int i = 0; i < sorted.length; i++) {
      final v = double.tryParse(sorted[i].value);
      if (v != null) spots.add(FlSpot(i.toDouble(), v));
    }

    if (spots.isEmpty) {
      return const Center(child: Text('No numeric data'));
    }

    double minY = spots.map((s) => s.y).reduce(min);
    double maxY = spots.map((s) => s.y).reduce(max);

    if (isSlider) {
      minY = 0;
      maxY = 100;
    } else if (minY == maxY) {
      minY = minY - 1;
      maxY = maxY + 1;
    } else {
      final pad = (maxY - minY) * 0.12;
      minY -= pad;
      maxY += pad;
    }

    final maxX = spots.length <= 1 ? 1.0 : (spots.length - 1).toDouble();

    // Determine bottom-axis label interval
    final interval = (spots.length <= 7)
        ? 1.0
        : (spots.length / 5).ceilToDouble();

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: maxX,
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: spots.length > 2,
            color: cs.primary,
            barWidth: 2,
            belowBarData: BarAreaData(
              show: true,
              color: cs.primary.withAlpha(30),
            ),
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) =>
                  FlDotCirclePainter(
                radius: spots.length <= 20 ? 4 : 2,
                color: cs.primary,
                strokeWidth: 1,
                strokeColor: cs.surface,
              ),
            ),
          ),
        ],
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (value, meta) {
                // Skip non-meaningful values
                if (value == meta.min || value == meta.max) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    value == value.truncateToDouble()
                        ? value.toInt().toString()
                        : value.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 10,
                      color: cs.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.right,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: interval,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final idx = value.round();
                if (idx < 0 || idx >= sorted.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    DateFormat('M/d').format(sorted[idx].timestamp),
                    style: TextStyle(
                      fontSize: 9,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: cs.outlineVariant.withAlpha(80),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(color: cs.outlineVariant, width: 1),
            left: BorderSide(color: cs.outlineVariant, width: 1),
          ),
        ),
      ),
    );
  }
}

class _CheckboxChart extends StatelessWidget {
  const _CheckboxChart({required this.events});
  final List<TrackingEvent> events;

  @override
  Widget build(BuildContext context) {
    final trueCount =
        events.where((e) => e.value.toLowerCase() == 'true').length;
    final falseCount = events.length - trueCount;

    if (trueCount == 0 && falseCount == 0) {
      return const Center(child: Text('No data'));
    }

    final cs = Theme.of(context).colorScheme;

    // If all same value, show a simple message + pie
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              sections: [
                if (trueCount > 0)
                  PieChartSectionData(
                    value: trueCount.toDouble(),
                    title: 'Yes\n$trueCount',
                    color: Colors.green.shade400,
                    radius: 70,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                if (falseCount > 0)
                  PieChartSectionData(
                    value: falseCount.toDouble(),
                    title: 'No\n$falseCount',
                    color: cs.error.withAlpha(200),
                    radius: 70,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
              ],
              sectionsSpace: 3,
              centerSpaceRadius: 30,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LegendItem(
                color: Colors.green.shade400,
                label: 'Yes',
                count: trueCount,
                total: events.length,
              ),
              const SizedBox(height: 8),
              _LegendItem(
                color: cs.error.withAlpha(200),
                label: 'No',
                count: falseCount,
                total: events.length,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    required this.count,
    required this.total,
  });
  final Color color;
  final String label;
  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (count / total * 100).toStringAsFixed(0) : '0';
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            Text('$count ($pct%)',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Theme.of(context).colorScheme.outline)),
          ],
        ),
      ],
    );
  }
}

// ─── Correlation Tab ─────────────────────────────────────────────────────────

class _CorrelationTab extends StatefulWidget {
  const _CorrelationTab();

  @override
  State<_CorrelationTab> createState() => _CorrelationTabState();
}

class _CorrelationTabState extends State<_CorrelationTab> {
  int? _expandedWidgetId1;
  int? _expandedWidgetId2;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnalyticsProvider>();
    final widgets = provider.widgets;

    if (widgets.isEmpty) {
      return _EmptyState(
        icon: Icons.grid_on,
        message: 'No widgets yet.',
        subtitle: 'Create widgets on the Widgets tab.',
      );
    }

    if (widgets.length < 2) {
      return _EmptyState(
        icon: Icons.grid_on,
        message: 'Need at least 2 widgets.',
        subtitle: 'Create more widgets to see correlations.',
      );
    }

    // Check if any correlation can be computed
    bool anyCorrelation = false;
    for (int i = 0; i < widgets.length; i++) {
      for (int j = i + 1; j < widgets.length; j++) {
        if (provider.correlationBetween(
                widgets[i].id, widgets[j].id,
                minPoints: 5) !=
            null) {
          anyCorrelation = true;
          break;
        }
      }
      if (anyCorrelation) break;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info card
          Card(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: Theme.of(context).colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pearson correlation between widgets (requires ≥5 overlapping days). '
                      'Green = positive, Red = negative, Grey = insufficient data.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (!anyCorrelation)
            _EmptyState(
              icon: Icons.hourglass_empty,
              message: 'Not enough data for correlations.',
              subtitle:
                  'Track at least 5 overlapping days across 2+ widgets.',
            )
          else ...[
            // Heatmap Grid
            Text(
              'Correlation Matrix',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _CorrelationHeatmap(
              widgets: widgets,
              provider: provider,
              onCellTap: (id1, id2) {
                setState(() {
                  if (_expandedWidgetId1 == id1 &&
                      _expandedWidgetId2 == id2) {
                    _expandedWidgetId1 = null;
                    _expandedWidgetId2 = null;
                  } else {
                    _expandedWidgetId1 = id1;
                    _expandedWidgetId2 = id2;
                  }
                });
              },
            ),

            // Expanded detail
            if (_expandedWidgetId1 != null && _expandedWidgetId2 != null)
              _CorrelationDetail(
                widgetId1: _expandedWidgetId1!,
                widgetId2: _expandedWidgetId2!,
                provider: provider,
                widgets: widgets,
              ),
          ],
        ],
      ),
    );
  }
}

class _CorrelationHeatmap extends StatelessWidget {
  const _CorrelationHeatmap({
    required this.widgets,
    required this.provider,
    required this.onCellTap,
  });
  final List<CustomWidget> widgets;
  final AnalyticsProvider provider;
  final void Function(int id1, int id2) onCellTap;

  Color _cellColor(CorrelationResult? result, ColorScheme cs) {
    if (result == null) return cs.surfaceContainerHighest;
    if (result.dataPoints == -1) {
      // Diagonal (self-correlation = 1.0)
      return cs.primaryContainer;
    }
    final r = result.value;
    if (r > 0.1) {
      final intensity = (r * 200).round().clamp(60, 220);
      return Color.fromARGB(255, 0, intensity, 60);
    } else if (r < -0.1) {
      final intensity = (r.abs() * 200).round().clamp(60, 220);
      return Color.fromARGB(255, intensity, 30, 30);
    }
    return cs.surfaceContainerHighest;
  }

  String _cellLabel(CorrelationResult? result) {
    if (result == null) return '—';
    if (result.dataPoints == -1) return '1.0';
    return result.value.toStringAsFixed(2);
  }

  Color _textColor(CorrelationResult? result, ColorScheme cs) {
    if (result == null) return cs.onSurfaceVariant;
    if (result.dataPoints == -1) return cs.onPrimaryContainer;
    final r = result.value;
    if (r.abs() > 0.1) return Colors.white;
    return cs.onSurfaceVariant;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final n = widgets.length;

    // Cell size responsive
    return LayoutBuilder(builder: (context, constraints) {
      final maxWidth = constraints.maxWidth;
      // Header column takes some space, rest split equally
      final headerWidth = 80.0;
      final cellSize = ((maxWidth - headerWidth) / n).clamp(40.0, 80.0);

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                SizedBox(width: headerWidth),
                ...widgets.map((w) => SizedBox(
                      width: cellSize,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 2, vertical: 4),
                        child: Text(
                          w.name,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )),
              ],
            ),

            // Data rows
            ...List.generate(n, (i) {
              return Row(
                children: [
                  // Row header
                  SizedBox(
                    width: headerWidth,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        widgets[i].name,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),

                  // Cells
                  ...List.generate(n, (j) {
                    final result = provider.correlationBetween(
                      widgets[i].id,
                      widgets[j].id,
                      minPoints: i == j ? 0 : 5,
                    );
                    final bgColor = _cellColor(result, cs);
                    final txtColor = _textColor(result, cs);
                    final isClickable = i != j && result != null;

                    return GestureDetector(
                      onTap: isClickable
                          ? () => onCellTap(widgets[i].id, widgets[j].id)
                          : null,
                      child: Container(
                        width: cellSize,
                        height: 44,
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(6),
                          border: isClickable
                              ? Border.all(
                                  color: cs.outline.withAlpha(60), width: 1)
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            _cellLabel(result),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: txtColor,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              );
            }),

            const SizedBox(height: 8),
            // Legend
            Row(
              children: [
                SizedBox(width: headerWidth),
                _LegendChip(color: const Color(0xFF00C03C), label: 'Positive'),
                const SizedBox(width: 8),
                _LegendChip(
                    color: const Color(0xFFDC1E1E), label: 'Negative'),
                const SizedBox(width: 8),
                _LegendChip(
                    color: cs.surfaceContainerHighest, label: 'No data'),
              ],
            ),
          ],
        ),
      );
    });
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _CorrelationDetail extends StatelessWidget {
  const _CorrelationDetail({
    required this.widgetId1,
    required this.widgetId2,
    required this.provider,
    required this.widgets,
  });
  final int widgetId1;
  final int widgetId2;
  final AnalyticsProvider provider;
  final List<CustomWidget> widgets;

  String _strengthLabel(double r) {
    final abs = r.abs();
    if (abs >= 0.7) return 'Strong';
    if (abs >= 0.4) return 'Moderate';
    if (abs >= 0.2) return 'Weak';
    return 'Very weak';
  }

  @override
  Widget build(BuildContext context) {
    final result =
        provider.correlationBetween(widgetId1, widgetId2, minPoints: 5);
    if (result == null) return const SizedBox.shrink();

    final w1 =
        widgets.where((w) => w.id == widgetId1).firstOrNull;
    final w2 =
        widgets.where((w) => w.id == widgetId2).firstOrNull;
    if (w1 == null || w2 == null) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    final r = result.value;
    final isPositive = r >= 0;
    final color = isPositive ? Colors.green.shade700 : cs.error;

    // Build scatter-like chart using daily averages
    final avgs1 = provider.dailyAverages(widgetId1);
    final avgs2 = provider.dailyAverages(widgetId2);
    final commonDays =
        avgs1.keys.toSet().intersection(avgs2.keys.toSet()).toList()
          ..sort();

    final spots = <FlSpot>[];
    for (final day in commonDays) {
      spots.add(FlSpot(avgs1[day]!, avgs2[day]!));
    }

    double minX = spots.isEmpty ? 0 : spots.map((s) => s.x).reduce(min);
    double maxX = spots.isEmpty ? 1 : spots.map((s) => s.x).reduce(max);
    double minY = spots.isEmpty ? 0 : spots.map((s) => s.y).reduce(min);
    double maxY = spots.isEmpty ? 1 : spots.map((s) => s.y).reduce(max);

    // Add padding
    final padX = (maxX - minX) * 0.15 + 0.5;
    final padY = (maxY - minY) * 0.15 + 0.5;
    minX -= padX;
    maxX += padX;
    minY -= padY;
    maxY += padY;

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.query_stats, color: color, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${w1.name} ↔ ${w2.name}',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Stats
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _StatChip(
                    label: 'r =',
                    value: r.toStringAsFixed(3),
                    color: color,
                  ),
                  _StatChip(
                    label: 'Strength',
                    value: _strengthLabel(r),
                    color: color,
                  ),
                  _StatChip(
                    label: 'Direction',
                    value: isPositive ? 'Positive ↗' : 'Negative ↘',
                    color: color,
                  ),
                  _StatChip(
                    label: 'Data points',
                    value: '${result.dataPoints} days',
                    color: cs.outline,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Scatter plot (as LineChart with hidden lines and only dots)
              if (spots.length >= 2) ...[
                Text(
                  'Scatter: ${w1.name} (x) vs ${w2.name} (y)',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: cs.outline),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 180,
                  child: LineChart(
                    LineChartData(
                      minX: minX,
                      maxX: maxX,
                      minY: minY,
                      maxY: maxY,
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: false,
                          color: Colors.transparent,
                          barWidth: 0,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, bar, index) =>
                                FlDotCirclePainter(
                              radius: 5,
                              color: color.withAlpha(180),
                              strokeWidth: 1,
                              strokeColor: color,
                            ),
                          ),
                        ),
                      ],
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          axisNameWidget: Text(w2.name,
                              style: const TextStyle(fontSize: 9)),
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 36,
                            getTitlesWidget: (value, meta) {
                              if (value == meta.min || value == meta.max) {
                                return const SizedBox.shrink();
                              }
                              return Text(
                                value.toStringAsFixed(1),
                                style: TextStyle(
                                    fontSize: 9, color: cs.onSurfaceVariant),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          axisNameWidget: Text(w1.name,
                              style: const TextStyle(fontSize: 9)),
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 24,
                            getTitlesWidget: (value, meta) {
                              if (value == meta.min || value == meta.max) {
                                return const SizedBox.shrink();
                              }
                              return Text(
                                value.toStringAsFixed(1),
                                style: TextStyle(
                                    fontSize: 9, color: cs.onSurfaceVariant),
                              );
                            },
                          ),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        getDrawingHorizontalLine: (v) => FlLine(
                          color: cs.outlineVariant.withAlpha(60),
                          strokeWidth: 1,
                        ),
                        getDrawingVerticalLine: (v) => FlLine(
                          color: cs.outlineVariant.withAlpha(60),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(
                            color: cs.outlineVariant, width: 1),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip(
      {required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Theme.of(context).colorScheme.outline)),
        Text(value,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.message,
    required this.subtitle,
  });
  final IconData icon;
  final String message;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 64,
                color: Theme.of(context).colorScheme.outline.withAlpha(120)),
            const SizedBox(height: 16),
            Text(message,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(subtitle,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(
                        color: Theme.of(context).colorScheme.outline),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
