import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../providers/marked_days_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/widget_manager_provider.dart' show FieldType;

// ─── Date helpers (kept local, no locale initialization required) ───────────

const List<String> _germanMonths = [
  'Januar', 'Februar', 'März', 'April', 'Mai', 'Juni',
  'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember',
];

const List<String> _englishMonths = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

const List<String> _germanWeekdays = [
  'Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So',
];

const List<String> _englishWeekdays = [
  'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
];

String _formatMonthTitle(DateTime day, DateFormatPref pref) {
  final months =
      pref == DateFormatPref.german ? _germanMonths : _englishMonths;
  return '${months[day.month - 1]} ${day.year}';
}

String _formatWeekday(DateTime day, DateFormatPref pref) {
  final weekdays =
      pref == DateFormatPref.german ? _germanWeekdays : _englishWeekdays;
  return weekdays[day.weekday - 1];
}

// ─── Entry Point ─────────────────────────────────────────────────────────────
//
// Reusable content widget for the "Days" feature (calendar + evaluation).
// Intentionally has no Scaffold/AppBar of its own – it is embedded as a tab
// inside the Analytics screen, so it only provides the body content.
// The widget keeps its state (selected calendar month, scroll position) alive
// across tab switches via [AutomaticKeepAliveClientMixin].

class MarkedDaysView extends StatefulWidget {
  const MarkedDaysView({super.key});

  @override
  State<MarkedDaysView> createState() => _MarkedDaysViewState();
}

class _MarkedDaysViewState extends State<MarkedDaysView>
    with AutomaticKeepAliveClientMixin {
  late DateTime _focusedDay;
  late DateTime _selectedDay;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedDay = now;
    _selectedDay = now;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final provider = context.watch<MarkedDaysProvider>();

    if (provider.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null) {
      return _ErrorView(
        error: provider.error!,
        onRetry: () => context.read<MarkedDaysProvider>().loadData(),
      );
    }
    return _buildContent(context, provider);
  }

  Widget _buildContent(BuildContext context, MarkedDaysProvider provider) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildCalendarCard(context, provider),
            const SizedBox(height: 16),
            _HighlightsSection(
              highlights: provider.highlights,
              hasMarkedDays: provider.markedDaysCount > 0,
              analyzing: provider.analyzing,
            ),
            const SizedBox(height: 16),
            _ComparisonSection(
              comparisons: provider.comparisons,
              hasMarkedDays: provider.markedDaysCount > 0,
              analyzing: provider.analyzing,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarCard(BuildContext context, MarkedDaysProvider provider) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final settings = context.watch<ThemeProvider>();
    final datePref = settings.dateFormat;

    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Column(
          children: [
            TableCalendar<bool>(
              firstDay: DateTime(now.year - 5, 1, 1),
              lastDay: DateTime(now.year + 5, 12, 31),
              focusedDay: _focusedDay,
              startingDayOfWeek: StartingDayOfWeek.monday,
              calendarFormat: CalendarFormat.month,
              // Only horizontal swiping between months – vertical drags pass
              // through to the surrounding scroll view (whole screen scrolls
              // as one unit instead of the calendar swallowing gestures).
              availableGestures: AvailableGestures.horizontalSwipe,
              availableCalendarFormats: const {
                CalendarFormat.month: 'Month',
              },
              headerStyle: HeaderStyle(
                titleCentered: true,
                formatButtonVisible: false,
                titleTextFormatter: (day, _) => _formatMonthTitle(day, datePref),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                dowTextFormatter: (day, _) => _formatWeekday(day, datePref),
                weekdayStyle: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                weekendStyle: TextStyle(
                  color: cs.outline,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                todayDecoration: BoxDecoration(
                  color: cs.primary,
                  shape: BoxShape.circle,
                ),
                todayTextStyle: TextStyle(
                  color: cs.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
                selectedDecoration: BoxDecoration(
                  border: Border.all(color: cs.primary, width: 2),
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: cs.tertiary,
                  shape: BoxShape.circle,
                ),
                markerSize: 7,
                markersMaxCount: 1,
              ),
              selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
              eventLoader: (day) =>
                  provider.isMarked(day) ? const [true] : const [],
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
                // Tap = markieren/unmarkieren (ohne Texteingabe).
                context.read<MarkedDaysProvider>().toggleDay(selectedDay);
              },
              onPageChanged: (focusedDay) {
                setState(() => _focusedDay = focusedDay);
              },
            ),
            const Divider(height: 24),
            // Legend + counter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: cs.tertiary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Marked',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const Spacer(),
                  Text(
                    provider.markedDaysCount == 1
                        ? '1 marked day'
                        : '${provider.markedDaysCount} marked days',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(
                            color: cs.primary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Error View ──────────────────────────────────────────────────────────────

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

// ─── Ähnlichkeits-Highlights ─────────────────────────────────────────────────

class _HighlightsSection extends StatelessWidget {
  const _HighlightsSection({
    required this.highlights,
    required this.hasMarkedDays,
    required this.analyzing,
  });

  final List<SimilarityHighlight> highlights;
  final bool hasMarkedDays;

  /// True while the comparison/highlight analysis is running.
  final bool analyzing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: cs.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Similarity Highlights',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'How often a value occurred on marked days.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: cs.outline),
            ),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: analyzing
                  ? const _AnalyzingRow(key: ValueKey('analyzing'))
                  : !hasMarkedDays
                      ? _EmptyHint(
                          key: const ValueKey('no-marked'),
                          icon: Icons.event_available,
                          text: 'First mark days in the calendar to see similarities.',
                        )
                      : highlights.isEmpty
                          ? const _EmptyHint(
                              key: ValueKey('no-data'),
                              icon: Icons.check_box_outlined,
                              text: 'No checkbox data on marked days.',
                            )
                          : Column(
                              key: const ValueKey('results'),
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: highlights
                                  .map((h) => _HighlightTile(highlight: h))
                                  .toList(),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small loading row shown while the analysis is being recomputed.
class _AnalyzingRow extends StatelessWidget {
  const _AnalyzingRow({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(
            'Calculating analysis…',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _HighlightTile extends StatelessWidget {
  const _HighlightTile({required this.highlight});

  final SimilarityHighlight highlight;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isTrue = highlight.dominantValue;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            isTrue ? Icons.check_circle : Icons.cancel,
            color: isTrue ? Colors.green.shade600 : cs.error,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              highlight.label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Vergleich: markierte vs. andere Tage ────────────────────────────────────

class _ComparisonSection extends StatelessWidget {
  const _ComparisonSection({
    required this.comparisons,
    required this.hasMarkedDays,
    required this.analyzing,
  });

  final List<MarkedComparison> comparisons;
  final bool hasMarkedDays;

  /// True while the comparison/highlight analysis is running.
  final bool analyzing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final maxAbsDelta = comparisons.isEmpty
        ? 1.0
        : comparisons
            .map((c) => c.delta?.abs() ?? 0)
            .reduce((a, b) => a > b ? a : b);

    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.compare_arrows, color: cs.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Comparison: marked vs. other days',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Ø value per day — only widgets with data.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: cs.outline),
            ),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: analyzing
                  ? const _AnalyzingRow(key: ValueKey('analyzing'))
                  : !hasMarkedDays
                      ? const _EmptyHint(
                          key: ValueKey('no-marked'),
                          icon: Icons.event_available,
                          text: 'Mark days in the calendar to compare them '
                              'with other days.',
                        )
                      : comparisons.isEmpty
                          ? const _EmptyHint(
                              key: ValueKey('no-data'),
                              icon: Icons.bar_chart,
                              text: 'No comparable data yet. '
                                  'Track on marked and other days.',
                            )
                          : Column(
                              key: const ValueKey('results'),
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: comparisons
                                  .map(
                                    (c) => _ComparisonRow(
                                      comparison: c,
                                      maxAbsDelta: maxAbsDelta,
                                    ),
                                  )
                                  .toList(),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({
    required this.comparison,
    required this.maxAbsDelta,
  });

  final MarkedComparison comparison;
  final double maxAbsDelta;

  IconData get _icon {
    switch (comparison.widget.fieldType) {
      case 'slider':
        return Icons.linear_scale;
      case 'checkbox':
        return Icons.check_box_outlined;
      case 'duration':
        return Icons.timer_outlined;
      case 'time':
        return Icons.access_time;
      default:
        return Icons.pin_outlined;
    }
  }

  String _formatValue(double v, FieldType ft) {
    switch (ft) {
      case FieldType.checkbox:
        return '${(v * 100).round()}%';
      case FieldType.slider:
        return v.toStringAsFixed(1);
      case FieldType.number:
        return v == v.roundToDouble() ? '${v.toInt()}' : v.toStringAsFixed(1);
      case FieldType.duration:
        final total = v.round();
        final h = total ~/ 60;
        final m = total % 60;
        return h > 0 ? '${h}h ${m}min' : '${m}min';
      case FieldType.time:
        final total = v.round();
        final h = (total ~/ 60).toString().padLeft(2, '0');
        final m = (total % 60).toString().padLeft(2, '0');
        return '$h:$m';
    }
  }

  String _formatDelta(double delta, FieldType ft) {
    final sign = delta >= 0 ? '+' : '−';
    final abs = delta.abs();
    switch (ft) {
      case FieldType.checkbox:
        return '$sign${(abs * 100).round()} %';
      case FieldType.slider:
        return '$sign${abs.toStringAsFixed(1)}';
      case FieldType.number:
        return '$sign${abs == abs.roundToDouble() ? '${abs.toInt()}' : abs.toStringAsFixed(1)}';
      case FieldType.duration:
        final total = abs.round();
        final h = total ~/ 60;
        final m = total % 60;
        return h > 0 ? '$sign${h}h ${m}min' : '$sign${m}min';
      case FieldType.time:
        return '$sign${abs.round()} min';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ft = FieldType.fromDb(comparison.widget.fieldType);
    final delta = comparison.delta ?? 0;
    final deltaPositive = delta >= 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: icon + name + delta chip
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_icon, color: cs.onPrimaryContainer, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  comparison.widget.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: deltaPositive
                      ? Colors.green.withValues(alpha: 0.15)
                      : cs.errorContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _formatDelta(delta, ft),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: deltaPositive
                            ? Colors.green.shade700
                            : cs.onErrorContainer,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Averages row
          Row(
            children: [
              Expanded(
                child: _AvgColumn(
                  label: 'Ø marked',
                  value: _formatValue(comparison.avgMarked!, ft),
                  days: comparison.markedDaysWithData,
                  highlight: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _AvgColumn(
                  label: 'Ø other',
                  value: _formatValue(comparison.avgUnmarked!, ft),
                  days: comparison.unmarkedDaysWithData,
                  highlight: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Delta bar
          _DeltaBar(
            delta: delta,
            maxAbsDelta: maxAbsDelta,
            positiveColor: Colors.green.shade600,
            negativeColor: cs.error,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                deltaPositive
                    ? 'higher on marked days'
                    : 'lower on marked days',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: cs.outline),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AvgColumn extends StatelessWidget {
  const _AvgColumn({
    required this.label,
    required this.value,
    required this.days,
    required this.highlight,
  });

  final String label;
  final String value;
  final int days;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: cs.outline),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: highlight ? cs.tertiary : cs.onSurface,
              ),
        ),
        Text(
          '$days day${days == 1 ? '' : 's'}',
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: cs.outline),
        ),
      ],
    );
  }
}

/// Diverging horizontal bar: fills right (green) when the delta is positive
/// (higher on marked days), left (red) when negative.
class _DeltaBar extends StatelessWidget {
  const _DeltaBar({
    required this.delta,
    required this.maxAbsDelta,
    required this.positiveColor,
    required this.negativeColor,
  });

  final double delta;
  final double maxAbsDelta;
  final Color positiveColor;
  final Color negativeColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fraction =
        maxAbsDelta <= 0 ? 0.0 : (delta.abs() / maxAbsDelta).clamp(0.0, 1.0);
    final positive = delta >= 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final half = constraints.maxWidth / 2;
        final fillWidth = half * fraction;

        return SizedBox(
          height: 10,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Track
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              // Center divider
              Center(
                child: Container(
                  width: 2,
                  height: 10,
                  color: cs.outlineVariant,
                ),
              ),
              // Fill (from center outward)
              if (fillWidth > 0)
                Positioned(
                  left: positive ? half : half - fillWidth,
                  child: Container(
                    width: fillWidth,
                    height: 10,
                    decoration: BoxDecoration(
                      color:
                          positive ? positiveColor : negativeColor,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Shared empty hint ───────────────────────────────────────────────────────

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Icon(icon, size: 36, color: cs.outline),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: cs.outline),
          ),
        ],
      ),
    );
  }
}
