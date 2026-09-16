// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ReadCacheEntriesTable extends ReadCacheEntries
    with TableInfo<$ReadCacheEntriesTable, ReadCacheEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReadCacheEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payloadMeta =
      const VerificationMeta('payload');
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
      'payload', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fetchedAtMeta =
      const VerificationMeta('fetchedAt');
  @override
  late final GeneratedColumn<String> fetchedAt = GeneratedColumn<String>(
      'fetched_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [key, payload, fetchedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'read_cache_entries';
  @override
  VerificationContext validateIntegrity(Insertable<ReadCacheEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(_payloadMeta,
          payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta));
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(_fetchedAtMeta,
          fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta));
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  ReadCacheEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReadCacheEntry(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      payload: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload'])!,
      fetchedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}fetched_at'])!,
    );
  }

  @override
  $ReadCacheEntriesTable createAlias(String alias) {
    return $ReadCacheEntriesTable(attachedDatabase, alias);
  }
}

class ReadCacheEntry extends DataClass implements Insertable<ReadCacheEntry> {
  final String key;
  final String payload;
  final String fetchedAt;
  const ReadCacheEntry(
      {required this.key, required this.payload, required this.fetchedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['payload'] = Variable<String>(payload);
    map['fetched_at'] = Variable<String>(fetchedAt);
    return map;
  }

  ReadCacheEntriesCompanion toCompanion(bool nullToAbsent) {
    return ReadCacheEntriesCompanion(
      key: Value(key),
      payload: Value(payload),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory ReadCacheEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReadCacheEntry(
      key: serializer.fromJson<String>(json['key']),
      payload: serializer.fromJson<String>(json['payload']),
      fetchedAt: serializer.fromJson<String>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'payload': serializer.toJson<String>(payload),
      'fetchedAt': serializer.toJson<String>(fetchedAt),
    };
  }

  ReadCacheEntry copyWith({String? key, String? payload, String? fetchedAt}) =>
      ReadCacheEntry(
        key: key ?? this.key,
        payload: payload ?? this.payload,
        fetchedAt: fetchedAt ?? this.fetchedAt,
      );
  ReadCacheEntry copyWithCompanion(ReadCacheEntriesCompanion data) {
    return ReadCacheEntry(
      key: data.key.present ? data.key.value : this.key,
      payload: data.payload.present ? data.payload.value : this.payload,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReadCacheEntry(')
          ..write('key: $key, ')
          ..write('payload: $payload, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, payload, fetchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReadCacheEntry &&
          other.key == this.key &&
          other.payload == this.payload &&
          other.fetchedAt == this.fetchedAt);
}

class ReadCacheEntriesCompanion extends UpdateCompanion<ReadCacheEntry> {
  final Value<String> key;
  final Value<String> payload;
  final Value<String> fetchedAt;
  final Value<int> rowid;
  const ReadCacheEntriesCompanion({
    this.key = const Value.absent(),
    this.payload = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReadCacheEntriesCompanion.insert({
    required String key,
    required String payload,
    required String fetchedAt,
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        payload = Value(payload),
        fetchedAt = Value(fetchedAt);
  static Insertable<ReadCacheEntry> custom({
    Expression<String>? key,
    Expression<String>? payload,
    Expression<String>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (payload != null) 'payload': payload,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReadCacheEntriesCompanion copyWith(
      {Value<String>? key,
      Value<String>? payload,
      Value<String>? fetchedAt,
      Value<int>? rowid}) {
    return ReadCacheEntriesCompanion(
      key: key ?? this.key,
      payload: payload ?? this.payload,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<String>(fetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReadCacheEntriesCompanion(')
          ..write('key: $key, ')
          ..write('payload: $payload, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ReadCacheEntriesTable readCacheEntries =
      $ReadCacheEntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [readCacheEntries];
}

typedef $$ReadCacheEntriesTableCreateCompanionBuilder
    = ReadCacheEntriesCompanion Function({
  required String key,
  required String payload,
  required String fetchedAt,
  Value<int> rowid,
});
typedef $$ReadCacheEntriesTableUpdateCompanionBuilder
    = ReadCacheEntriesCompanion Function({
  Value<String> key,
  Value<String> payload,
  Value<String> fetchedAt,
  Value<int> rowid,
});

class $$ReadCacheEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $ReadCacheEntriesTable> {
  $$ReadCacheEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fetchedAt => $composableBuilder(
      column: $table.fetchedAt, builder: (column) => ColumnFilters(column));
}

class $$ReadCacheEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $ReadCacheEntriesTable> {
  $$ReadCacheEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fetchedAt => $composableBuilder(
      column: $table.fetchedAt, builder: (column) => ColumnOrderings(column));
}

class $$ReadCacheEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReadCacheEntriesTable> {
  $$ReadCacheEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$ReadCacheEntriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ReadCacheEntriesTable,
    ReadCacheEntry,
    $$ReadCacheEntriesTableFilterComposer,
    $$ReadCacheEntriesTableOrderingComposer,
    $$ReadCacheEntriesTableAnnotationComposer,
    $$ReadCacheEntriesTableCreateCompanionBuilder,
    $$ReadCacheEntriesTableUpdateCompanionBuilder,
    (
      ReadCacheEntry,
      BaseReferences<_$AppDatabase, $ReadCacheEntriesTable, ReadCacheEntry>
    ),
    ReadCacheEntry,
    PrefetchHooks Function()> {
  $$ReadCacheEntriesTableTableManager(
      _$AppDatabase db, $ReadCacheEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReadCacheEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReadCacheEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReadCacheEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> payload = const Value.absent(),
            Value<String> fetchedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ReadCacheEntriesCompanion(
            key: key,
            payload: payload,
            fetchedAt: fetchedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required String payload,
            required String fetchedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              ReadCacheEntriesCompanion.insert(
            key: key,
            payload: payload,
            fetchedAt: fetchedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ReadCacheEntriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ReadCacheEntriesTable,
    ReadCacheEntry,
    $$ReadCacheEntriesTableFilterComposer,
    $$ReadCacheEntriesTableOrderingComposer,
    $$ReadCacheEntriesTableAnnotationComposer,
    $$ReadCacheEntriesTableCreateCompanionBuilder,
    $$ReadCacheEntriesTableUpdateCompanionBuilder,
    (
      ReadCacheEntry,
      BaseReferences<_$AppDatabase, $ReadCacheEntriesTable, ReadCacheEntry>
    ),
    ReadCacheEntry,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ReadCacheEntriesTableTableManager get readCacheEntries =>
      $$ReadCacheEntriesTableTableManager(_db, _db.readCacheEntries);
}
