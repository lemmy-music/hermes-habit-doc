import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../database/database.dart';
import 'widget_manager_provider.dart';

/// Normalizes a [DateTime] to the date-only representation (midnight).
DateTime dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

/// Stable "YYYY-MM-DD" key for a [DateTime] — used to group/compare days.
String dayKey(DateTime dt) =>
    '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

/// Result of comparing a widget's daily values on marked vs. unmarked days.
class MarkedComparison {
  final CustomWidget widget;

  /// Average daily value on marked days (in the widget's unit space).
  final double? avgMarked;

  /// Average daily value on all other days (in the widget's unit space).
  final double? avgUnmarked;

  /// Number of marked days that contributed data.
  final int markedDaysWithData;

  /// Number of unmarked days that contributed data.
  final int unmarkedDaysWithData;

  const MarkedComparison({
    required this.widget,
    required this.avgMarked,
    required this.avgUnmarked,
    required this.markedDaysWithData,
    required this.unmarkedDaysWithData,
  });

  /// Difference `avgMarked - avgUnmarked`. Null if either side has no data.
  double? get delta {
    final a = avgMarked;
    final b = avgUnmarked;
    if (a == null || b == null) return null;
    return a - b;
  }

  bool get hasBothGroups => avgMarked != null && avgUnmarked != null;
}

/// Highlight for checkbox widgets: how often a value occurred on marked days.
class SimilarityHighlight {
  final CustomWidget widget;

  /// Percentage (0–100) of marked days with data where the dominant state
  /// ([dominantValue]) occurred.
  final int percentage;

  /// Dominant state on marked days: `true` → "✓", `false` → "✗".
  final bool dominantValue;

  const SimilarityHighlight({
    required this.widget,
    required this.percentage,
    required this.dominantValue,
  });

  String get label =>
      'An $percentage% der markierten Tage: ${widget.name} '
      '${dominantValue ? '✓' : '✗'}';
}

/// Provider for the "Tage" (marked days) feature.
///
/// Loads marked days plus all widgets/events (same pattern as
/// [AnalyticsProvider]) and exposes:
/// - Calendar CRUD: [toggleDay], [isMarked], [markedDays]
/// - Comparison analysis: [allComparisons], [compareMarkedVsUnmarked]
/// - Checkbox highlights: [similarityHighlights]
class MarkedDaysProvider extends ChangeNotifier {
  final AppDatabase _db;

  MarkedDaysProvider(this._db) {
    loadData();
  }

  List<MarkedDay> _markedDays = [];
  List<CustomWidget> _widgets = [];
  Map<int, List<TrackingEvent>> _eventsByWidgetId = {};
  bool _loading = false;
  String? _error;

  // ── Getters ───────────────────────────────────────────────────────────────

  List<MarkedDay> get markedDays => List.unmodifiable(_markedDays);
  List<CustomWidget> get widgets => List.unmodifiable(_widgets);
  bool get loading => _loading;
  String? get error => _error;

  /// Keys (YYYY-MM-DD) of all marked days.
  Set<String> get markedDayKeys =>
      _markedDays.map((m) => dayKey(m.date)).toSet();

  /// True if the given day (time-of-day ignored) is marked.
  bool isMarked(DateTime date) => markedDayKeys.contains(dayKey(date));

  int get markedDaysCount => _markedDays.length;

  // ── Data Loading ──────────────────────────────────────────────────────────

  Future<void> loadData() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _markedDays = await _db.getAllMarkedDays();
      _widgets = await _db.getAllWidgets();
      _eventsByWidgetId = {};
      for (final w in _widgets) {
        _eventsByWidgetId[w.id] = await _db.getEventsForWidget(w.id);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _reloadMarkedDays() async {
    try {
      _markedDays = await _db.getAllMarkedDays();
    } catch (e) {
      _error = e.toString();
    } finally {
      notifyListeners();
    }
  }

  // ── Calendar CRUD ─────────────────────────────────────────────────────────

  /// Marks the day if it is unmarked, unmarks it otherwise.
  Future<void> toggleDay(DateTime date) async {
    final normalized = dateOnly(date);
    try {
      if (isMarked(normalized)) {
        final existing = _markedDays
            .where((m) => dayKey(m.date) == dayKey(normalized))
            .firstOrNull;
        if (existing != null) {
          await _db.deleteMarkedDay(existing.id);
        }
      } else {
        await _db.insertMarkedDay(
          MarkedDaysCompanion.insert(date: normalized),
        );
      }
      await _reloadMarkedDays();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Removes the mark from [date] if present (no-op otherwise).
  Future<void> unmarkDay(DateTime date) async {
    final normalized = dateOnly(date);
    if (!isMarked(normalized)) return;
    await toggleDay(normalized);
  }

  // ── Value Parsing ─────────────────────────────────────────────────────────

  /// Parses an event value to double (minutes for duration, minutes-since-
  /// midnight for time, 1.0/0.0 for checkbox).
  double? _parseValue(TrackingEvent e, FieldType ft) {
    switch (ft) {
      case FieldType.number:
        return double.tryParse(e.value);
      case FieldType.slider:
        return double.tryParse(e.value);
      case FieldType.checkbox:
        return e.value.toLowerCase() == 'true' ? 1.0 : 0.0;
      case FieldType.duration:
        try {
          final map = jsonDecode(e.value) as Map<String, dynamic>;
          final hours = (map['hours'] as num?)?.toInt() ?? 0;
          final minutes = (map['minutes'] as num?)?.toInt() ?? 0;
          return (hours * 60 + minutes).toDouble();
        } catch (_) {
          return null;
        }
      case FieldType.time:
        final parts = e.value.split(':');
        if (parts.length < 2) return null;
        final h = int.tryParse(parts[0]) ?? 0;
        final m = int.tryParse(parts[1]) ?? 0;
        return (h * 60 + m).toDouble();
    }
  }

  // ── Statistics ────────────────────────────────────────────────────────────

  /// Daily averages for a widget: "YYYY-MM-DD" → average value.
  Map<String, double> dailyAverages(int widgetId) {
    final widget = _widgets.where((w) => w.id == widgetId).firstOrNull;
    if (widget == null) return {};

    final ft = FieldType.fromDb(widget.fieldType);
    final events = _eventsByWidgetId[widgetId] ?? [];

    final Map<String, List<double>> byDay = {};
    for (final e in events) {
      final v = _parseValue(e, ft);
      if (v == null) continue;
      byDay.putIfAbsent(dayKey(e.timestamp), () => []).add(v);
    }

    return byDay.map((k, vs) {
      final avg = vs.reduce((a, b) => a + b) / vs.length;
      return MapEntry(k, avg);
    });
  }

  /// Compares a widget's daily values on marked vs. unmarked days.
  ///
  /// Returns a [MarkedComparison]; averages are null for groups without data.
  MarkedComparison? compareMarkedVsUnmarked(int widgetId) {
    final widget = _widgets.where((w) => w.id == widgetId).firstOrNull;
    if (widget == null) return null;

    final avgs = dailyAverages(widgetId);
    final marked = markedDayKeys;

    final markedValues = <double>[];
    final unmarkedValues = <double>[];
    avgs.forEach((key, value) {
      if (marked.contains(key)) {
        markedValues.add(value);
      } else {
        unmarkedValues.add(value);
      }
    });

    double? mean(List<double> values) =>
        values.isEmpty ? null : values.reduce((a, b) => a + b) / values.length;

    return MarkedComparison(
      widget: widget,
      avgMarked: mean(markedValues),
      avgUnmarked: mean(unmarkedValues),
      markedDaysWithData: markedValues.length,
      unmarkedDaysWithData: unmarkedValues.length,
    );
  }

  /// Comparisons for every widget that has data on both marked and
  /// unmarked days.
  List<MarkedComparison> get allComparisons {
    final result = <MarkedComparison>[];
    for (final w in _widgets) {
      final c = compareMarkedVsUnmarked(w.id);
      if (c != null && c.hasBothGroups) {
        result.add(c);
      }
    }
    return result;
  }

  /// Checkbox highlights: how often the dominant state occurred on marked
  /// days, sorted by percentage descending.
  List<SimilarityHighlight> similarityHighlights() {
    final highlights = <SimilarityHighlight>[];
    final marked = markedDayKeys;

    for (final w in _widgets) {
      if (FieldType.fromDb(w.fieldType) != FieldType.checkbox) continue;

      final avgs = dailyAverages(w.id);
      var trueDays = 0;
      var dataDays = 0;
      avgs.forEach((key, value) {
        if (!marked.contains(key)) return;
        dataDays++;
        if (value >= 0.5) trueDays++;
      });
      if (dataDays == 0) continue;

      final pctTrue = 100 * trueDays / dataDays;
      final dominant = pctTrue >= 50;
      highlights.add(SimilarityHighlight(
        widget: w,
        percentage: (dominant ? pctTrue : 100 - pctTrue).round(),
        dominantValue: dominant,
      ));
    }

    highlights.sort((a, b) => b.percentage.compareTo(a.percentage));
    return highlights;
  }
}
