import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
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

// ─── Database ────────────────────────────────────────────────────────────────

@DriftDatabase(tables: [CustomWidgets, TrackingEvents])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  // ── CustomWidgets CRUD ────────────────────────────────────────────────────

  Future<List<CustomWidget>> getAllWidgets() =>
      (select(customWidgets)
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  Stream<List<CustomWidget>> watchAllWidgets() =>
      (select(customWidgets)
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

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

  Future<int> insertEvent(TrackingEventsCompanion event) =>
      into(trackingEvents).insert(event);
}

// ─── Connection factory ───────────────────────────────────────────────────────

QueryExecutor _openConnection() {
  if (kIsWeb) {
    // Web: in-memory SQLite (no persistence yet — add drift_flutter_libs for web)
    return NativeDatabase.memory();
  }
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'habit_doc.db'));
    return NativeDatabase(file);
  });
}
