import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import '../database/database.dart';

/// FieldType enum matching database values
enum FieldType {
  number('number', 'Number'),
  slider('slider', 'Slider'),
  checkbox('checkbox', 'Checkbox');

  const FieldType(this.dbValue, this.label);
  final String dbValue;
  final String label;

  static FieldType fromDb(String value) =>
      FieldType.values.firstWhere((e) => e.dbValue == value,
          orElse: () => FieldType.number);
}

/// Provider that manages all custom widgets
class WidgetManagerProvider extends ChangeNotifier {
  final AppDatabase _db;

  WidgetManagerProvider(this._db) {
    _loadWidgets();
  }

  List<CustomWidget> _widgets = [];
  bool _loading = false;
  String? _error;

  List<CustomWidget> get widgets => List.unmodifiable(_widgets);
  bool get loading => _loading;
  String? get error => _error;

  // ── Internal ──────────────────────────────────────────────────────────────

  Future<void> _loadWidgets() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _widgets = await _db.getAllWidgets();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ── Public API ────────────────────────────────────────────────────────────

  Future<void> refresh() => _loadWidgets();

  Future<void> createWidget(String name, FieldType fieldType) async {
    await _db.insertWidget(
      CustomWidgetsCompanion.insert(
        name: name,
        fieldType: fieldType.dbValue,
      ),
    );
    await _loadWidgets();
  }

  Future<void> editWidget(int id, String name, FieldType fieldType) async {
    await _db.updateWidget(
      CustomWidgetsCompanion(
        id: Value(id),
        name: Value(name),
        fieldType: Value(fieldType.dbValue),
      ),
    );
    await _loadWidgets();
  }

  Future<void> deleteWidget(int id) async {
    await _db.deleteWidget(id);
    await _loadWidgets();
  }
}
