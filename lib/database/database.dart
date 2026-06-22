import 'dart:async';
import 'package:drift/drift.dart';

// Tables
class CustomWidgets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get fieldType => text()(); // 'number', 'slider', 'checkbox'
  DateTimeColumn get createdAt => dateTime()();
}

class TrackingEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get widgetId => integer()();
  TextColumn get value => text()(); // JSON or string representation
  DateTimeColumn get timestamp => dateTime()();
}

// TODO: Generate with build_runner once Drift is properly integrated
// For now, placeholder
class AppDatabase {
  Future<List<dynamic>> getAllWidgets() async => [];
  Future<void> insertWidget(String name, String fieldType) async {}
  Future<void> insertEvent(int widgetId, dynamic value, DateTime timestamp) async {}
}
