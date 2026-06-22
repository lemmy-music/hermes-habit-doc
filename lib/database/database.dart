// ignore_for_file: unnecessary_import
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

// ─── Tables ─────────────────────────────────────────────────────────────────

class CustomWidgets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get fieldType => text()(); // 'number', 'slider', 'checkbox'
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class TrackingEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get widgetId => integer().references(CustomWidgets, #id)();
  TextColumn get value => text()();
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
}

// ─── Database ────────────────────────────────────────────────────────────────

/// Web-compatible Drift database.
///
/// Uses [drift_flutter]'s [driftDatabase] which automatically selects:
/// - Native platforms (Android, iOS, macOS, Windows, Linux): sqlite3 file-based DB
/// - Web platform: IndexedDB-backed storage (no dart:ffi, no WASM required for
///   basic support — completely safe in the browser)
@DriftDatabase(tables: [CustomWidgets, TrackingEvents])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  // ── Connection factory ────────────────────────────────────────────────────

  /// Platform-aware connection factory.
  ///
  /// [driftDatabase] from package:drift_flutter handles web vs. native:
  ///   - On native: opens a sqlite3 file in the documents directory.
  ///   - On web:    uses IndexedDB storage (no dart:ffi, no dart:io).
  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'habit_doc_db');
  }

  // ── CustomWidgets CRUD ────────────────────────────────────────────────────

  Future<List<CustomWidget>> getAllWidgets() =>
      (select(customWidgets)
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  Stream<List<CustomWidget>> watchAllWidgets() =>
      (select(customWidgets)
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  Future<CustomWidget?> getWidgetById(int id) =>
      (select(customWidgets)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insertWidget(CustomWidgetsCompanion widget) =>
      into(customWidgets).insert(widget);

  Future<bool> updateWidget(CustomWidgetsCompanion widget) =>
      update(customWidgets).replace(widget);

  Future<int> deleteWidget(int id) =>
      (delete(customWidgets)..where((t) => t.id.equals(id))).go();

  // ── TrackingEvents CRUD ───────────────────────────────────────────────────

  Future<List<TrackingEvent>> getEventsForWidget(int widgetId) =>
      (select(trackingEvents)
            ..where((t) => t.widgetId.equals(widgetId))
            ..orderBy([(t) => OrderingTerm.desc(t.timestamp)]))
          .get();

  Stream<List<TrackingEvent>> watchEventsForWidget(int widgetId) =>
      (select(trackingEvents)
            ..where((t) => t.widgetId.equals(widgetId))
            ..orderBy([(t) => OrderingTerm.desc(t.timestamp)]))
          .watch();

  Future<int> insertEvent(TrackingEventsCompanion event) =>
      into(trackingEvents).insert(event);

  Future<int> deleteEvent(int id) =>
      (delete(trackingEvents)..where((t) => t.id.equals(id))).go();

  Future<int> clearEventsForWidget(int widgetId) =>
      (delete(trackingEvents)..where((t) => t.widgetId.equals(widgetId))).go();
}
