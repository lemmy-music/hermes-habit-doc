import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import '../database/database.dart';
import 'widget_manager_provider.dart';

/// Holds the current form state for a single widget's tracking card.
class WidgetTrackingState {
  final CustomWidget widget;

  // Form values
  String numberValue;
  double sliderValue;
  bool checkboxValue;

  // Timestamp for the event (defaults to now, user-editable for backlogging)
  DateTime selectedTimestamp;

  // UI state
  bool saving;
  String? error;

  WidgetTrackingState({
    required this.widget,
    this.numberValue = '',
    this.sliderValue = 50.0,
    this.checkboxValue = false,
    DateTime? selectedTimestamp,
    this.saving = false,
    this.error,
  }) : selectedTimestamp = selectedTimestamp ?? DateTime.now();

  /// Returns the string value to persist depending on field type.
  String get valueForDb {
    final fieldType = FieldType.fromDb(widget.fieldType);
    switch (fieldType) {
      case FieldType.number:
        return numberValue.isEmpty ? '0' : numberValue;
      case FieldType.slider:
        return sliderValue.toStringAsFixed(1);
      case FieldType.checkbox:
        return checkboxValue ? 'true' : 'false';
    }
  }

  /// Reset form values back to defaults after saving.
  void reset() {
    numberValue = '';
    sliderValue = 50.0;
    checkboxValue = false;
    selectedTimestamp = DateTime.now();
    saving = false;
    error = null;
  }

  WidgetTrackingState copyWith({
    String? numberValue,
    double? sliderValue,
    bool? checkboxValue,
    DateTime? selectedTimestamp,
    bool? saving,
    String? error,
    bool clearError = false,
  }) {
    return WidgetTrackingState(
      widget: widget,
      numberValue: numberValue ?? this.numberValue,
      sliderValue: sliderValue ?? this.sliderValue,
      checkboxValue: checkboxValue ?? this.checkboxValue,
      selectedTimestamp: selectedTimestamp ?? this.selectedTimestamp,
      saving: saving ?? this.saving,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Provider that manages the Tracking screen state:
/// - loads all widgets
/// - holds per-widget form state
/// - saves events to the database
class TrackingProvider extends ChangeNotifier {
  final AppDatabase _db;

  TrackingProvider(this._db) {
    _loadWidgets();
  }

  List<CustomWidget> _widgets = [];
  final Map<int, WidgetTrackingState> _formStates = {};
  bool _loading = false;
  String? _error;

  List<CustomWidget> get widgets => List.unmodifiable(_widgets);
  bool get loading => _loading;
  String? get error => _error;

  WidgetTrackingState? stateFor(int widgetId) => _formStates[widgetId];

  // ── Loading ───────────────────────────────────────────────────────────────

  Future<void> _loadWidgets() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _widgets = await _db.getAllWidgets();
      // Initialize form state for any new widgets
      for (final w in _widgets) {
        _formStates.putIfAbsent(
          w.id,
          () => WidgetTrackingState(widget: w),
        );
      }
      // Remove stale states for deleted widgets
      final widgetIds = _widgets.map((w) => w.id).toSet();
      _formStates.removeWhere((id, _) => !widgetIds.contains(id));
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => _loadWidgets();

  // ── Mutators (called from UI) ─────────────────────────────────────────────

  void setNumberValue(int widgetId, String value) {
    final state = _formStates[widgetId];
    if (state == null) return;
    _formStates[widgetId] = state.copyWith(numberValue: value, clearError: true);
    notifyListeners();
  }

  void setSliderValue(int widgetId, double value) {
    final state = _formStates[widgetId];
    if (state == null) return;
    _formStates[widgetId] = state.copyWith(sliderValue: value, clearError: true);
    notifyListeners();
  }

  void setCheckboxValue(int widgetId, bool value) {
    final state = _formStates[widgetId];
    if (state == null) return;
    _formStates[widgetId] = state.copyWith(checkboxValue: value, clearError: true);
    notifyListeners();
  }

  void setTimestamp(int widgetId, DateTime dt) {
    final state = _formStates[widgetId];
    if (state == null) return;
    _formStates[widgetId] = state.copyWith(selectedTimestamp: dt, clearError: true);
    notifyListeners();
  }

  /// Saves a tracking event for the given widget. Returns null on success,
  /// or an error message string on failure.
  Future<String?> saveEvent(int widgetId) async {
    final state = _formStates[widgetId];
    if (state == null) return 'Widget not found';

    // Validate number input
    final fieldType = FieldType.fromDb(state.widget.fieldType);
    if (fieldType == FieldType.number) {
      final raw = state.numberValue.trim();
      if (raw.isEmpty) return 'Please enter a value';
      if (double.tryParse(raw) == null) return 'Value must be a number';
    }

    // Mark as saving
    _formStates[widgetId] = state.copyWith(saving: true, clearError: true);
    notifyListeners();

    try {
      await _db.insertEvent(
        TrackingEventsCompanion.insert(
          widgetId: widgetId,
          value: state.valueForDb,
          timestamp: Value(state.selectedTimestamp),
        ),
      );

      // Reset form on success
      _formStates[widgetId]!.reset();
      notifyListeners();
      return null; // success
    } catch (e) {
      _formStates[widgetId] = _formStates[widgetId]!.copyWith(
        saving: false,
        error: e.toString(),
      );
      notifyListeners();
      return e.toString();
    }
  }
}
