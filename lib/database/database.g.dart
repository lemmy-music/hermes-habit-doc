// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $CustomWidgetsTable extends CustomWidgets
    with TableInfo<$CustomWidgetsTable, CustomWidget> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomWidgetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fieldTypeMeta =
      const VerificationMeta('fieldType');
  @override
  late final GeneratedColumn<String> fieldType = GeneratedColumn<String>(
      'field_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [id, name, fieldType, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'custom_widgets';
  @override
  VerificationContext validateIntegrity(Insertable<CustomWidget> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('field_type')) {
      context.handle(_fieldTypeMeta,
          fieldType.isAcceptableOrUnknown(data['field_type']!, _fieldTypeMeta));
    } else if (isInserting) {
      context.missing(_fieldTypeMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CustomWidget map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomWidget(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      fieldType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}field_type'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $CustomWidgetsTable createAlias(String alias) {
    return $CustomWidgetsTable(attachedDatabase, alias);
  }
}

class CustomWidget extends DataClass implements Insertable<CustomWidget> {
  final int id;
  final String name;
  final String fieldType;
  final DateTime createdAt;
  const CustomWidget(
      {required this.id,
      required this.name,
      required this.fieldType,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['field_type'] = Variable<String>(fieldType);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CustomWidgetsCompanion toCompanion(bool nullToAbsent) {
    return CustomWidgetsCompanion(
      id: Value(id),
      name: Value(name),
      fieldType: Value(fieldType),
      createdAt: Value(createdAt),
    );
  }

  factory CustomWidget.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomWidget(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      fieldType: serializer.fromJson<String>(json['fieldType']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'fieldType': serializer.toJson<String>(fieldType),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  CustomWidget copyWith(
          {int? id, String? name, String? fieldType, DateTime? createdAt}) =>
      CustomWidget(
        id: id ?? this.id,
        name: name ?? this.name,
        fieldType: fieldType ?? this.fieldType,
        createdAt: createdAt ?? this.createdAt,
      );
  CustomWidget copyWithCompanion(CustomWidgetsCompanion data) {
    return CustomWidget(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      fieldType: data.fieldType.present ? data.fieldType.value : this.fieldType,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomWidget(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('fieldType: $fieldType, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, fieldType, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomWidget &&
          other.id == this.id &&
          other.name == this.name &&
          other.fieldType == this.fieldType &&
          other.createdAt == this.createdAt);
}

class CustomWidgetsCompanion extends UpdateCompanion<CustomWidget> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> fieldType;
  final Value<DateTime> createdAt;
  const CustomWidgetsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.fieldType = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  CustomWidgetsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String fieldType,
    this.createdAt = const Value.absent(),
  })  : name = Value(name),
        fieldType = Value(fieldType);
  static Insertable<CustomWidget> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? fieldType,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (fieldType != null) 'field_type': fieldType,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  CustomWidgetsCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String>? fieldType,
      Value<DateTime>? createdAt}) {
    return CustomWidgetsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      fieldType: fieldType ?? this.fieldType,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (fieldType.present) {
      map['field_type'] = Variable<String>(fieldType.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomWidgetsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('fieldType: $fieldType, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $TrackingEventsTable extends TrackingEvents
    with TableInfo<$TrackingEventsTable, TrackingEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrackingEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _widgetIdMeta =
      const VerificationMeta('widgetId');
  @override
  late final GeneratedColumn<int> widgetId = GeneratedColumn<int>(
      'widget_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _timestampMeta =
      const VerificationMeta('timestamp');
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
      'timestamp', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [id, widgetId, value, timestamp];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tracking_events';
  @override
  VerificationContext validateIntegrity(Insertable<TrackingEvent> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('widget_id')) {
      context.handle(_widgetIdMeta,
          widgetId.isAcceptableOrUnknown(data['widget_id']!, _widgetIdMeta));
    } else if (isInserting) {
      context.missing(_widgetIdMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TrackingEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TrackingEvent(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      widgetId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}widget_id'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}timestamp'])!,
    );
  }

  @override
  $TrackingEventsTable createAlias(String alias) {
    return $TrackingEventsTable(attachedDatabase, alias);
  }
}

class TrackingEvent extends DataClass implements Insertable<TrackingEvent> {
  final int id;
  final int widgetId;
  final String value;
  final DateTime timestamp;
  const TrackingEvent(
      {required this.id,
      required this.widgetId,
      required this.value,
      required this.timestamp});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['widget_id'] = Variable<int>(widgetId);
    map['value'] = Variable<String>(value);
    map['timestamp'] = Variable<DateTime>(timestamp);
    return map;
  }

  TrackingEventsCompanion toCompanion(bool nullToAbsent) {
    return TrackingEventsCompanion(
      id: Value(id),
      widgetId: Value(widgetId),
      value: Value(value),
      timestamp: Value(timestamp),
    );
  }

  factory TrackingEvent.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TrackingEvent(
      id: serializer.fromJson<int>(json['id']),
      widgetId: serializer.fromJson<int>(json['widgetId']),
      value: serializer.fromJson<String>(json['value']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'widgetId': serializer.toJson<int>(widgetId),
      'value': serializer.toJson<String>(value),
      'timestamp': serializer.toJson<DateTime>(timestamp),
    };
  }

  TrackingEvent copyWith(
          {int? id, int? widgetId, String? value, DateTime? timestamp}) =>
      TrackingEvent(
        id: id ?? this.id,
        widgetId: widgetId ?? this.widgetId,
        value: value ?? this.value,
        timestamp: timestamp ?? this.timestamp,
      );
  TrackingEvent copyWithCompanion(TrackingEventsCompanion data) {
    return TrackingEvent(
      id: data.id.present ? data.id.value : this.id,
      widgetId: data.widgetId.present ? data.widgetId.value : this.widgetId,
      value: data.value.present ? data.value.value : this.value,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrackingEvent(')
          ..write('id: $id, ')
          ..write('widgetId: $widgetId, ')
          ..write('value: $value, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, widgetId, value, timestamp);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrackingEvent &&
          other.id == this.id &&
          other.widgetId == this.widgetId &&
          other.value == this.value &&
          other.timestamp == this.timestamp);
}

class TrackingEventsCompanion extends UpdateCompanion<TrackingEvent> {
  final Value<int> id;
  final Value<int> widgetId;
  final Value<String> value;
  final Value<DateTime> timestamp;
  const TrackingEventsCompanion({
    this.id = const Value.absent(),
    this.widgetId = const Value.absent(),
    this.value = const Value.absent(),
    this.timestamp = const Value.absent(),
  });
  TrackingEventsCompanion.insert({
    this.id = const Value.absent(),
    required int widgetId,
    required String value,
    this.timestamp = const Value.absent(),
  })  : widgetId = Value(widgetId),
        value = Value(value);
  static Insertable<TrackingEvent> custom({
    Expression<int>? id,
    Expression<int>? widgetId,
    Expression<String>? value,
    Expression<DateTime>? timestamp,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (widgetId != null) 'widget_id': widgetId,
      if (value != null) 'value': value,
      if (timestamp != null) 'timestamp': timestamp,
    });
  }

  TrackingEventsCompanion copyWith(
      {Value<int>? id,
      Value<int>? widgetId,
      Value<String>? value,
      Value<DateTime>? timestamp}) {
    return TrackingEventsCompanion(
      id: id ?? this.id,
      widgetId: widgetId ?? this.widgetId,
      value: value ?? this.value,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (widgetId.present) {
      map['widget_id'] = Variable<int>(widgetId.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrackingEventsCompanion(')
          ..write('id: $id, ')
          ..write('widgetId: $widgetId, ')
          ..write('value: $value, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CustomWidgetsTable customWidgets = $CustomWidgetsTable(this);
  late final $TrackingEventsTable trackingEvents = $TrackingEventsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [customWidgets, trackingEvents];
}

typedef $$CustomWidgetsTableCreateCompanionBuilder = CustomWidgetsCompanion
    Function({
  Value<int> id,
  required String name,
  required String fieldType,
  Value<DateTime> createdAt,
});
typedef $$CustomWidgetsTableUpdateCompanionBuilder = CustomWidgetsCompanion
    Function({
  Value<int> id,
  Value<String> name,
  Value<String> fieldType,
  Value<DateTime> createdAt,
});

class $$CustomWidgetsTableFilterComposer
    extends Composer<_$AppDatabase, $CustomWidgetsTable> {
  $$CustomWidgetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fieldType => $composableBuilder(
      column: $table.fieldType, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$CustomWidgetsTableOrderingComposer
    extends Composer<_$AppDatabase, $CustomWidgetsTable> {
  $$CustomWidgetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fieldType => $composableBuilder(
      column: $table.fieldType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$CustomWidgetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CustomWidgetsTable> {
  $$CustomWidgetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get fieldType =>
      $composableBuilder(column: $table.fieldType, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$CustomWidgetsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CustomWidgetsTable,
    CustomWidget,
    $$CustomWidgetsTableFilterComposer,
    $$CustomWidgetsTableOrderingComposer,
    $$CustomWidgetsTableAnnotationComposer,
    $$CustomWidgetsTableCreateCompanionBuilder,
    $$CustomWidgetsTableUpdateCompanionBuilder,
    (
      CustomWidget,
      BaseReferences<_$AppDatabase, $CustomWidgetsTable, CustomWidget>
    ),
    CustomWidget,
    PrefetchHooks Function()> {
  $$CustomWidgetsTableTableManager(_$AppDatabase db, $CustomWidgetsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomWidgetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CustomWidgetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CustomWidgetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> fieldType = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              CustomWidgetsCompanion(
            id: id,
            name: name,
            fieldType: fieldType,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            required String fieldType,
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              CustomWidgetsCompanion.insert(
            id: id,
            name: name,
            fieldType: fieldType,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CustomWidgetsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CustomWidgetsTable,
    CustomWidget,
    $$CustomWidgetsTableFilterComposer,
    $$CustomWidgetsTableOrderingComposer,
    $$CustomWidgetsTableAnnotationComposer,
    $$CustomWidgetsTableCreateCompanionBuilder,
    $$CustomWidgetsTableUpdateCompanionBuilder,
    (
      CustomWidget,
      BaseReferences<_$AppDatabase, $CustomWidgetsTable, CustomWidget>
    ),
    CustomWidget,
    PrefetchHooks Function()>;
typedef $$TrackingEventsTableCreateCompanionBuilder = TrackingEventsCompanion
    Function({
  Value<int> id,
  required int widgetId,
  required String value,
  Value<DateTime> timestamp,
});
typedef $$TrackingEventsTableUpdateCompanionBuilder = TrackingEventsCompanion
    Function({
  Value<int> id,
  Value<int> widgetId,
  Value<String> value,
  Value<DateTime> timestamp,
});

class $$TrackingEventsTableFilterComposer
    extends Composer<_$AppDatabase, $TrackingEventsTable> {
  $$TrackingEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get widgetId => $composableBuilder(
      column: $table.widgetId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnFilters(column));
}

class $$TrackingEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $TrackingEventsTable> {
  $$TrackingEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get widgetId => $composableBuilder(
      column: $table.widgetId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnOrderings(column));
}

class $$TrackingEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TrackingEventsTable> {
  $$TrackingEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get widgetId =>
      $composableBuilder(column: $table.widgetId, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);
}

class $$TrackingEventsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TrackingEventsTable,
    TrackingEvent,
    $$TrackingEventsTableFilterComposer,
    $$TrackingEventsTableOrderingComposer,
    $$TrackingEventsTableAnnotationComposer,
    $$TrackingEventsTableCreateCompanionBuilder,
    $$TrackingEventsTableUpdateCompanionBuilder,
    (
      TrackingEvent,
      BaseReferences<_$AppDatabase, $TrackingEventsTable, TrackingEvent>
    ),
    TrackingEvent,
    PrefetchHooks Function()> {
  $$TrackingEventsTableTableManager(
      _$AppDatabase db, $TrackingEventsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TrackingEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TrackingEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TrackingEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> widgetId = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<DateTime> timestamp = const Value.absent(),
          }) =>
              TrackingEventsCompanion(
            id: id,
            widgetId: widgetId,
            value: value,
            timestamp: timestamp,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int widgetId,
            required String value,
            Value<DateTime> timestamp = const Value.absent(),
          }) =>
              TrackingEventsCompanion.insert(
            id: id,
            widgetId: widgetId,
            value: value,
            timestamp: timestamp,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TrackingEventsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TrackingEventsTable,
    TrackingEvent,
    $$TrackingEventsTableFilterComposer,
    $$TrackingEventsTableOrderingComposer,
    $$TrackingEventsTableAnnotationComposer,
    $$TrackingEventsTableCreateCompanionBuilder,
    $$TrackingEventsTableUpdateCompanionBuilder,
    (
      TrackingEvent,
      BaseReferences<_$AppDatabase, $TrackingEventsTable, TrackingEvent>
    ),
    TrackingEvent,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CustomWidgetsTableTableManager get customWidgets =>
      $$CustomWidgetsTableTableManager(_db, _db.customWidgets);
  $$TrackingEventsTableTableManager get trackingEvents =>
      $$TrackingEventsTableTableManager(_db, _db.trackingEvents);
}
