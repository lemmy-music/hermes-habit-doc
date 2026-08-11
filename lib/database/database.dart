// ignore_for_file: unnecessary_import
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

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

/// Days that the user explicitly marked for later analysis.
///
/// Only the date (without time of day) is relevant; [label] is reserved for
/// future use (the user currently marks days without entering any text).
class MarkedDays extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime().unique()();
  TextColumn get label => text().nullable()();
}

// ─── Database ────────────────────────────────────────────────────────────────

/// Web-compatible Drift database.
///
/// Uses [drift_flutter]'s [driftDatabase] which automatically selects:
/// - Native platforms (Android, iOS, macOS, Windows, Linux): sqlite3 file-based DB
/// - Web platform: IndexedDB-backed storage (no dart:ffi, no WASM required for
///   basic support — completely safe in the browser)
@DriftDatabase(tables: [CustomWidgets, TrackingEvents, MarkedDays])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // v1 → v2: new MarkedDays table
          if (from < 2) {
            await m.createTable(markedDays);
          }
        },
      );

  // ── Connection factory ────────────────────────────────────────────────────

  /// Platform-aware connection factory.
  ///
  /// [driftDatabase] from package:drift_flutter handles web vs. native:
  ///   - On native: opens a sqlite3 file in the documents directory.
  ///   - On web:    uses WASM + IndexedDB storage (no dart:ffi, no dart:io).
  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'habit_doc_db',
      web: kIsWeb
          ? DriftWebOptions(
              sqlite3Wasm: Uri.parse('sqlite3.wasm'),
              driftWorker: Uri.parse('drift_worker.js'),
            )
          : null,
    );
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

  Future<List<TrackingEvent>> getAllEvents() =>
      (select(trackingEvents)
            ..orderBy([(t) => OrderingTerm.desc(t.timestamp)]))
          .get();

  // ── MarkedDays CRUD ──────────────────────────────────────────────────────

  Future<List<MarkedDay>> getAllMarkedDays() => select(markedDays).get();

  Stream<List<MarkedDay>> watchAllMarkedDays() => select(markedDays).watch();

  Future<MarkedDay?> getMarkedDayByDate(DateTime date) =>
      (select(markedDays)..where((t) => t.date.equals(date)))
          .getSingleOrNull();

  Future<int> insertMarkedDay(MarkedDaysCompanion day) =>
      into(markedDays).insert(day);

  Future<int> deleteMarkedDay(int id) =>
      (delete(markedDays)..where((t) => t.id.equals(id))).go();
}
