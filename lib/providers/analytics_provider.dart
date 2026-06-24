import 'dart:convert';
import 'dart:math' show sqrt;
import 'package:flutter/foundation.dart';
import '../database/database.dart';
import 'widget_manager_provider.dart';

/// Pairs a TrackingEvent with its parent widget for display.
class EventWithWidget {
  final TrackingEvent event;
  final CustomWidget widget;

  const EventWithWidget({required this.event, required this.widget});
}

/// Result of a Pearson correlation computation.
class CorrelationResult {
  final double value; // -1.0 to 1.0
  final int dataPoints; // number of overlapping daily averages used

  const CorrelationResult({required this.value, required this.dataPoints});
}

/// Provider for the Analytics screen.
/// Loads all widgets + their events, exposes timeline, per-widget events,
/// and computes Pearson correlations between numeric-valued widget pairs.
class AnalyticsProvider extends ChangeNotifier {
  final AppDatabase _db;

  AnalyticsProvider(this._db) {
    loadData();
  }

  List<CustomWidget> _widgets = [];
  Map<int, List<TrackingEvent>> _eventsByWidgetId = {};
  bool _loading = false;
  String? _error;

  // ── Getters ───────────────────────────────────────────────────────────────

  List<CustomWidget> get widgets => List.unmodifiable(_widgets);
  bool get loading => _loading;
  String? get error => _error;

  /// All events merged and sorted by timestamp descending.
  List<EventWithWidget> get timeline {
    final result = <EventWithWidget>[];
    for (final w in _widgets) {
      for (final e in _eventsByWidgetId[w.id] ?? []) {
        result.add(EventWithWidget(event: e, widget: w));
      }
    }
    result.sort((a, b) => b.event.timestamp.compareTo(a.event.timestamp));
    return result;
  }

  /// Events for a specific widget, sorted newest first.
  List<TrackingEvent> eventsForWidget(int widgetId) =>
      List.unmodifiable(_eventsByWidgetId[widgetId] ?? []);

  // ── Data Loading ──────────────────────────────────────────────────────────

  Future<void> loadData() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
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

  // ── Mutations ─────────────────────────────────────────────────────────────

  Future<void> deleteEvent(int eventId, int widgetId) async {
    try {
      await _db.deleteEvent(eventId);
      // Reload only this widget's events
      _eventsByWidgetId[widgetId] = await _db.getEventsForWidget(widgetId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // ── Statistics ────────────────────────────────────────────────────────────

  /// Parses an event value to double (in minutes for duration, minutes-since-midnight for time).
  double? _parseValue(TrackingEvent e, FieldType ft) {
    switch (ft) {
      case FieldType.number:
        return double.tryParse(e.value);
      case FieldType.slider:
        return double.tryParse(e.value);
      case FieldType.checkbox:
        return e.value.toLowerCase() == 'true' ? 1.0 : 0.0;
      case FieldType.duration:
        // Parse {"hours": int, "minutes": int} → total minutes
        try {
          final map = jsonDecode(e.value) as Map<String, dynamic>;
          final hours = (map['hours'] as num?)?.toInt() ?? 0;
          final minutes = (map['minutes'] as num?)?.toInt() ?? 0;
          return (hours * 60 + minutes).toDouble();
        } catch (_) {
          return null;
        }
      case FieldType.time:
        // Parse "HH:mm" → minutes since midnight
        final parts = e.value.split(':');
        if (parts.length < 2) return null;
        final h = int.tryParse(parts[0]) ?? 0;
        final m = int.tryParse(parts[1]) ?? 0;
        return (h * 60 + m).toDouble();
    }
  }

  /// Computes daily averages for a widget's events.
  /// Returns a map of "YYYY-MM-DD" → average value.
  /// For duration: average total minutes. For time: average minutes-since-midnight.
  Map<String, double> dailyAverages(int widgetId) {
    final widget =
        _widgets.where((w) => w.id == widgetId).firstOrNull;
    if (widget == null) return {};

    final ft = FieldType.fromDb(widget.fieldType);
    final events = _eventsByWidgetId[widgetId] ?? [];

    final Map<String, List<double>> byDay = {};
    for (final e in events) {
      final t = e.timestamp;
      final dayKey =
          '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
      final v = _parseValue(e, ft);
      if (v != null) {
        byDay.putIfAbsent(dayKey, () => []).add(v);
      }
    }

    return byDay.map((k, vs) {
      final avg = vs.reduce((a, b) => a + b) / vs.length;
      return MapEntry(k, avg);
    });
  }

  /// Computes Pearson correlation between two widgets.
  /// Returns null if there are fewer than [minPoints] overlapping days.
  CorrelationResult? correlationBetween(
    int widgetId1,
    int widgetId2, {
    int minPoints = 5,
  }) {
    if (widgetId1 == widgetId2) {
      return CorrelationResult(value: 1.0, dataPoints: -1);
    }

    final avgs1 = dailyAverages(widgetId1);
    final avgs2 = dailyAverages(widgetId2);

    final commonDays =
        avgs1.keys.toSet().intersection(avgs2.keys.toSet()).toList();

    if (commonDays.length < minPoints) return null;

    final xs = commonDays.map((d) => avgs1[d]!).toList();
    final ys = commonDays.map((d) => avgs2[d]!).toList();

    return _pearson(xs, ys, commonDays.length);
  }

  CorrelationResult? _pearson(List<double> xs, List<double> ys, int n) {
    final meanX = xs.reduce((a, b) => a + b) / n;
    final meanY = ys.reduce((a, b) => a + b) / n;

    double sumXY = 0, sumX2 = 0, sumY2 = 0;
    for (int i = 0; i < n; i++) {
      final dx = xs[i] - meanX;
      final dy = ys[i] - meanY;
      sumXY += dx * dy;
      sumX2 += dx * dx;
      sumY2 += dy * dy;
    }

    if (sumX2 == 0 || sumY2 == 0) return null;

    final r = sumXY / sqrt(sumX2 * sumY2);
    // Clamp to [-1, 1] to handle floating-point drift
    final clamped = r.clamp(-1.0, 1.0);
    return CorrelationResult(value: clamped, dataPoints: n);
  }
}
