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

class $InventoryItemsTable extends InventoryItems
    with TableInfo<$InventoryItemsTable, InventoryItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InventoryItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _householdIdMeta =
      const VerificationMeta('householdId');
  @override
  late final GeneratedColumn<String> householdId = GeneratedColumn<String>(
      'household_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _quantityMeta =
      const VerificationMeta('quantity');
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
      'quantity', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
      'unit', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _displayQuantityMeta =
      const VerificationMeta('displayQuantity');
  @override
  late final GeneratedColumn<double> displayQuantity = GeneratedColumn<double>(
      'display_quantity', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _displayUnitMeta =
      const VerificationMeta('displayUnit');
  @override
  late final GeneratedColumn<String> displayUnit = GeneratedColumn<String>(
      'display_unit', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lowStockThresholdMeta =
      const VerificationMeta('lowStockThreshold');
  @override
  late final GeneratedColumn<double> lowStockThreshold =
      GeneratedColumn<double>('low_stock_threshold', aliasedName, true,
          type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _expiryDateMeta =
      const VerificationMeta('expiryDate');
  @override
  late final GeneratedColumn<String> expiryDate = GeneratedColumn<String>(
      'expiry_date', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _versionMeta =
      const VerificationMeta('version');
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
      'version', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _isLowStockMeta =
      const VerificationMeta('isLowStock');
  @override
  late final GeneratedColumn<bool> isLowStock = GeneratedColumn<bool>(
      'is_low_stock', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_low_stock" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isExpiringSoonMeta =
      const VerificationMeta('isExpiringSoon');
  @override
  late final GeneratedColumn<bool> isExpiringSoon = GeneratedColumn<bool>(
      'is_expiring_soon', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_expiring_soon" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdByMeta =
      const VerificationMeta('createdBy');
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
      'created_by', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _syncStatusMeta =
      const VerificationMeta('syncStatus');
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
      'sync_status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('SYNCED'));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        householdId,
        name,
        category,
        quantity,
        unit,
        displayQuantity,
        displayUnit,
        lowStockThreshold,
        expiryDate,
        note,
        version,
        isLowStock,
        isExpiringSoon,
        createdBy,
        createdAt,
        updatedAt,
        syncStatus
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'inventory_items';
  @override
  VerificationContext validateIntegrity(Insertable<InventoryItem> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('household_id')) {
      context.handle(
          _householdIdMeta,
          householdId.isAcceptableOrUnknown(
              data['household_id']!, _householdIdMeta));
    } else if (isInserting) {
      context.missing(_householdIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    }
    if (data.containsKey('quantity')) {
      context.handle(_quantityMeta,
          quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta));
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('unit')) {
      context.handle(
          _unitMeta, unit.isAcceptableOrUnknown(data['unit']!, _unitMeta));
    } else if (isInserting) {
      context.missing(_unitMeta);
    }
    if (data.containsKey('display_quantity')) {
      context.handle(
          _displayQuantityMeta,
          displayQuantity.isAcceptableOrUnknown(
              data['display_quantity']!, _displayQuantityMeta));
    }
    if (data.containsKey('display_unit')) {
      context.handle(
          _displayUnitMeta,
          displayUnit.isAcceptableOrUnknown(
              data['display_unit']!, _displayUnitMeta));
    }
    if (data.containsKey('low_stock_threshold')) {
      context.handle(
          _lowStockThresholdMeta,
          lowStockThreshold.isAcceptableOrUnknown(
              data['low_stock_threshold']!, _lowStockThresholdMeta));
    }
    if (data.containsKey('expiry_date')) {
      context.handle(
          _expiryDateMeta,
          expiryDate.isAcceptableOrUnknown(
              data['expiry_date']!, _expiryDateMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('version')) {
      context.handle(_versionMeta,
          version.isAcceptableOrUnknown(data['version']!, _versionMeta));
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('is_low_stock')) {
      context.handle(
          _isLowStockMeta,
          isLowStock.isAcceptableOrUnknown(
              data['is_low_stock']!, _isLowStockMeta));
    }
    if (data.containsKey('is_expiring_soon')) {
      context.handle(
          _isExpiringSoonMeta,
          isExpiringSoon.isAcceptableOrUnknown(
              data['is_expiring_soon']!, _isExpiringSoonMeta));
    }
    if (data.containsKey('created_by')) {
      context.handle(_createdByMeta,
          createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta));
    } else if (isInserting) {
      context.missing(_createdByMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
          _syncStatusMeta,
          syncStatus.isAcceptableOrUnknown(
              data['sync_status']!, _syncStatusMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InventoryItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InventoryItem(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      householdId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}household_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category']),
      quantity: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}quantity'])!,
      unit: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unit'])!,
      displayQuantity: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}display_quantity']),
      displayUnit: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}display_unit']),
      lowStockThreshold: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}low_stock_threshold']),
      expiryDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}expiry_date']),
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
      version: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}version'])!,
      isLowStock: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_low_stock'])!,
      isExpiringSoon: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_expiring_soon'])!,
      createdBy: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_by'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}updated_at'])!,
      syncStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_status'])!,
    );
  }

  @override
  $InventoryItemsTable createAlias(String alias) {
    return $InventoryItemsTable(attachedDatabase, alias);
  }
}

class InventoryItem extends DataClass implements Insertable<InventoryItem> {
  final String id;
  final String householdId;
  final String name;
  final String? category;
  final double quantity;
  final String unit;
  final double? displayQuantity;
  final String? displayUnit;
  final double? lowStockThreshold;
  final String? expiryDate;
  final String? note;
  final int version;
  final bool isLowStock;
  final bool isExpiringSoon;
  final String createdBy;
  final String createdAt;
  final String updatedAt;
  final String syncStatus;
  const InventoryItem(
      {required this.id,
      required this.householdId,
      required this.name,
      this.category,
      required this.quantity,
      required this.unit,
      this.displayQuantity,
      this.displayUnit,
      this.lowStockThreshold,
      this.expiryDate,
      this.note,
      required this.version,
      required this.isLowStock,
      required this.isExpiringSoon,
      required this.createdBy,
      required this.createdAt,
      required this.updatedAt,
      required this.syncStatus});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['household_id'] = Variable<String>(householdId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    map['quantity'] = Variable<double>(quantity);
    map['unit'] = Variable<String>(unit);
    if (!nullToAbsent || displayQuantity != null) {
      map['display_quantity'] = Variable<double>(displayQuantity);
    }
    if (!nullToAbsent || displayUnit != null) {
      map['display_unit'] = Variable<String>(displayUnit);
    }
    if (!nullToAbsent || lowStockThreshold != null) {
      map['low_stock_threshold'] = Variable<double>(lowStockThreshold);
    }
    if (!nullToAbsent || expiryDate != null) {
      map['expiry_date'] = Variable<String>(expiryDate);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['version'] = Variable<int>(version);
    map['is_low_stock'] = Variable<bool>(isLowStock);
    map['is_expiring_soon'] = Variable<bool>(isExpiringSoon);
    map['created_by'] = Variable<String>(createdBy);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    map['sync_status'] = Variable<String>(syncStatus);
    return map;
  }

  InventoryItemsCompanion toCompanion(bool nullToAbsent) {
    return InventoryItemsCompanion(
      id: Value(id),
      householdId: Value(householdId),
      name: Value(name),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      quantity: Value(quantity),
      unit: Value(unit),
      displayQuantity: displayQuantity == null && nullToAbsent
          ? const Value.absent()
          : Value(displayQuantity),
      displayUnit: displayUnit == null && nullToAbsent
          ? const Value.absent()
          : Value(displayUnit),
      lowStockThreshold: lowStockThreshold == null && nullToAbsent
          ? const Value.absent()
          : Value(lowStockThreshold),
      expiryDate: expiryDate == null && nullToAbsent
          ? const Value.absent()
          : Value(expiryDate),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      version: Value(version),
      isLowStock: Value(isLowStock),
      isExpiringSoon: Value(isExpiringSoon),
      createdBy: Value(createdBy),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncStatus: Value(syncStatus),
    );
  }

  factory InventoryItem.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InventoryItem(
      id: serializer.fromJson<String>(json['id']),
      householdId: serializer.fromJson<String>(json['householdId']),
      name: serializer.fromJson<String>(json['name']),
      category: serializer.fromJson<String?>(json['category']),
      quantity: serializer.fromJson<double>(json['quantity']),
      unit: serializer.fromJson<String>(json['unit']),
      displayQuantity: serializer.fromJson<double?>(json['displayQuantity']),
      displayUnit: serializer.fromJson<String?>(json['displayUnit']),
      lowStockThreshold:
          serializer.fromJson<double?>(json['lowStockThreshold']),
      expiryDate: serializer.fromJson<String?>(json['expiryDate']),
      note: serializer.fromJson<String?>(json['note']),
      version: serializer.fromJson<int>(json['version']),
      isLowStock: serializer.fromJson<bool>(json['isLowStock']),
      isExpiringSoon: serializer.fromJson<bool>(json['isExpiringSoon']),
      createdBy: serializer.fromJson<String>(json['createdBy']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'householdId': serializer.toJson<String>(householdId),
      'name': serializer.toJson<String>(name),
      'category': serializer.toJson<String?>(category),
      'quantity': serializer.toJson<double>(quantity),
      'unit': serializer.toJson<String>(unit),
      'displayQuantity': serializer.toJson<double?>(displayQuantity),
      'displayUnit': serializer.toJson<String?>(displayUnit),
      'lowStockThreshold': serializer.toJson<double?>(lowStockThreshold),
      'expiryDate': serializer.toJson<String?>(expiryDate),
      'note': serializer.toJson<String?>(note),
      'version': serializer.toJson<int>(version),
      'isLowStock': serializer.toJson<bool>(isLowStock),
      'isExpiringSoon': serializer.toJson<bool>(isExpiringSoon),
      'createdBy': serializer.toJson<String>(createdBy),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
    };
  }

  InventoryItem copyWith(
          {String? id,
          String? householdId,
          String? name,
          Value<String?> category = const Value.absent(),
          double? quantity,
          String? unit,
          Value<double?> displayQuantity = const Value.absent(),
          Value<String?> displayUnit = const Value.absent(),
          Value<double?> lowStockThreshold = const Value.absent(),
          Value<String?> expiryDate = const Value.absent(),
          Value<String?> note = const Value.absent(),
          int? version,
          bool? isLowStock,
          bool? isExpiringSoon,
          String? createdBy,
          String? createdAt,
          String? updatedAt,
          String? syncStatus}) =>
      InventoryItem(
        id: id ?? this.id,
        householdId: householdId ?? this.householdId,
        name: name ?? this.name,
        category: category.present ? category.value : this.category,
        quantity: quantity ?? this.quantity,
        unit: unit ?? this.unit,
        displayQuantity: displayQuantity.present
            ? displayQuantity.value
            : this.displayQuantity,
        displayUnit: displayUnit.present ? displayUnit.value : this.displayUnit,
        lowStockThreshold: lowStockThreshold.present
            ? lowStockThreshold.value
            : this.lowStockThreshold,
        expiryDate: expiryDate.present ? expiryDate.value : this.expiryDate,
        note: note.present ? note.value : this.note,
        version: version ?? this.version,
        isLowStock: isLowStock ?? this.isLowStock,
        isExpiringSoon: isExpiringSoon ?? this.isExpiringSoon,
        createdBy: createdBy ?? this.createdBy,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        syncStatus: syncStatus ?? this.syncStatus,
      );
  InventoryItem copyWithCompanion(InventoryItemsCompanion data) {
    return InventoryItem(
      id: data.id.present ? data.id.value : this.id,
      householdId:
          data.householdId.present ? data.householdId.value : this.householdId,
      name: data.name.present ? data.name.value : this.name,
      category: data.category.present ? data.category.value : this.category,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unit: data.unit.present ? data.unit.value : this.unit,
      displayQuantity: data.displayQuantity.present
          ? data.displayQuantity.value
          : this.displayQuantity,
      displayUnit:
          data.displayUnit.present ? data.displayUnit.value : this.displayUnit,
      lowStockThreshold: data.lowStockThreshold.present
          ? data.lowStockThreshold.value
          : this.lowStockThreshold,
      expiryDate:
          data.expiryDate.present ? data.expiryDate.value : this.expiryDate,
      note: data.note.present ? data.note.value : this.note,
      version: data.version.present ? data.version.value : this.version,
      isLowStock:
          data.isLowStock.present ? data.isLowStock.value : this.isLowStock,
      isExpiringSoon: data.isExpiringSoon.present
          ? data.isExpiringSoon.value
          : this.isExpiringSoon,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncStatus:
          data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InventoryItem(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('quantity: $quantity, ')
          ..write('unit: $unit, ')
          ..write('displayQuantity: $displayQuantity, ')
          ..write('displayUnit: $displayUnit, ')
          ..write('lowStockThreshold: $lowStockThreshold, ')
          ..write('expiryDate: $expiryDate, ')
          ..write('note: $note, ')
          ..write('version: $version, ')
          ..write('isLowStock: $isLowStock, ')
          ..write('isExpiringSoon: $isExpiringSoon, ')
          ..write('createdBy: $createdBy, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      householdId,
      name,
      category,
      quantity,
      unit,
      displayQuantity,
      displayUnit,
      lowStockThreshold,
      expiryDate,
      note,
      version,
      isLowStock,
      isExpiringSoon,
      createdBy,
      createdAt,
      updatedAt,
      syncStatus);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InventoryItem &&
          other.id == this.id &&
          other.householdId == this.householdId &&
          other.name == this.name &&
          other.category == this.category &&
          other.quantity == this.quantity &&
          other.unit == this.unit &&
          other.displayQuantity == this.displayQuantity &&
          other.displayUnit == this.displayUnit &&
          other.lowStockThreshold == this.lowStockThreshold &&
          other.expiryDate == this.expiryDate &&
          other.note == this.note &&
          other.version == this.version &&
          other.isLowStock == this.isLowStock &&
          other.isExpiringSoon == this.isExpiringSoon &&
          other.createdBy == this.createdBy &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncStatus == this.syncStatus);
}

class InventoryItemsCompanion extends UpdateCompanion<InventoryItem> {
  final Value<String> id;
  final Value<String> householdId;
  final Value<String> name;
  final Value<String?> category;
  final Value<double> quantity;
  final Value<String> unit;
  final Value<double?> displayQuantity;
  final Value<String?> displayUnit;
  final Value<double?> lowStockThreshold;
  final Value<String?> expiryDate;
  final Value<String?> note;
  final Value<int> version;
  final Value<bool> isLowStock;
  final Value<bool> isExpiringSoon;
  final Value<String> createdBy;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<String> syncStatus;
  final Value<int> rowid;
  const InventoryItemsCompanion({
    this.id = const Value.absent(),
    this.householdId = const Value.absent(),
    this.name = const Value.absent(),
    this.category = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unit = const Value.absent(),
    this.displayQuantity = const Value.absent(),
    this.displayUnit = const Value.absent(),
    this.lowStockThreshold = const Value.absent(),
    this.expiryDate = const Value.absent(),
    this.note = const Value.absent(),
    this.version = const Value.absent(),
    this.isLowStock = const Value.absent(),
    this.isExpiringSoon = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InventoryItemsCompanion.insert({
    required String id,
    required String householdId,
    required String name,
    this.category = const Value.absent(),
    required double quantity,
    required String unit,
    this.displayQuantity = const Value.absent(),
    this.displayUnit = const Value.absent(),
    this.lowStockThreshold = const Value.absent(),
    this.expiryDate = const Value.absent(),
    this.note = const Value.absent(),
    required int version,
    this.isLowStock = const Value.absent(),
    this.isExpiringSoon = const Value.absent(),
    required String createdBy,
    required String createdAt,
    required String updatedAt,
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        householdId = Value(householdId),
        name = Value(name),
        quantity = Value(quantity),
        unit = Value(unit),
        version = Value(version),
        createdBy = Value(createdBy),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<InventoryItem> custom({
    Expression<String>? id,
    Expression<String>? householdId,
    Expression<String>? name,
    Expression<String>? category,
    Expression<double>? quantity,
    Expression<String>? unit,
    Expression<double>? displayQuantity,
    Expression<String>? displayUnit,
    Expression<double>? lowStockThreshold,
    Expression<String>? expiryDate,
    Expression<String>? note,
    Expression<int>? version,
    Expression<bool>? isLowStock,
    Expression<bool>? isExpiringSoon,
    Expression<String>? createdBy,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<String>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (householdId != null) 'household_id': householdId,
      if (name != null) 'name': name,
      if (category != null) 'category': category,
      if (quantity != null) 'quantity': quantity,
      if (unit != null) 'unit': unit,
      if (displayQuantity != null) 'display_quantity': displayQuantity,
      if (displayUnit != null) 'display_unit': displayUnit,
      if (lowStockThreshold != null) 'low_stock_threshold': lowStockThreshold,
      if (expiryDate != null) 'expiry_date': expiryDate,
      if (note != null) 'note': note,
      if (version != null) 'version': version,
      if (isLowStock != null) 'is_low_stock': isLowStock,
      if (isExpiringSoon != null) 'is_expiring_soon': isExpiringSoon,
      if (createdBy != null) 'created_by': createdBy,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InventoryItemsCompanion copyWith(
      {Value<String>? id,
      Value<String>? householdId,
      Value<String>? name,
      Value<String?>? category,
      Value<double>? quantity,
      Value<String>? unit,
      Value<double?>? displayQuantity,
      Value<String?>? displayUnit,
      Value<double?>? lowStockThreshold,
      Value<String?>? expiryDate,
      Value<String?>? note,
      Value<int>? version,
      Value<bool>? isLowStock,
      Value<bool>? isExpiringSoon,
      Value<String>? createdBy,
      Value<String>? createdAt,
      Value<String>? updatedAt,
      Value<String>? syncStatus,
      Value<int>? rowid}) {
    return InventoryItemsCompanion(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      displayQuantity: displayQuantity ?? this.displayQuantity,
      displayUnit: displayUnit ?? this.displayUnit,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      expiryDate: expiryDate ?? this.expiryDate,
      note: note ?? this.note,
      version: version ?? this.version,
      isLowStock: isLowStock ?? this.isLowStock,
      isExpiringSoon: isExpiringSoon ?? this.isExpiringSoon,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (householdId.present) {
      map['household_id'] = Variable<String>(householdId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (displayQuantity.present) {
      map['display_quantity'] = Variable<double>(displayQuantity.value);
    }
    if (displayUnit.present) {
      map['display_unit'] = Variable<String>(displayUnit.value);
    }
    if (lowStockThreshold.present) {
      map['low_stock_threshold'] = Variable<double>(lowStockThreshold.value);
    }
    if (expiryDate.present) {
      map['expiry_date'] = Variable<String>(expiryDate.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (isLowStock.present) {
      map['is_low_stock'] = Variable<bool>(isLowStock.value);
    }
    if (isExpiringSoon.present) {
      map['is_expiring_soon'] = Variable<bool>(isExpiringSoon.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InventoryItemsCompanion(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('quantity: $quantity, ')
          ..write('unit: $unit, ')
          ..write('displayQuantity: $displayQuantity, ')
          ..write('displayUnit: $displayUnit, ')
          ..write('lowStockThreshold: $lowStockThreshold, ')
          ..write('expiryDate: $expiryDate, ')
          ..write('note: $note, ')
          ..write('version: $version, ')
          ..write('isLowStock: $isLowStock, ')
          ..write('isExpiringSoon: $isExpiringSoon, ')
          ..write('createdBy: $createdBy, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InventorySyncQueueTable extends InventorySyncQueue
    with TableInfo<$InventorySyncQueueTable, InventorySyncQueueData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InventorySyncQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _householdIdMeta =
      const VerificationMeta('householdId');
  @override
  late final GeneratedColumn<String> householdId = GeneratedColumn<String>(
      'household_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
      'item_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _operationMeta =
      const VerificationMeta('operation');
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
      'operation', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _baseVersionMeta =
      const VerificationMeta('baseVersion');
  @override
  late final GeneratedColumn<int> baseVersion = GeneratedColumn<int>(
      'base_version', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _deleteReasonMeta =
      const VerificationMeta('deleteReason');
  @override
  late final GeneratedColumn<String> deleteReason = GeneratedColumn<String>(
      'delete_reason', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        householdId,
        itemId,
        operation,
        baseVersion,
        deleteReason,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'inventory_sync_queue';
  @override
  VerificationContext validateIntegrity(
      Insertable<InventorySyncQueueData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('household_id')) {
      context.handle(
          _householdIdMeta,
          householdId.isAcceptableOrUnknown(
              data['household_id']!, _householdIdMeta));
    } else if (isInserting) {
      context.missing(_householdIdMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(_itemIdMeta,
          itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta));
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('operation')) {
      context.handle(_operationMeta,
          operation.isAcceptableOrUnknown(data['operation']!, _operationMeta));
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('base_version')) {
      context.handle(
          _baseVersionMeta,
          baseVersion.isAcceptableOrUnknown(
              data['base_version']!, _baseVersionMeta));
    } else if (isInserting) {
      context.missing(_baseVersionMeta);
    }
    if (data.containsKey('delete_reason')) {
      context.handle(
          _deleteReasonMeta,
          deleteReason.isAcceptableOrUnknown(
              data['delete_reason']!, _deleteReasonMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InventorySyncQueueData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InventorySyncQueueData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      householdId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}household_id'])!,
      itemId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}item_id'])!,
      operation: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}operation'])!,
      baseVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}base_version'])!,
      deleteReason: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}delete_reason']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $InventorySyncQueueTable createAlias(String alias) {
    return $InventorySyncQueueTable(attachedDatabase, alias);
  }
}

class InventorySyncQueueData extends DataClass
    implements Insertable<InventorySyncQueueData> {
  final int id;
  final String householdId;
  final String itemId;
  final String operation;
  final int baseVersion;
  final String? deleteReason;
  final DateTime createdAt;
  const InventorySyncQueueData(
      {required this.id,
      required this.householdId,
      required this.itemId,
      required this.operation,
      required this.baseVersion,
      this.deleteReason,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['household_id'] = Variable<String>(householdId);
    map['item_id'] = Variable<String>(itemId);
    map['operation'] = Variable<String>(operation);
    map['base_version'] = Variable<int>(baseVersion);
    if (!nullToAbsent || deleteReason != null) {
      map['delete_reason'] = Variable<String>(deleteReason);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  InventorySyncQueueCompanion toCompanion(bool nullToAbsent) {
    return InventorySyncQueueCompanion(
      id: Value(id),
      householdId: Value(householdId),
      itemId: Value(itemId),
      operation: Value(operation),
      baseVersion: Value(baseVersion),
      deleteReason: deleteReason == null && nullToAbsent
          ? const Value.absent()
          : Value(deleteReason),
      createdAt: Value(createdAt),
    );
  }

  factory InventorySyncQueueData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InventorySyncQueueData(
      id: serializer.fromJson<int>(json['id']),
      householdId: serializer.fromJson<String>(json['householdId']),
      itemId: serializer.fromJson<String>(json['itemId']),
      operation: serializer.fromJson<String>(json['operation']),
      baseVersion: serializer.fromJson<int>(json['baseVersion']),
      deleteReason: serializer.fromJson<String?>(json['deleteReason']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'householdId': serializer.toJson<String>(householdId),
      'itemId': serializer.toJson<String>(itemId),
      'operation': serializer.toJson<String>(operation),
      'baseVersion': serializer.toJson<int>(baseVersion),
      'deleteReason': serializer.toJson<String?>(deleteReason),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  InventorySyncQueueData copyWith(
          {int? id,
          String? householdId,
          String? itemId,
          String? operation,
          int? baseVersion,
          Value<String?> deleteReason = const Value.absent(),
          DateTime? createdAt}) =>
      InventorySyncQueueData(
        id: id ?? this.id,
        householdId: householdId ?? this.householdId,
        itemId: itemId ?? this.itemId,
        operation: operation ?? this.operation,
        baseVersion: baseVersion ?? this.baseVersion,
        deleteReason:
            deleteReason.present ? deleteReason.value : this.deleteReason,
        createdAt: createdAt ?? this.createdAt,
      );
  InventorySyncQueueData copyWithCompanion(InventorySyncQueueCompanion data) {
    return InventorySyncQueueData(
      id: data.id.present ? data.id.value : this.id,
      householdId:
          data.householdId.present ? data.householdId.value : this.householdId,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      operation: data.operation.present ? data.operation.value : this.operation,
      baseVersion:
          data.baseVersion.present ? data.baseVersion.value : this.baseVersion,
      deleteReason: data.deleteReason.present
          ? data.deleteReason.value
          : this.deleteReason,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InventorySyncQueueData(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('itemId: $itemId, ')
          ..write('operation: $operation, ')
          ..write('baseVersion: $baseVersion, ')
          ..write('deleteReason: $deleteReason, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, householdId, itemId, operation, baseVersion, deleteReason, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InventorySyncQueueData &&
          other.id == this.id &&
          other.householdId == this.householdId &&
          other.itemId == this.itemId &&
          other.operation == this.operation &&
          other.baseVersion == this.baseVersion &&
          other.deleteReason == this.deleteReason &&
          other.createdAt == this.createdAt);
}

class InventorySyncQueueCompanion
    extends UpdateCompanion<InventorySyncQueueData> {
  final Value<int> id;
  final Value<String> householdId;
  final Value<String> itemId;
  final Value<String> operation;
  final Value<int> baseVersion;
  final Value<String?> deleteReason;
  final Value<DateTime> createdAt;
  const InventorySyncQueueCompanion({
    this.id = const Value.absent(),
    this.householdId = const Value.absent(),
    this.itemId = const Value.absent(),
    this.operation = const Value.absent(),
    this.baseVersion = const Value.absent(),
    this.deleteReason = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  InventorySyncQueueCompanion.insert({
    this.id = const Value.absent(),
    required String householdId,
    required String itemId,
    required String operation,
    required int baseVersion,
    this.deleteReason = const Value.absent(),
    required DateTime createdAt,
  })  : householdId = Value(householdId),
        itemId = Value(itemId),
        operation = Value(operation),
        baseVersion = Value(baseVersion),
        createdAt = Value(createdAt);
  static Insertable<InventorySyncQueueData> custom({
    Expression<int>? id,
    Expression<String>? householdId,
    Expression<String>? itemId,
    Expression<String>? operation,
    Expression<int>? baseVersion,
    Expression<String>? deleteReason,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (householdId != null) 'household_id': householdId,
      if (itemId != null) 'item_id': itemId,
      if (operation != null) 'operation': operation,
      if (baseVersion != null) 'base_version': baseVersion,
      if (deleteReason != null) 'delete_reason': deleteReason,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  InventorySyncQueueCompanion copyWith(
      {Value<int>? id,
      Value<String>? householdId,
      Value<String>? itemId,
      Value<String>? operation,
      Value<int>? baseVersion,
      Value<String?>? deleteReason,
      Value<DateTime>? createdAt}) {
    return InventorySyncQueueCompanion(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      itemId: itemId ?? this.itemId,
      operation: operation ?? this.operation,
      baseVersion: baseVersion ?? this.baseVersion,
      deleteReason: deleteReason ?? this.deleteReason,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (householdId.present) {
      map['household_id'] = Variable<String>(householdId.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (baseVersion.present) {
      map['base_version'] = Variable<int>(baseVersion.value);
    }
    if (deleteReason.present) {
      map['delete_reason'] = Variable<String>(deleteReason.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InventorySyncQueueCompanion(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('itemId: $itemId, ')
          ..write('operation: $operation, ')
          ..write('baseVersion: $baseVersion, ')
          ..write('deleteReason: $deleteReason, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ShoppingListItemsTable extends ShoppingListItems
    with TableInfo<$ShoppingListItemsTable, ShoppingListItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShoppingListItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _householdIdMeta =
      const VerificationMeta('householdId');
  @override
  late final GeneratedColumn<String> householdId = GeneratedColumn<String>(
      'household_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _shoppingListIdMeta =
      const VerificationMeta('shoppingListId');
  @override
  late final GeneratedColumn<String> shoppingListId = GeneratedColumn<String>(
      'shopping_list_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _quantityMeta =
      const VerificationMeta('quantity');
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
      'quantity', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
      'unit', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _displayQuantityMeta =
      const VerificationMeta('displayQuantity');
  @override
  late final GeneratedColumn<double> displayQuantity = GeneratedColumn<double>(
      'display_quantity', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _displayUnitMeta =
      const VerificationMeta('displayUnit');
  @override
  late final GeneratedColumn<String> displayUnit = GeneratedColumn<String>(
      'display_unit', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _versionMeta =
      const VerificationMeta('version');
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
      'version', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _createdByMeta =
      const VerificationMeta('createdBy');
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
      'created_by', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _syncStatusMeta =
      const VerificationMeta('syncStatus');
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
      'sync_status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('SYNCED'));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        householdId,
        shoppingListId,
        name,
        quantity,
        unit,
        displayQuantity,
        displayUnit,
        category,
        status,
        source,
        version,
        createdBy,
        createdAt,
        updatedAt,
        syncStatus
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shopping_list_items';
  @override
  VerificationContext validateIntegrity(Insertable<ShoppingListItem> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('household_id')) {
      context.handle(
          _householdIdMeta,
          householdId.isAcceptableOrUnknown(
              data['household_id']!, _householdIdMeta));
    } else if (isInserting) {
      context.missing(_householdIdMeta);
    }
    if (data.containsKey('shopping_list_id')) {
      context.handle(
          _shoppingListIdMeta,
          shoppingListId.isAcceptableOrUnknown(
              data['shopping_list_id']!, _shoppingListIdMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(_quantityMeta,
          quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta));
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('unit')) {
      context.handle(
          _unitMeta, unit.isAcceptableOrUnknown(data['unit']!, _unitMeta));
    } else if (isInserting) {
      context.missing(_unitMeta);
    }
    if (data.containsKey('display_quantity')) {
      context.handle(
          _displayQuantityMeta,
          displayQuantity.isAcceptableOrUnknown(
              data['display_quantity']!, _displayQuantityMeta));
    } else if (isInserting) {
      context.missing(_displayQuantityMeta);
    }
    if (data.containsKey('display_unit')) {
      context.handle(
          _displayUnitMeta,
          displayUnit.isAcceptableOrUnknown(
              data['display_unit']!, _displayUnitMeta));
    } else if (isInserting) {
      context.missing(_displayUnitMeta);
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('version')) {
      context.handle(_versionMeta,
          version.isAcceptableOrUnknown(data['version']!, _versionMeta));
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('created_by')) {
      context.handle(_createdByMeta,
          createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
          _syncStatusMeta,
          syncStatus.isAcceptableOrUnknown(
              data['sync_status']!, _syncStatusMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ShoppingListItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShoppingListItem(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      householdId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}household_id'])!,
      shoppingListId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}shopping_list_id']),
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      quantity: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}quantity'])!,
      unit: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unit'])!,
      displayQuantity: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}display_quantity'])!,
      displayUnit: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}display_unit'])!,
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      version: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}version'])!,
      createdBy: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_by']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}updated_at'])!,
      syncStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_status'])!,
    );
  }

  @override
  $ShoppingListItemsTable createAlias(String alias) {
    return $ShoppingListItemsTable(attachedDatabase, alias);
  }
}

class ShoppingListItem extends DataClass
    implements Insertable<ShoppingListItem> {
  final String id;
  final String householdId;
  final String? shoppingListId;
  final String name;
  final double quantity;
  final String unit;
  final double displayQuantity;
  final String displayUnit;
  final String? category;
  final String status;
  final String source;
  final int version;
  final String? createdBy;
  final String createdAt;
  final String updatedAt;
  final String syncStatus;
  const ShoppingListItem(
      {required this.id,
      required this.householdId,
      this.shoppingListId,
      required this.name,
      required this.quantity,
      required this.unit,
      required this.displayQuantity,
      required this.displayUnit,
      this.category,
      required this.status,
      required this.source,
      required this.version,
      this.createdBy,
      required this.createdAt,
      required this.updatedAt,
      required this.syncStatus});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['household_id'] = Variable<String>(householdId);
    if (!nullToAbsent || shoppingListId != null) {
      map['shopping_list_id'] = Variable<String>(shoppingListId);
    }
    map['name'] = Variable<String>(name);
    map['quantity'] = Variable<double>(quantity);
    map['unit'] = Variable<String>(unit);
    map['display_quantity'] = Variable<double>(displayQuantity);
    map['display_unit'] = Variable<String>(displayUnit);
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    map['status'] = Variable<String>(status);
    map['source'] = Variable<String>(source);
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || createdBy != null) {
      map['created_by'] = Variable<String>(createdBy);
    }
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    map['sync_status'] = Variable<String>(syncStatus);
    return map;
  }

  ShoppingListItemsCompanion toCompanion(bool nullToAbsent) {
    return ShoppingListItemsCompanion(
      id: Value(id),
      householdId: Value(householdId),
      shoppingListId: shoppingListId == null && nullToAbsent
          ? const Value.absent()
          : Value(shoppingListId),
      name: Value(name),
      quantity: Value(quantity),
      unit: Value(unit),
      displayQuantity: Value(displayQuantity),
      displayUnit: Value(displayUnit),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      status: Value(status),
      source: Value(source),
      version: Value(version),
      createdBy: createdBy == null && nullToAbsent
          ? const Value.absent()
          : Value(createdBy),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncStatus: Value(syncStatus),
    );
  }

  factory ShoppingListItem.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShoppingListItem(
      id: serializer.fromJson<String>(json['id']),
      householdId: serializer.fromJson<String>(json['householdId']),
      shoppingListId: serializer.fromJson<String?>(json['shoppingListId']),
      name: serializer.fromJson<String>(json['name']),
      quantity: serializer.fromJson<double>(json['quantity']),
      unit: serializer.fromJson<String>(json['unit']),
      displayQuantity: serializer.fromJson<double>(json['displayQuantity']),
      displayUnit: serializer.fromJson<String>(json['displayUnit']),
      category: serializer.fromJson<String?>(json['category']),
      status: serializer.fromJson<String>(json['status']),
      source: serializer.fromJson<String>(json['source']),
      version: serializer.fromJson<int>(json['version']),
      createdBy: serializer.fromJson<String?>(json['createdBy']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'householdId': serializer.toJson<String>(householdId),
      'shoppingListId': serializer.toJson<String?>(shoppingListId),
      'name': serializer.toJson<String>(name),
      'quantity': serializer.toJson<double>(quantity),
      'unit': serializer.toJson<String>(unit),
      'displayQuantity': serializer.toJson<double>(displayQuantity),
      'displayUnit': serializer.toJson<String>(displayUnit),
      'category': serializer.toJson<String?>(category),
      'status': serializer.toJson<String>(status),
      'source': serializer.toJson<String>(source),
      'version': serializer.toJson<int>(version),
      'createdBy': serializer.toJson<String?>(createdBy),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
    };
  }

  ShoppingListItem copyWith(
          {String? id,
          String? householdId,
          Value<String?> shoppingListId = const Value.absent(),
          String? name,
          double? quantity,
          String? unit,
          double? displayQuantity,
          String? displayUnit,
          Value<String?> category = const Value.absent(),
          String? status,
          String? source,
          int? version,
          Value<String?> createdBy = const Value.absent(),
          String? createdAt,
          String? updatedAt,
          String? syncStatus}) =>
      ShoppingListItem(
        id: id ?? this.id,
        householdId: householdId ?? this.householdId,
        shoppingListId:
            shoppingListId.present ? shoppingListId.value : this.shoppingListId,
        name: name ?? this.name,
        quantity: quantity ?? this.quantity,
        unit: unit ?? this.unit,
        displayQuantity: displayQuantity ?? this.displayQuantity,
        displayUnit: displayUnit ?? this.displayUnit,
        category: category.present ? category.value : this.category,
        status: status ?? this.status,
        source: source ?? this.source,
        version: version ?? this.version,
        createdBy: createdBy.present ? createdBy.value : this.createdBy,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        syncStatus: syncStatus ?? this.syncStatus,
      );
  ShoppingListItem copyWithCompanion(ShoppingListItemsCompanion data) {
    return ShoppingListItem(
      id: data.id.present ? data.id.value : this.id,
      householdId:
          data.householdId.present ? data.householdId.value : this.householdId,
      shoppingListId: data.shoppingListId.present
          ? data.shoppingListId.value
          : this.shoppingListId,
      name: data.name.present ? data.name.value : this.name,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unit: data.unit.present ? data.unit.value : this.unit,
      displayQuantity: data.displayQuantity.present
          ? data.displayQuantity.value
          : this.displayQuantity,
      displayUnit:
          data.displayUnit.present ? data.displayUnit.value : this.displayUnit,
      category: data.category.present ? data.category.value : this.category,
      status: data.status.present ? data.status.value : this.status,
      source: data.source.present ? data.source.value : this.source,
      version: data.version.present ? data.version.value : this.version,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncStatus:
          data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShoppingListItem(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('shoppingListId: $shoppingListId, ')
          ..write('name: $name, ')
          ..write('quantity: $quantity, ')
          ..write('unit: $unit, ')
          ..write('displayQuantity: $displayQuantity, ')
          ..write('displayUnit: $displayUnit, ')
          ..write('category: $category, ')
          ..write('status: $status, ')
          ..write('source: $source, ')
          ..write('version: $version, ')
          ..write('createdBy: $createdBy, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      householdId,
      shoppingListId,
      name,
      quantity,
      unit,
      displayQuantity,
      displayUnit,
      category,
      status,
      source,
      version,
      createdBy,
      createdAt,
      updatedAt,
      syncStatus);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShoppingListItem &&
          other.id == this.id &&
          other.householdId == this.householdId &&
          other.shoppingListId == this.shoppingListId &&
          other.name == this.name &&
          other.quantity == this.quantity &&
          other.unit == this.unit &&
          other.displayQuantity == this.displayQuantity &&
          other.displayUnit == this.displayUnit &&
          other.category == this.category &&
          other.status == this.status &&
          other.source == this.source &&
          other.version == this.version &&
          other.createdBy == this.createdBy &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncStatus == this.syncStatus);
}

class ShoppingListItemsCompanion extends UpdateCompanion<ShoppingListItem> {
  final Value<String> id;
  final Value<String> householdId;
  final Value<String?> shoppingListId;
  final Value<String> name;
  final Value<double> quantity;
  final Value<String> unit;
  final Value<double> displayQuantity;
  final Value<String> displayUnit;
  final Value<String?> category;
  final Value<String> status;
  final Value<String> source;
  final Value<int> version;
  final Value<String?> createdBy;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<String> syncStatus;
  final Value<int> rowid;
  const ShoppingListItemsCompanion({
    this.id = const Value.absent(),
    this.householdId = const Value.absent(),
    this.shoppingListId = const Value.absent(),
    this.name = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unit = const Value.absent(),
    this.displayQuantity = const Value.absent(),
    this.displayUnit = const Value.absent(),
    this.category = const Value.absent(),
    this.status = const Value.absent(),
    this.source = const Value.absent(),
    this.version = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ShoppingListItemsCompanion.insert({
    required String id,
    required String householdId,
    this.shoppingListId = const Value.absent(),
    required String name,
    required double quantity,
    required String unit,
    required double displayQuantity,
    required String displayUnit,
    this.category = const Value.absent(),
    required String status,
    required String source,
    required int version,
    this.createdBy = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        householdId = Value(householdId),
        name = Value(name),
        quantity = Value(quantity),
        unit = Value(unit),
        displayQuantity = Value(displayQuantity),
        displayUnit = Value(displayUnit),
        status = Value(status),
        source = Value(source),
        version = Value(version),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<ShoppingListItem> custom({
    Expression<String>? id,
    Expression<String>? householdId,
    Expression<String>? shoppingListId,
    Expression<String>? name,
    Expression<double>? quantity,
    Expression<String>? unit,
    Expression<double>? displayQuantity,
    Expression<String>? displayUnit,
    Expression<String>? category,
    Expression<String>? status,
    Expression<String>? source,
    Expression<int>? version,
    Expression<String>? createdBy,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<String>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (householdId != null) 'household_id': householdId,
      if (shoppingListId != null) 'shopping_list_id': shoppingListId,
      if (name != null) 'name': name,
      if (quantity != null) 'quantity': quantity,
      if (unit != null) 'unit': unit,
      if (displayQuantity != null) 'display_quantity': displayQuantity,
      if (displayUnit != null) 'display_unit': displayUnit,
      if (category != null) 'category': category,
      if (status != null) 'status': status,
      if (source != null) 'source': source,
      if (version != null) 'version': version,
      if (createdBy != null) 'created_by': createdBy,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ShoppingListItemsCompanion copyWith(
      {Value<String>? id,
      Value<String>? householdId,
      Value<String?>? shoppingListId,
      Value<String>? name,
      Value<double>? quantity,
      Value<String>? unit,
      Value<double>? displayQuantity,
      Value<String>? displayUnit,
      Value<String?>? category,
      Value<String>? status,
      Value<String>? source,
      Value<int>? version,
      Value<String?>? createdBy,
      Value<String>? createdAt,
      Value<String>? updatedAt,
      Value<String>? syncStatus,
      Value<int>? rowid}) {
    return ShoppingListItemsCompanion(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      shoppingListId: shoppingListId ?? this.shoppingListId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      displayQuantity: displayQuantity ?? this.displayQuantity,
      displayUnit: displayUnit ?? this.displayUnit,
      category: category ?? this.category,
      status: status ?? this.status,
      source: source ?? this.source,
      version: version ?? this.version,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (householdId.present) {
      map['household_id'] = Variable<String>(householdId.value);
    }
    if (shoppingListId.present) {
      map['shopping_list_id'] = Variable<String>(shoppingListId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (displayQuantity.present) {
      map['display_quantity'] = Variable<double>(displayQuantity.value);
    }
    if (displayUnit.present) {
      map['display_unit'] = Variable<String>(displayUnit.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShoppingListItemsCompanion(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('shoppingListId: $shoppingListId, ')
          ..write('name: $name, ')
          ..write('quantity: $quantity, ')
          ..write('unit: $unit, ')
          ..write('displayQuantity: $displayQuantity, ')
          ..write('displayUnit: $displayUnit, ')
          ..write('category: $category, ')
          ..write('status: $status, ')
          ..write('source: $source, ')
          ..write('version: $version, ')
          ..write('createdBy: $createdBy, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ShoppingSyncQueueEntriesTable extends ShoppingSyncQueueEntries
    with TableInfo<$ShoppingSyncQueueEntriesTable, ShoppingSyncQueueEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShoppingSyncQueueEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _householdIdMeta =
      const VerificationMeta('householdId');
  @override
  late final GeneratedColumn<String> householdId = GeneratedColumn<String>(
      'household_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
      'item_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _operationMeta =
      const VerificationMeta('operation');
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
      'operation', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payloadMeta =
      const VerificationMeta('payload');
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
      'payload', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _baseVersionMeta =
      const VerificationMeta('baseVersion');
  @override
  late final GeneratedColumn<int> baseVersion = GeneratedColumn<int>(
      'base_version', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, householdId, itemId, operation, payload, baseVersion, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shopping_sync_queue_entries';
  @override
  VerificationContext validateIntegrity(
      Insertable<ShoppingSyncQueueEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('household_id')) {
      context.handle(
          _householdIdMeta,
          householdId.isAcceptableOrUnknown(
              data['household_id']!, _householdIdMeta));
    } else if (isInserting) {
      context.missing(_householdIdMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(_itemIdMeta,
          itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta));
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('operation')) {
      context.handle(_operationMeta,
          operation.isAcceptableOrUnknown(data['operation']!, _operationMeta));
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(_payloadMeta,
          payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta));
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('base_version')) {
      context.handle(
          _baseVersionMeta,
          baseVersion.isAcceptableOrUnknown(
              data['base_version']!, _baseVersionMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ShoppingSyncQueueEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShoppingSyncQueueEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      householdId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}household_id'])!,
      itemId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}item_id'])!,
      operation: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}operation'])!,
      payload: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload'])!,
      baseVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}base_version']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $ShoppingSyncQueueEntriesTable createAlias(String alias) {
    return $ShoppingSyncQueueEntriesTable(attachedDatabase, alias);
  }
}

class ShoppingSyncQueueEntry extends DataClass
    implements Insertable<ShoppingSyncQueueEntry> {
  final int id;
  final String householdId;
  final String itemId;
  final String operation;
  final String payload;
  final int? baseVersion;
  final String createdAt;
  const ShoppingSyncQueueEntry(
      {required this.id,
      required this.householdId,
      required this.itemId,
      required this.operation,
      required this.payload,
      this.baseVersion,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['household_id'] = Variable<String>(householdId);
    map['item_id'] = Variable<String>(itemId);
    map['operation'] = Variable<String>(operation);
    map['payload'] = Variable<String>(payload);
    if (!nullToAbsent || baseVersion != null) {
      map['base_version'] = Variable<int>(baseVersion);
    }
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  ShoppingSyncQueueEntriesCompanion toCompanion(bool nullToAbsent) {
    return ShoppingSyncQueueEntriesCompanion(
      id: Value(id),
      householdId: Value(householdId),
      itemId: Value(itemId),
      operation: Value(operation),
      payload: Value(payload),
      baseVersion: baseVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(baseVersion),
      createdAt: Value(createdAt),
    );
  }

  factory ShoppingSyncQueueEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShoppingSyncQueueEntry(
      id: serializer.fromJson<int>(json['id']),
      householdId: serializer.fromJson<String>(json['householdId']),
      itemId: serializer.fromJson<String>(json['itemId']),
      operation: serializer.fromJson<String>(json['operation']),
      payload: serializer.fromJson<String>(json['payload']),
      baseVersion: serializer.fromJson<int?>(json['baseVersion']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'householdId': serializer.toJson<String>(householdId),
      'itemId': serializer.toJson<String>(itemId),
      'operation': serializer.toJson<String>(operation),
      'payload': serializer.toJson<String>(payload),
      'baseVersion': serializer.toJson<int?>(baseVersion),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  ShoppingSyncQueueEntry copyWith(
          {int? id,
          String? householdId,
          String? itemId,
          String? operation,
          String? payload,
          Value<int?> baseVersion = const Value.absent(),
          String? createdAt}) =>
      ShoppingSyncQueueEntry(
        id: id ?? this.id,
        householdId: householdId ?? this.householdId,
        itemId: itemId ?? this.itemId,
        operation: operation ?? this.operation,
        payload: payload ?? this.payload,
        baseVersion: baseVersion.present ? baseVersion.value : this.baseVersion,
        createdAt: createdAt ?? this.createdAt,
      );
  ShoppingSyncQueueEntry copyWithCompanion(
      ShoppingSyncQueueEntriesCompanion data) {
    return ShoppingSyncQueueEntry(
      id: data.id.present ? data.id.value : this.id,
      householdId:
          data.householdId.present ? data.householdId.value : this.householdId,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      operation: data.operation.present ? data.operation.value : this.operation,
      payload: data.payload.present ? data.payload.value : this.payload,
      baseVersion:
          data.baseVersion.present ? data.baseVersion.value : this.baseVersion,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShoppingSyncQueueEntry(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('itemId: $itemId, ')
          ..write('operation: $operation, ')
          ..write('payload: $payload, ')
          ..write('baseVersion: $baseVersion, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, householdId, itemId, operation, payload, baseVersion, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShoppingSyncQueueEntry &&
          other.id == this.id &&
          other.householdId == this.householdId &&
          other.itemId == this.itemId &&
          other.operation == this.operation &&
          other.payload == this.payload &&
          other.baseVersion == this.baseVersion &&
          other.createdAt == this.createdAt);
}

class ShoppingSyncQueueEntriesCompanion
    extends UpdateCompanion<ShoppingSyncQueueEntry> {
  final Value<int> id;
  final Value<String> householdId;
  final Value<String> itemId;
  final Value<String> operation;
  final Value<String> payload;
  final Value<int?> baseVersion;
  final Value<String> createdAt;
  const ShoppingSyncQueueEntriesCompanion({
    this.id = const Value.absent(),
    this.householdId = const Value.absent(),
    this.itemId = const Value.absent(),
    this.operation = const Value.absent(),
    this.payload = const Value.absent(),
    this.baseVersion = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ShoppingSyncQueueEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String householdId,
    required String itemId,
    required String operation,
    required String payload,
    this.baseVersion = const Value.absent(),
    required String createdAt,
  })  : householdId = Value(householdId),
        itemId = Value(itemId),
        operation = Value(operation),
        payload = Value(payload),
        createdAt = Value(createdAt);
  static Insertable<ShoppingSyncQueueEntry> custom({
    Expression<int>? id,
    Expression<String>? householdId,
    Expression<String>? itemId,
    Expression<String>? operation,
    Expression<String>? payload,
    Expression<int>? baseVersion,
    Expression<String>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (householdId != null) 'household_id': householdId,
      if (itemId != null) 'item_id': itemId,
      if (operation != null) 'operation': operation,
      if (payload != null) 'payload': payload,
      if (baseVersion != null) 'base_version': baseVersion,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ShoppingSyncQueueEntriesCompanion copyWith(
      {Value<int>? id,
      Value<String>? householdId,
      Value<String>? itemId,
      Value<String>? operation,
      Value<String>? payload,
      Value<int?>? baseVersion,
      Value<String>? createdAt}) {
    return ShoppingSyncQueueEntriesCompanion(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      itemId: itemId ?? this.itemId,
      operation: operation ?? this.operation,
      payload: payload ?? this.payload,
      baseVersion: baseVersion ?? this.baseVersion,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (householdId.present) {
      map['household_id'] = Variable<String>(householdId.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (baseVersion.present) {
      map['base_version'] = Variable<int>(baseVersion.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShoppingSyncQueueEntriesCompanion(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('itemId: $itemId, ')
          ..write('operation: $operation, ')
          ..write('payload: $payload, ')
          ..write('baseVersion: $baseVersion, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ReadCacheEntriesTable readCacheEntries =
      $ReadCacheEntriesTable(this);
  late final $InventoryItemsTable inventoryItems = $InventoryItemsTable(this);
  late final $InventorySyncQueueTable inventorySyncQueue =
      $InventorySyncQueueTable(this);
  late final $ShoppingListItemsTable shoppingListItems =
      $ShoppingListItemsTable(this);
  late final $ShoppingSyncQueueEntriesTable shoppingSyncQueueEntries =
      $ShoppingSyncQueueEntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        readCacheEntries,
        inventoryItems,
        inventorySyncQueue,
        shoppingListItems,
        shoppingSyncQueueEntries
      ];
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
              .map((e) => (
                    e.readTable<$ReadCacheEntriesTable, ReadCacheEntry>(table),
                    BaseReferences<_$AppDatabase, $ReadCacheEntriesTable,
                        ReadCacheEntry>(db, table, e)
                  ))
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
typedef $$InventoryItemsTableCreateCompanionBuilder = InventoryItemsCompanion
    Function({
  required String id,
  required String householdId,
  required String name,
  Value<String?> category,
  required double quantity,
  required String unit,
  Value<double?> displayQuantity,
  Value<String?> displayUnit,
  Value<double?> lowStockThreshold,
  Value<String?> expiryDate,
  Value<String?> note,
  required int version,
  Value<bool> isLowStock,
  Value<bool> isExpiringSoon,
  required String createdBy,
  required String createdAt,
  required String updatedAt,
  Value<String> syncStatus,
  Value<int> rowid,
});
typedef $$InventoryItemsTableUpdateCompanionBuilder = InventoryItemsCompanion
    Function({
  Value<String> id,
  Value<String> householdId,
  Value<String> name,
  Value<String?> category,
  Value<double> quantity,
  Value<String> unit,
  Value<double?> displayQuantity,
  Value<String?> displayUnit,
  Value<double?> lowStockThreshold,
  Value<String?> expiryDate,
  Value<String?> note,
  Value<int> version,
  Value<bool> isLowStock,
  Value<bool> isExpiringSoon,
  Value<String> createdBy,
  Value<String> createdAt,
  Value<String> updatedAt,
  Value<String> syncStatus,
  Value<int> rowid,
});

class $$InventoryItemsTableFilterComposer
    extends Composer<_$AppDatabase, $InventoryItemsTable> {
  $$InventoryItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get displayQuantity => $composableBuilder(
      column: $table.displayQuantity,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get displayUnit => $composableBuilder(
      column: $table.displayUnit, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get lowStockThreshold => $composableBuilder(
      column: $table.lowStockThreshold,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get expiryDate => $composableBuilder(
      column: $table.expiryDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isLowStock => $composableBuilder(
      column: $table.isLowStock, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isExpiringSoon => $composableBuilder(
      column: $table.isExpiringSoon,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdBy => $composableBuilder(
      column: $table.createdBy, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnFilters(column));
}

class $$InventoryItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $InventoryItemsTable> {
  $$InventoryItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get displayQuantity => $composableBuilder(
      column: $table.displayQuantity,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get displayUnit => $composableBuilder(
      column: $table.displayUnit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get lowStockThreshold => $composableBuilder(
      column: $table.lowStockThreshold,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get expiryDate => $composableBuilder(
      column: $table.expiryDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isLowStock => $composableBuilder(
      column: $table.isLowStock, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isExpiringSoon => $composableBuilder(
      column: $table.isExpiringSoon,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdBy => $composableBuilder(
      column: $table.createdBy, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnOrderings(column));
}

class $$InventoryItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $InventoryItemsTable> {
  $$InventoryItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<double> get displayQuantity => $composableBuilder(
      column: $table.displayQuantity, builder: (column) => column);

  GeneratedColumn<String> get displayUnit => $composableBuilder(
      column: $table.displayUnit, builder: (column) => column);

  GeneratedColumn<double> get lowStockThreshold => $composableBuilder(
      column: $table.lowStockThreshold, builder: (column) => column);

  GeneratedColumn<String> get expiryDate => $composableBuilder(
      column: $table.expiryDate, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<bool> get isLowStock => $composableBuilder(
      column: $table.isLowStock, builder: (column) => column);

  GeneratedColumn<bool> get isExpiringSoon => $composableBuilder(
      column: $table.isExpiringSoon, builder: (column) => column);

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => column);
}

class $$InventoryItemsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $InventoryItemsTable,
    InventoryItem,
    $$InventoryItemsTableFilterComposer,
    $$InventoryItemsTableOrderingComposer,
    $$InventoryItemsTableAnnotationComposer,
    $$InventoryItemsTableCreateCompanionBuilder,
    $$InventoryItemsTableUpdateCompanionBuilder,
    (
      InventoryItem,
      BaseReferences<_$AppDatabase, $InventoryItemsTable, InventoryItem>
    ),
    InventoryItem,
    PrefetchHooks Function()> {
  $$InventoryItemsTableTableManager(
      _$AppDatabase db, $InventoryItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InventoryItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InventoryItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InventoryItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> householdId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> category = const Value.absent(),
            Value<double> quantity = const Value.absent(),
            Value<String> unit = const Value.absent(),
            Value<double?> displayQuantity = const Value.absent(),
            Value<String?> displayUnit = const Value.absent(),
            Value<double?> lowStockThreshold = const Value.absent(),
            Value<String?> expiryDate = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<int> version = const Value.absent(),
            Value<bool> isLowStock = const Value.absent(),
            Value<bool> isExpiringSoon = const Value.absent(),
            Value<String> createdBy = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
            Value<String> updatedAt = const Value.absent(),
            Value<String> syncStatus = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              InventoryItemsCompanion(
            id: id,
            householdId: householdId,
            name: name,
            category: category,
            quantity: quantity,
            unit: unit,
            displayQuantity: displayQuantity,
            displayUnit: displayUnit,
            lowStockThreshold: lowStockThreshold,
            expiryDate: expiryDate,
            note: note,
            version: version,
            isLowStock: isLowStock,
            isExpiringSoon: isExpiringSoon,
            createdBy: createdBy,
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncStatus: syncStatus,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String householdId,
            required String name,
            Value<String?> category = const Value.absent(),
            required double quantity,
            required String unit,
            Value<double?> displayQuantity = const Value.absent(),
            Value<String?> displayUnit = const Value.absent(),
            Value<double?> lowStockThreshold = const Value.absent(),
            Value<String?> expiryDate = const Value.absent(),
            Value<String?> note = const Value.absent(),
            required int version,
            Value<bool> isLowStock = const Value.absent(),
            Value<bool> isExpiringSoon = const Value.absent(),
            required String createdBy,
            required String createdAt,
            required String updatedAt,
            Value<String> syncStatus = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              InventoryItemsCompanion.insert(
            id: id,
            householdId: householdId,
            name: name,
            category: category,
            quantity: quantity,
            unit: unit,
            displayQuantity: displayQuantity,
            displayUnit: displayUnit,
            lowStockThreshold: lowStockThreshold,
            expiryDate: expiryDate,
            note: note,
            version: version,
            isLowStock: isLowStock,
            isExpiringSoon: isExpiringSoon,
            createdBy: createdBy,
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncStatus: syncStatus,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$InventoryItemsTable, InventoryItem>(table),
                    BaseReferences<_$AppDatabase, $InventoryItemsTable,
                        InventoryItem>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$InventoryItemsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $InventoryItemsTable,
    InventoryItem,
    $$InventoryItemsTableFilterComposer,
    $$InventoryItemsTableOrderingComposer,
    $$InventoryItemsTableAnnotationComposer,
    $$InventoryItemsTableCreateCompanionBuilder,
    $$InventoryItemsTableUpdateCompanionBuilder,
    (
      InventoryItem,
      BaseReferences<_$AppDatabase, $InventoryItemsTable, InventoryItem>
    ),
    InventoryItem,
    PrefetchHooks Function()>;
typedef $$InventorySyncQueueTableCreateCompanionBuilder
    = InventorySyncQueueCompanion Function({
  Value<int> id,
  required String householdId,
  required String itemId,
  required String operation,
  required int baseVersion,
  Value<String?> deleteReason,
  required DateTime createdAt,
});
typedef $$InventorySyncQueueTableUpdateCompanionBuilder
    = InventorySyncQueueCompanion Function({
  Value<int> id,
  Value<String> householdId,
  Value<String> itemId,
  Value<String> operation,
  Value<int> baseVersion,
  Value<String?> deleteReason,
  Value<DateTime> createdAt,
});

class $$InventorySyncQueueTableFilterComposer
    extends Composer<_$AppDatabase, $InventorySyncQueueTable> {
  $$InventorySyncQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get itemId => $composableBuilder(
      column: $table.itemId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get operation => $composableBuilder(
      column: $table.operation, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get baseVersion => $composableBuilder(
      column: $table.baseVersion, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deleteReason => $composableBuilder(
      column: $table.deleteReason, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$InventorySyncQueueTableOrderingComposer
    extends Composer<_$AppDatabase, $InventorySyncQueueTable> {
  $$InventorySyncQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get itemId => $composableBuilder(
      column: $table.itemId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get operation => $composableBuilder(
      column: $table.operation, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get baseVersion => $composableBuilder(
      column: $table.baseVersion, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deleteReason => $composableBuilder(
      column: $table.deleteReason,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$InventorySyncQueueTableAnnotationComposer
    extends Composer<_$AppDatabase, $InventorySyncQueueTable> {
  $$InventorySyncQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => column);

  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<int> get baseVersion => $composableBuilder(
      column: $table.baseVersion, builder: (column) => column);

  GeneratedColumn<String> get deleteReason => $composableBuilder(
      column: $table.deleteReason, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$InventorySyncQueueTableTableManager extends RootTableManager<
    _$AppDatabase,
    $InventorySyncQueueTable,
    InventorySyncQueueData,
    $$InventorySyncQueueTableFilterComposer,
    $$InventorySyncQueueTableOrderingComposer,
    $$InventorySyncQueueTableAnnotationComposer,
    $$InventorySyncQueueTableCreateCompanionBuilder,
    $$InventorySyncQueueTableUpdateCompanionBuilder,
    (
      InventorySyncQueueData,
      BaseReferences<_$AppDatabase, $InventorySyncQueueTable,
          InventorySyncQueueData>
    ),
    InventorySyncQueueData,
    PrefetchHooks Function()> {
  $$InventorySyncQueueTableTableManager(
      _$AppDatabase db, $InventorySyncQueueTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InventorySyncQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InventorySyncQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InventorySyncQueueTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> householdId = const Value.absent(),
            Value<String> itemId = const Value.absent(),
            Value<String> operation = const Value.absent(),
            Value<int> baseVersion = const Value.absent(),
            Value<String?> deleteReason = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              InventorySyncQueueCompanion(
            id: id,
            householdId: householdId,
            itemId: itemId,
            operation: operation,
            baseVersion: baseVersion,
            deleteReason: deleteReason,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String householdId,
            required String itemId,
            required String operation,
            required int baseVersion,
            Value<String?> deleteReason = const Value.absent(),
            required DateTime createdAt,
          }) =>
              InventorySyncQueueCompanion.insert(
            id: id,
            householdId: householdId,
            itemId: itemId,
            operation: operation,
            baseVersion: baseVersion,
            deleteReason: deleteReason,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$InventorySyncQueueTable,
                        InventorySyncQueueData>(table),
                    BaseReferences<_$AppDatabase, $InventorySyncQueueTable,
                        InventorySyncQueueData>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$InventorySyncQueueTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $InventorySyncQueueTable,
    InventorySyncQueueData,
    $$InventorySyncQueueTableFilterComposer,
    $$InventorySyncQueueTableOrderingComposer,
    $$InventorySyncQueueTableAnnotationComposer,
    $$InventorySyncQueueTableCreateCompanionBuilder,
    $$InventorySyncQueueTableUpdateCompanionBuilder,
    (
      InventorySyncQueueData,
      BaseReferences<_$AppDatabase, $InventorySyncQueueTable,
          InventorySyncQueueData>
    ),
    InventorySyncQueueData,
    PrefetchHooks Function()>;
typedef $$ShoppingListItemsTableCreateCompanionBuilder
    = ShoppingListItemsCompanion Function({
  required String id,
  required String householdId,
  Value<String?> shoppingListId,
  required String name,
  required double quantity,
  required String unit,
  required double displayQuantity,
  required String displayUnit,
  Value<String?> category,
  required String status,
  required String source,
  required int version,
  Value<String?> createdBy,
  required String createdAt,
  required String updatedAt,
  Value<String> syncStatus,
  Value<int> rowid,
});
typedef $$ShoppingListItemsTableUpdateCompanionBuilder
    = ShoppingListItemsCompanion Function({
  Value<String> id,
  Value<String> householdId,
  Value<String?> shoppingListId,
  Value<String> name,
  Value<double> quantity,
  Value<String> unit,
  Value<double> displayQuantity,
  Value<String> displayUnit,
  Value<String?> category,
  Value<String> status,
  Value<String> source,
  Value<int> version,
  Value<String?> createdBy,
  Value<String> createdAt,
  Value<String> updatedAt,
  Value<String> syncStatus,
  Value<int> rowid,
});

class $$ShoppingListItemsTableFilterComposer
    extends Composer<_$AppDatabase, $ShoppingListItemsTable> {
  $$ShoppingListItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get shoppingListId => $composableBuilder(
      column: $table.shoppingListId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get displayQuantity => $composableBuilder(
      column: $table.displayQuantity,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get displayUnit => $composableBuilder(
      column: $table.displayUnit, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdBy => $composableBuilder(
      column: $table.createdBy, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnFilters(column));
}

class $$ShoppingListItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $ShoppingListItemsTable> {
  $$ShoppingListItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get shoppingListId => $composableBuilder(
      column: $table.shoppingListId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get displayQuantity => $composableBuilder(
      column: $table.displayQuantity,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get displayUnit => $composableBuilder(
      column: $table.displayUnit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdBy => $composableBuilder(
      column: $table.createdBy, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnOrderings(column));
}

class $$ShoppingListItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ShoppingListItemsTable> {
  $$ShoppingListItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => column);

  GeneratedColumn<String> get shoppingListId => $composableBuilder(
      column: $table.shoppingListId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<double> get displayQuantity => $composableBuilder(
      column: $table.displayQuantity, builder: (column) => column);

  GeneratedColumn<String> get displayUnit => $composableBuilder(
      column: $table.displayUnit, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => column);
}

class $$ShoppingListItemsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ShoppingListItemsTable,
    ShoppingListItem,
    $$ShoppingListItemsTableFilterComposer,
    $$ShoppingListItemsTableOrderingComposer,
    $$ShoppingListItemsTableAnnotationComposer,
    $$ShoppingListItemsTableCreateCompanionBuilder,
    $$ShoppingListItemsTableUpdateCompanionBuilder,
    (
      ShoppingListItem,
      BaseReferences<_$AppDatabase, $ShoppingListItemsTable, ShoppingListItem>
    ),
    ShoppingListItem,
    PrefetchHooks Function()> {
  $$ShoppingListItemsTableTableManager(
      _$AppDatabase db, $ShoppingListItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShoppingListItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShoppingListItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShoppingListItemsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> householdId = const Value.absent(),
            Value<String?> shoppingListId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<double> quantity = const Value.absent(),
            Value<String> unit = const Value.absent(),
            Value<double> displayQuantity = const Value.absent(),
            Value<String> displayUnit = const Value.absent(),
            Value<String?> category = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<int> version = const Value.absent(),
            Value<String?> createdBy = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
            Value<String> updatedAt = const Value.absent(),
            Value<String> syncStatus = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ShoppingListItemsCompanion(
            id: id,
            householdId: householdId,
            shoppingListId: shoppingListId,
            name: name,
            quantity: quantity,
            unit: unit,
            displayQuantity: displayQuantity,
            displayUnit: displayUnit,
            category: category,
            status: status,
            source: source,
            version: version,
            createdBy: createdBy,
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncStatus: syncStatus,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String householdId,
            Value<String?> shoppingListId = const Value.absent(),
            required String name,
            required double quantity,
            required String unit,
            required double displayQuantity,
            required String displayUnit,
            Value<String?> category = const Value.absent(),
            required String status,
            required String source,
            required int version,
            Value<String?> createdBy = const Value.absent(),
            required String createdAt,
            required String updatedAt,
            Value<String> syncStatus = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ShoppingListItemsCompanion.insert(
            id: id,
            householdId: householdId,
            shoppingListId: shoppingListId,
            name: name,
            quantity: quantity,
            unit: unit,
            displayQuantity: displayQuantity,
            displayUnit: displayUnit,
            category: category,
            status: status,
            source: source,
            version: version,
            createdBy: createdBy,
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncStatus: syncStatus,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$ShoppingListItemsTable, ShoppingListItem>(
                        table),
                    BaseReferences<_$AppDatabase, $ShoppingListItemsTable,
                        ShoppingListItem>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ShoppingListItemsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ShoppingListItemsTable,
    ShoppingListItem,
    $$ShoppingListItemsTableFilterComposer,
    $$ShoppingListItemsTableOrderingComposer,
    $$ShoppingListItemsTableAnnotationComposer,
    $$ShoppingListItemsTableCreateCompanionBuilder,
    $$ShoppingListItemsTableUpdateCompanionBuilder,
    (
      ShoppingListItem,
      BaseReferences<_$AppDatabase, $ShoppingListItemsTable, ShoppingListItem>
    ),
    ShoppingListItem,
    PrefetchHooks Function()>;
typedef $$ShoppingSyncQueueEntriesTableCreateCompanionBuilder
    = ShoppingSyncQueueEntriesCompanion Function({
  Value<int> id,
  required String householdId,
  required String itemId,
  required String operation,
  required String payload,
  Value<int?> baseVersion,
  required String createdAt,
});
typedef $$ShoppingSyncQueueEntriesTableUpdateCompanionBuilder
    = ShoppingSyncQueueEntriesCompanion Function({
  Value<int> id,
  Value<String> householdId,
  Value<String> itemId,
  Value<String> operation,
  Value<String> payload,
  Value<int?> baseVersion,
  Value<String> createdAt,
});

class $$ShoppingSyncQueueEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $ShoppingSyncQueueEntriesTable> {
  $$ShoppingSyncQueueEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get itemId => $composableBuilder(
      column: $table.itemId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get operation => $composableBuilder(
      column: $table.operation, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get baseVersion => $composableBuilder(
      column: $table.baseVersion, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$ShoppingSyncQueueEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $ShoppingSyncQueueEntriesTable> {
  $$ShoppingSyncQueueEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get itemId => $composableBuilder(
      column: $table.itemId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get operation => $composableBuilder(
      column: $table.operation, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get baseVersion => $composableBuilder(
      column: $table.baseVersion, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$ShoppingSyncQueueEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ShoppingSyncQueueEntriesTable> {
  $$ShoppingSyncQueueEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => column);

  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<int> get baseVersion => $composableBuilder(
      column: $table.baseVersion, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ShoppingSyncQueueEntriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ShoppingSyncQueueEntriesTable,
    ShoppingSyncQueueEntry,
    $$ShoppingSyncQueueEntriesTableFilterComposer,
    $$ShoppingSyncQueueEntriesTableOrderingComposer,
    $$ShoppingSyncQueueEntriesTableAnnotationComposer,
    $$ShoppingSyncQueueEntriesTableCreateCompanionBuilder,
    $$ShoppingSyncQueueEntriesTableUpdateCompanionBuilder,
    (
      ShoppingSyncQueueEntry,
      BaseReferences<_$AppDatabase, $ShoppingSyncQueueEntriesTable,
          ShoppingSyncQueueEntry>
    ),
    ShoppingSyncQueueEntry,
    PrefetchHooks Function()> {
  $$ShoppingSyncQueueEntriesTableTableManager(
      _$AppDatabase db, $ShoppingSyncQueueEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShoppingSyncQueueEntriesTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$ShoppingSyncQueueEntriesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShoppingSyncQueueEntriesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> householdId = const Value.absent(),
            Value<String> itemId = const Value.absent(),
            Value<String> operation = const Value.absent(),
            Value<String> payload = const Value.absent(),
            Value<int?> baseVersion = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
          }) =>
              ShoppingSyncQueueEntriesCompanion(
            id: id,
            householdId: householdId,
            itemId: itemId,
            operation: operation,
            payload: payload,
            baseVersion: baseVersion,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String householdId,
            required String itemId,
            required String operation,
            required String payload,
            Value<int?> baseVersion = const Value.absent(),
            required String createdAt,
          }) =>
              ShoppingSyncQueueEntriesCompanion.insert(
            id: id,
            householdId: householdId,
            itemId: itemId,
            operation: operation,
            payload: payload,
            baseVersion: baseVersion,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$ShoppingSyncQueueEntriesTable,
                        ShoppingSyncQueueEntry>(table),
                    BaseReferences<
                        _$AppDatabase,
                        $ShoppingSyncQueueEntriesTable,
                        ShoppingSyncQueueEntry>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ShoppingSyncQueueEntriesTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $ShoppingSyncQueueEntriesTable,
        ShoppingSyncQueueEntry,
        $$ShoppingSyncQueueEntriesTableFilterComposer,
        $$ShoppingSyncQueueEntriesTableOrderingComposer,
        $$ShoppingSyncQueueEntriesTableAnnotationComposer,
        $$ShoppingSyncQueueEntriesTableCreateCompanionBuilder,
        $$ShoppingSyncQueueEntriesTableUpdateCompanionBuilder,
        (
          ShoppingSyncQueueEntry,
          BaseReferences<_$AppDatabase, $ShoppingSyncQueueEntriesTable,
              ShoppingSyncQueueEntry>
        ),
        ShoppingSyncQueueEntry,
        PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ReadCacheEntriesTableTableManager get readCacheEntries =>
      $$ReadCacheEntriesTableTableManager(_db, _db.readCacheEntries);
  $$InventoryItemsTableTableManager get inventoryItems =>
      $$InventoryItemsTableTableManager(_db, _db.inventoryItems);
  $$InventorySyncQueueTableTableManager get inventorySyncQueue =>
      $$InventorySyncQueueTableTableManager(_db, _db.inventorySyncQueue);
  $$ShoppingListItemsTableTableManager get shoppingListItems =>
      $$ShoppingListItemsTableTableManager(_db, _db.shoppingListItems);
  $$ShoppingSyncQueueEntriesTableTableManager get shoppingSyncQueueEntries =>
      $$ShoppingSyncQueueEntriesTableTableManager(
          _db, _db.shoppingSyncQueueEntries);
}
