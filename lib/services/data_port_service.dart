import 'dart:convert';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import '../database/database.dart';

/// Result of an import operation.
class ImportResult {
  final int widgetsAdded;
  final int eventsAdded;
  final String? error;

  const ImportResult({
    this.widgetsAdded = 0,
    this.eventsAdded = 0,
    this.error,
  });

  bool get isSuccess => error == null;
}

/// Handles JSON export and import for all habit data.
class DataPortService {
  final AppDatabase _db;

  DataPortService(this._db);

  // ─── Export ────────────────────────────────────────────────────────────────

  /// Builds the export payload.
  Future<Map<String, dynamic>> _buildExportMap() async {
    final widgets = await _db.getAllWidgets();
    final widgetMaps = <Map<String, dynamic>>[];
    final eventMaps = <Map<String, dynamic>>[];

    for (final w in widgets) {
      widgetMaps.add({
        'id': w.id,
        'name': w.name,
        'fieldType': w.fieldType,
        'createdAt': w.createdAt.toIso8601String(),
      });
      final events = await _db.getEventsForWidget(w.id);
      for (final e in events) {
        eventMaps.add({
          'id': e.id,
          'widgetId': e.widgetId,
          'value': e.value,
          'timestamp': e.timestamp.toIso8601String(),
        });
      }
    }

    return {'widgets': widgetMaps, 'events': eventMaps};
  }

  /// Exports data as JSON.
  ///
  /// On **web**: file_picker.saveFile with bytes triggers a browser download.
  /// On **native**: opens a save-file dialog.
  ///
  /// Returns null on success, an error string on failure.
  Future<String?> exportData() async {
    try {
      final data = await _buildExportMap();
      final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
      final bytes = Uint8List.fromList(utf8.encode(jsonStr));
      final filename =
          'habit_doc_export_${DateTime.now().millisecondsSinceEpoch}.json';

      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Habit Doc Export',
        fileName: filename,
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: bytes,
      );

      // On web, file_picker downloads and returns null (no path).
      // On native, null means the user cancelled the dialog.
      if (!kIsWeb && path == null) {
        return 'Export cancelled by user.';
      }

      return null; // success
    } catch (e) {
      return 'Export failed: $e';
    }
  }

  // ─── Import ────────────────────────────────────────────────────────────────

  /// Opens the file picker and parses the selected JSON file.
  ///
  /// Returns null when the user cancels.
  /// Throws [FormatException] on parse / structure errors.
  Future<Map<String, dynamic>?> pickAndParseJson() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true, // required for web
    );

    if (result == null || result.files.isEmpty) return null;

    final file = result.files.first;
    final rawBytes = file.bytes;
    if (rawBytes == null) {
      throw const FormatException('Could not read file content.');
    }

    final jsonStr = utf8.decode(rawBytes);
    final dynamic decoded;
    try {
      decoded = jsonDecode(jsonStr);
    } catch (_) {
      throw const FormatException(
          'Invalid JSON — the file is not valid JSON.');
    }

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
          'Invalid format: root element must be a JSON object.');
    }
    _validateStructure(decoded);
    return decoded;
  }

  void _validateStructure(Map<String, dynamic> data) {
    if (!data.containsKey('widgets') || data['widgets'] is! List) {
      throw const FormatException(
          'Invalid format: missing or invalid "widgets" array.');
    }
    if (!data.containsKey('events') || data['events'] is! List) {
      throw const FormatException(
          'Invalid format: missing or invalid "events" array.');
    }
  }

  /// Imports parsed data into the database.
  ///
  /// [overwrite] = true  → clears ALL existing data first.
  /// [overwrite] = false → merges (widgets with the same name are reused
  ///                        so events still link correctly).
  Future<ImportResult> importData(
    Map<String, dynamic> data, {
    required bool overwrite,
  }) async {
    try {
      if (overwrite) await _clearAll();

      final rawWidgets = (data['widgets'] as List).cast<Map<String, dynamic>>();
      final rawEvents = (data['events'] as List).cast<Map<String, dynamic>>();

      // Map old widget IDs → new/existing widget IDs.
      final Map<int, int> idMap = {};
      var widgetsAdded = 0;

      final existing = await _db.getAllWidgets();
      final existingNames = {for (final w in existing) w.name};
      final nameToId = {for (final w in existing) w.name: w.id};

      for (final wMap in rawWidgets) {
        final oldId = (wMap['id'] as num).toInt();
        final name = wMap['name'] as String;
        final fieldType = wMap['fieldType'] as String;

        if (overwrite || !existingNames.contains(name)) {
          final newId = await _db.insertWidget(
            CustomWidgetsCompanion.insert(name: name, fieldType: fieldType),
          );
          idMap[oldId] = newId;
          widgetsAdded++;
        } else {
          idMap[oldId] = nameToId[name]!;
        }
      }

      var eventsAdded = 0;
      for (final eMap in rawEvents) {
        final oldWidgetId = (eMap['widgetId'] as num).toInt();
        final newWidgetId = idMap[oldWidgetId];
        if (newWidgetId == null) continue;

        final value = eMap['value'] as String;
        final timestamp =
            DateTime.tryParse(eMap['timestamp'] as String) ?? DateTime.now();

        await _db.insertEvent(
          TrackingEventsCompanion.insert(
            widgetId: newWidgetId,
            value: value,
            timestamp: drift.Value(timestamp),
          ),
        );
        eventsAdded++;
      }

      return ImportResult(widgetsAdded: widgetsAdded, eventsAdded: eventsAdded);
    } catch (e) {
      return ImportResult(error: 'Import failed: $e');
    }
  }

  Future<void> _clearAll() async {
    final widgets = await _db.getAllWidgets();
    for (final w in widgets) {
      await _db.clearEventsForWidget(w.id);
      await _db.deleteWidget(w.id);
    }
  }
}
