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

  // Cached analysis results (recomputed off-frame so the UI can show a
  // loading indicator while the math runs).
  bool _analyzing = false;
  List<SimilarityHighlight> _highlights = [];
  List<MarkedComparison> _comparisons = [];
  int _analysisVersion = 0;
  bool _disposed = false;

  // ── Getters ───────────────────────────────────────────────────────────────

  List<MarkedDay> get markedDays => List.unmodifiable(_markedDays);
  List<CustomWidget> get widgets => List.unmodifiable(_widgets);
  bool get loading => _loading;
  String? get error => _error;

  /// True while the comparison/highlight analysis is running.
  bool get analyzing => _analyzing;

  /// Checkbox highlights for marked days (see [similarityHighlights]).
  List<SimilarityHighlight> get highlights => List.unmodifiable(_highlights);

  /// Comparison of marked vs. unmarked days for every widget with data.
  List<MarkedComparison> get comparisons => List.unmodifiable(_comparisons);

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
      // Fire-and-forget: the analysis sections show their own spinner.
      _runAnalysis();
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
      await _runAnalysis();
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

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  // ── Value Parsing ─────────────────────────────────────────────────────────

  /// Parses an event value to double (minutes for duration, minutes-since-
  /// midnight for time, 1.0/0.0 for checkbox).
  static double? _parseValueStatic(TrackingEvent e, FieldType ft) {
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

  /// Recomputes highlights + comparisons off-frame.
  ///
  /// The math is synchronous CPU work (1–2 s on web), so we first notify so
  /// the UI can show a loading placeholder, then crunch on a snapshot.
  /// A version counter makes sure a newer run always wins over an older one.
  Future<void> _runAnalysis() async {
    final version = ++_analysisVersion;
    _analyzing = true;
    notifyListeners();

    // Yield so the loading placeholders get a frame before the crunching.
    await Future<void>.delayed(const Duration(milliseconds: 30));
    if (_disposed || version != _analysisVersion) return;

    final widgets = List<CustomWidget>.of(_widgets);
    final events = Map<int, List<TrackingEvent>>.of(_eventsByWidgetId);
    final marked = markedDayKeys;

    final comparisons = _computeComparisons(widgets, events, marked);
    // Yield so the spinner can keep animating between the two heavy steps.
    await Future<void>.delayed(Duration.zero);
    if (_disposed || version != _analysisVersion) return;
    final highlights = _computeHighlights(widgets, events, marked);

    if (_disposed || version != _analysisVersion) return;
    _comparisons = comparisons;
    _highlights = highlights;
    _analyzing = false;
    notifyListeners();
  }

  /// Daily averages for a widget: "YYYY-MM-DD" → average value.
  static Map<String, double> _dailyAveragesFor(
    CustomWidget widget,
    Map<int, List<TrackingEvent>> eventsByWidgetId,
  ) {
    final ft = FieldType.fromDb(widget.fieldType);
    final events = eventsByWidgetId[widget.id] ?? [];

    final Map<String, List<double>> byDay = {};
    for (final e in events) {
      final v = _parseValueStatic(e, ft);
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
  static MarkedComparison? _compareMarkedVsUnmarked(
    CustomWidget widget,
    Map<int, List<TrackingEvent>> eventsByWidgetId,
    Set<String> markedKeys,
  ) {
    final avgs = _dailyAveragesFor(widget, eventsByWidgetId);

    final markedValues = <double>[];
    final unmarkedValues = <double>[];
    avgs.forEach((key, value) {
      if (markedKeys.contains(key)) {
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
  static List<MarkedComparison> _computeComparisons(
    List<CustomWidget> widgets,
    Map<int, List<TrackingEvent>> eventsByWidgetId,
    Set<String> markedKeys,
  ) {
    final result = <MarkedComparison>[];
    for (final w in widgets) {
      final c = _compareMarkedVsUnmarked(w, eventsByWidgetId, markedKeys);
      if (c != null && c.hasBothGroups) {
        result.add(c);
      }
    }
    return result;
  }

  /// Checkbox highlights: how often the dominant state occurred on marked
  /// days, sorted by percentage descending.
  static List<SimilarityHighlight> _computeHighlights(
    List<CustomWidget> widgets,
    Map<int, List<TrackingEvent>> eventsByWidgetId,
    Set<String> markedKeys,
  ) {
    final highlights = <SimilarityHighlight>[];

    for (final w in widgets) {
      if (FieldType.fromDb(w.fieldType) != FieldType.checkbox) continue;

      final avgs = _dailyAveragesFor(w, eventsByWidgetId);
      var trueDays = 0;
      var dataDays = 0;
      avgs.forEach((key, value) {
        if (!markedKeys.contains(key)) return;
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
