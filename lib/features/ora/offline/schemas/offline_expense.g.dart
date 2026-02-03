// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_expense.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetOfflineExpenseCollection on Isar {
  IsarCollection<OfflineExpense> get offlineExpenses => this.collection();
}

const OfflineExpenseSchema = CollectionSchema(
  name: r'OfflineExpense',
  id: -2768669777538212165,
  properties: {
    r'amount': PropertySchema(
      id: 0,
      name: r'amount',
      type: IsarType.double,
    ),
    r'amountCents': PropertySchema(
      id: 1,
      name: r'amountCents',
      type: IsarType.long,
    ),
    r'category': PropertySchema(
      id: 2,
      name: r'category',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 3,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'currency': PropertySchema(
      id: 4,
      name: r'currency',
      type: IsarType.string,
    ),
    r'description': PropertySchema(
      id: 5,
      name: r'description',
      type: IsarType.string,
    ),
    r'entryMode': PropertySchema(
      id: 6,
      name: r'entryMode',
      type: IsarType.byte,
      enumMap: _OfflineExpenseentryModeEnumValueMap,
    ),
    r'errorMessage': PropertySchema(
      id: 7,
      name: r'errorMessage',
      type: IsarType.string,
    ),
    r'expenseDate': PropertySchema(
      id: 8,
      name: r'expenseDate',
      type: IsarType.dateTime,
    ),
    r'formattedAmount': PropertySchema(
      id: 9,
      name: r'formattedAmount',
      type: IsarType.string,
    ),
    r'isDeleted': PropertySchema(
      id: 10,
      name: r'isDeleted',
      type: IsarType.bool,
    ),
    r'localId': PropertySchema(
      id: 11,
      name: r'localId',
      type: IsarType.string,
    ),
    r'localVersion': PropertySchema(
      id: 12,
      name: r'localVersion',
      type: IsarType.long,
    ),
    r'merchant': PropertySchema(
      id: 13,
      name: r'merchant',
      type: IsarType.string,
    ),
    r'notes': PropertySchema(
      id: 14,
      name: r'notes',
      type: IsarType.string,
    ),
    r'receiptLocalPath': PropertySchema(
      id: 15,
      name: r'receiptLocalPath',
      type: IsarType.string,
    ),
    r'receiptUrl': PropertySchema(
      id: 16,
      name: r'receiptUrl',
      type: IsarType.string,
    ),
    r'retryCount': PropertySchema(
      id: 17,
      name: r'retryCount',
      type: IsarType.long,
    ),
    r'serverId': PropertySchema(
      id: 18,
      name: r'serverId',
      type: IsarType.string,
    ),
    r'serverVersion': PropertySchema(
      id: 19,
      name: r'serverVersion',
      type: IsarType.long,
    ),
    r'shouldRetry': PropertySchema(
      id: 20,
      name: r'shouldRetry',
      type: IsarType.bool,
    ),
    r'sourceMessageLocalId': PropertySchema(
      id: 21,
      name: r'sourceMessageLocalId',
      type: IsarType.string,
    ),
    r'syncStatus': PropertySchema(
      id: 22,
      name: r'syncStatus',
      type: IsarType.byte,
      enumMap: _OfflineExpensesyncStatusEnumValueMap,
    ),
    r'syncedAt': PropertySchema(
      id: 23,
      name: r'syncedAt',
      type: IsarType.dateTime,
    ),
    r'tags': PropertySchema(
      id: 24,
      name: r'tags',
      type: IsarType.stringList,
    ),
    r'tagsString': PropertySchema(
      id: 25,
      name: r'tagsString',
      type: IsarType.string,
    ),
    r'tripId': PropertySchema(
      id: 26,
      name: r'tripId',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 27,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
    r'userId': PropertySchema(
      id: 28,
      name: r'userId',
      type: IsarType.string,
    )
  },
  estimateSize: _offlineExpenseEstimateSize,
  serialize: _offlineExpenseSerialize,
  deserialize: _offlineExpenseDeserialize,
  deserializeProp: _offlineExpenseDeserializeProp,
  idName: r'id',
  indexes: {
    r'localId': IndexSchema(
      id: 1199848425898359622,
      name: r'localId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'localId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'userId': IndexSchema(
      id: -2005826577402374815,
      name: r'userId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'userId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'currency': IndexSchema(
      id: 152811329157106879,
      name: r'currency',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'currency',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'category': IndexSchema(
      id: -7560358558326323820,
      name: r'category',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'category',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'expenseDate': IndexSchema(
      id: -472364015555664967,
      name: r'expenseDate',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'expenseDate',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'tripId': IndexSchema(
      id: 7734156669642746260,
      name: r'tripId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'tripId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'syncStatus': IndexSchema(
      id: 8239539375045684509,
      name: r'syncStatus',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'syncStatus',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'createdAt': IndexSchema(
      id: -3433535483987302584,
      name: r'createdAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'createdAt',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'isDeleted': IndexSchema(
      id: -786475870904832312,
      name: r'isDeleted',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'isDeleted',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _offlineExpenseGetId,
  getLinks: _offlineExpenseGetLinks,
  attach: _offlineExpenseAttach,
  version: '3.1.0+1',
);

int _offlineExpenseEstimateSize(
  OfflineExpense object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.category;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.currency.length * 3;
  bytesCount += 3 + object.description.length * 3;
  {
    final value = object.errorMessage;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.formattedAmount.length * 3;
  bytesCount += 3 + object.localId.length * 3;
  {
    final value = object.merchant;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.notes;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.receiptLocalPath;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.receiptUrl;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.serverId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.sourceMessageLocalId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.tags.length * 3;
  {
    for (var i = 0; i < object.tags.length; i++) {
      final value = object.tags[i];
      bytesCount += value.length * 3;
    }
  }
  {
    final value = object.tagsString;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.tripId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.userId.length * 3;
  return bytesCount;
}

void _offlineExpenseSerialize(
  OfflineExpense object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.amount);
  writer.writeLong(offsets[1], object.amountCents);
  writer.writeString(offsets[2], object.category);
  writer.writeDateTime(offsets[3], object.createdAt);
  writer.writeString(offsets[4], object.currency);
  writer.writeString(offsets[5], object.description);
  writer.writeByte(offsets[6], object.entryMode.index);
  writer.writeString(offsets[7], object.errorMessage);
  writer.writeDateTime(offsets[8], object.expenseDate);
  writer.writeString(offsets[9], object.formattedAmount);
  writer.writeBool(offsets[10], object.isDeleted);
  writer.writeString(offsets[11], object.localId);
  writer.writeLong(offsets[12], object.localVersion);
  writer.writeString(offsets[13], object.merchant);
  writer.writeString(offsets[14], object.notes);
  writer.writeString(offsets[15], object.receiptLocalPath);
  writer.writeString(offsets[16], object.receiptUrl);
  writer.writeLong(offsets[17], object.retryCount);
  writer.writeString(offsets[18], object.serverId);
  writer.writeLong(offsets[19], object.serverVersion);
  writer.writeBool(offsets[20], object.shouldRetry);
  writer.writeString(offsets[21], object.sourceMessageLocalId);
  writer.writeByte(offsets[22], object.syncStatus.index);
  writer.writeDateTime(offsets[23], object.syncedAt);
  writer.writeStringList(offsets[24], object.tags);
  writer.writeString(offsets[25], object.tagsString);
  writer.writeString(offsets[26], object.tripId);
  writer.writeDateTime(offsets[27], object.updatedAt);
  writer.writeString(offsets[28], object.userId);
}

OfflineExpense _offlineExpenseDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = OfflineExpense();
  object.amount = reader.readDouble(offsets[0]);
  object.amountCents = reader.readLong(offsets[1]);
  object.category = reader.readStringOrNull(offsets[2]);
  object.createdAt = reader.readDateTime(offsets[3]);
  object.currency = reader.readString(offsets[4]);
  object.description = reader.readString(offsets[5]);
  object.entryMode =
      _OfflineExpenseentryModeValueEnumMap[reader.readByteOrNull(offsets[6])] ??
          ExpenseEntryMode.ora;
  object.errorMessage = reader.readStringOrNull(offsets[7]);
  object.expenseDate = reader.readDateTime(offsets[8]);
  object.id = id;
  object.isDeleted = reader.readBool(offsets[10]);
  object.localId = reader.readString(offsets[11]);
  object.localVersion = reader.readLong(offsets[12]);
  object.merchant = reader.readStringOrNull(offsets[13]);
  object.notes = reader.readStringOrNull(offsets[14]);
  object.receiptLocalPath = reader.readStringOrNull(offsets[15]);
  object.receiptUrl = reader.readStringOrNull(offsets[16]);
  object.retryCount = reader.readLong(offsets[17]);
  object.serverId = reader.readStringOrNull(offsets[18]);
  object.serverVersion = reader.readLongOrNull(offsets[19]);
  object.sourceMessageLocalId = reader.readStringOrNull(offsets[21]);
  object.syncStatus = _OfflineExpensesyncStatusValueEnumMap[
          reader.readByteOrNull(offsets[22])] ??
      SyncStatus.pending;
  object.syncedAt = reader.readDateTimeOrNull(offsets[23]);
  object.tags = reader.readStringList(offsets[24]) ?? [];
  object.tagsString = reader.readStringOrNull(offsets[25]);
  object.tripId = reader.readStringOrNull(offsets[26]);
  object.updatedAt = reader.readDateTime(offsets[27]);
  object.userId = reader.readString(offsets[28]);
  return object;
}

P _offlineExpenseDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDouble(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readDateTime(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (_OfflineExpenseentryModeValueEnumMap[
              reader.readByteOrNull(offset)] ??
          ExpenseEntryMode.ora) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readDateTime(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readBool(offset)) as P;
    case 11:
      return (reader.readString(offset)) as P;
    case 12:
      return (reader.readLong(offset)) as P;
    case 13:
      return (reader.readStringOrNull(offset)) as P;
    case 14:
      return (reader.readStringOrNull(offset)) as P;
    case 15:
      return (reader.readStringOrNull(offset)) as P;
    case 16:
      return (reader.readStringOrNull(offset)) as P;
    case 17:
      return (reader.readLong(offset)) as P;
    case 18:
      return (reader.readStringOrNull(offset)) as P;
    case 19:
      return (reader.readLongOrNull(offset)) as P;
    case 20:
      return (reader.readBool(offset)) as P;
    case 21:
      return (reader.readStringOrNull(offset)) as P;
    case 22:
      return (_OfflineExpensesyncStatusValueEnumMap[
              reader.readByteOrNull(offset)] ??
          SyncStatus.pending) as P;
    case 23:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 24:
      return (reader.readStringList(offset) ?? []) as P;
    case 25:
      return (reader.readStringOrNull(offset)) as P;
    case 26:
      return (reader.readStringOrNull(offset)) as P;
    case 27:
      return (reader.readDateTime(offset)) as P;
    case 28:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _OfflineExpenseentryModeEnumValueMap = {
  'ora': 0,
  'manual': 1,
  'receipt': 2,
  'notification': 3,
  'import_': 4,
};
const _OfflineExpenseentryModeValueEnumMap = {
  0: ExpenseEntryMode.ora,
  1: ExpenseEntryMode.manual,
  2: ExpenseEntryMode.receipt,
  3: ExpenseEntryMode.notification,
  4: ExpenseEntryMode.import_,
};
const _OfflineExpensesyncStatusEnumValueMap = {
  'pending': 0,
  'syncing': 1,
  'synced': 2,
  'failed': 3,
  'conflict': 4,
  'deleted': 5,
};
const _OfflineExpensesyncStatusValueEnumMap = {
  0: SyncStatus.pending,
  1: SyncStatus.syncing,
  2: SyncStatus.synced,
  3: SyncStatus.failed,
  4: SyncStatus.conflict,
  5: SyncStatus.deleted,
};

Id _offlineExpenseGetId(OfflineExpense object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _offlineExpenseGetLinks(OfflineExpense object) {
  return [];
}

void _offlineExpenseAttach(
    IsarCollection<dynamic> col, Id id, OfflineExpense object) {
  object.id = id;
}

extension OfflineExpenseByIndex on IsarCollection<OfflineExpense> {
  Future<OfflineExpense?> getByLocalId(String localId) {
    return getByIndex(r'localId', [localId]);
  }

  OfflineExpense? getByLocalIdSync(String localId) {
    return getByIndexSync(r'localId', [localId]);
  }

  Future<bool> deleteByLocalId(String localId) {
    return deleteByIndex(r'localId', [localId]);
  }

  bool deleteByLocalIdSync(String localId) {
    return deleteByIndexSync(r'localId', [localId]);
  }

  Future<List<OfflineExpense?>> getAllByLocalId(List<String> localIdValues) {
    final values = localIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'localId', values);
  }

  List<OfflineExpense?> getAllByLocalIdSync(List<String> localIdValues) {
    final values = localIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'localId', values);
  }

  Future<int> deleteAllByLocalId(List<String> localIdValues) {
    final values = localIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'localId', values);
  }

  int deleteAllByLocalIdSync(List<String> localIdValues) {
    final values = localIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'localId', values);
  }

  Future<Id> putByLocalId(OfflineExpense object) {
    return putByIndex(r'localId', object);
  }

  Id putByLocalIdSync(OfflineExpense object, {bool saveLinks = true}) {
    return putByIndexSync(r'localId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByLocalId(List<OfflineExpense> objects) {
    return putAllByIndex(r'localId', objects);
  }

  List<Id> putAllByLocalIdSync(List<OfflineExpense> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'localId', objects, saveLinks: saveLinks);
  }
}

extension OfflineExpenseQueryWhereSort
    on QueryBuilder<OfflineExpense, OfflineExpense, QWhere> {
  QueryBuilder<OfflineExpense, OfflineExpense, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterWhere> anyExpenseDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'expenseDate'),
      );
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterWhere> anySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'syncStatus'),
      );
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterWhere> anyCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'createdAt'),
      );
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterWhere> anyIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'isDeleted'),
      );
    });
  }
}

extension OfflineExpenseQueryWhere
    on QueryBuilder<OfflineExpense, OfflineExpense, QWhereClause> {
  QueryBuilder<OfflineExpense, OfflineExpense, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterWhereClause> idNotEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterWhereClause>
      localIdEqualTo(String localId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'localId',
        value: [localId],
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterWhereClause>
      localIdNotEqualTo(String localId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'localId',
              lower: [],
              upper: [localId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'localId',
              lower: [localId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'localId',
              lower: [localId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'localId',
              lower: [],
              upper: [localId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterWhereClause> userIdEqualTo(
      String userId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'userId',
        value: [userId],
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterWhereClause>
      userIdNotEqualTo(String userId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userId',
              lower: [],
              upper: [userId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userId',
              lower: [userId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userId',
              lower: [userId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userId',
              lower: [],
              upper: [userId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterWhereClause>
      currencyEqualTo(String currency) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'currency',
        value: [currency],
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterWhereClause>
      currencyNotEqualTo(String currency) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'currency',
              lower: [],
              upper: [currency],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'currency',
              lower: [currency],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'currency',
              lower: [currency],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'currency',
              lower: [],
              upper: [currency],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterWhereClause>
      categoryIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'category',
        value: [null],
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterWhereClause>
      categoryIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'category',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterWhereClause>
      categoryEqualTo(String? category) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'category',
        value: [category],
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterWhereClause>
      categoryNotEqualTo(String? category) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'category',
              lower: [],
              upper: [category],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'category',
              lower: [category],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'category',
              lower: [category],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'category',
              lower: [],
              upper: [category],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterWhereClause>
      expenseDateEqualTo(DateTime expenseDate) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'expenseDate',
        value: [expenseDate],
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterWhereClause>
      expenseDateNotEqualTo(DateTime expenseDate) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'expenseDate',
              lower: [],
              upper: [expenseDate],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'expenseDate',
              lower: [expenseDate],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'expenseDate',
              lower: [expenseDate],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'expenseDate',
              lower: [],
              upper: [expenseDate],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterWhereClause>
      expenseDateGreaterThan(
    DateTime expenseDate, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'expenseDate',
        lower: [expenseDate],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterWhereClause>
      expenseDateLessThan(
    DateTime expenseDate, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'expenseDate',
        lower: [],
        upper: [expenseDate],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterWhereClause>
      expenseDateBetween(
    DateTime lowerExpenseDate,
    DateTime upperExpenseDate, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'expenseDate',
        lower: [lowerExpenseDate],
        includeLower: includeLower,
        upper: [upperExpenseDate],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterWhereClause>
      tripIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'tripId',
        value: [null],
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterWhereClause>
      tripIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'tripId',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterWhereClause> tripIdEqualTo(
      String? tripId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'tripId',
        value: [tripId],
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterWhereClause>
      tripIdNotEqualTo(String? tripId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'tripId',
              lower: [],
              upper: [tripId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'tripId',
              lower: [tripId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'tripId',
              lower: [tripId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'tripId',
              lower: [],
              upper: [tripId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterWhereClause>
      syncStatusEqualTo(SyncStatus syncStatus) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'syncStatus',
        value: [syncStatus],
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterWhereClause>
      syncStatusNotEqualTo(SyncStatus syncStatus) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'syncStatus',
              lower: [],
              upper: [syncStatus],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'syncStatus',
              lower: [syncStatus],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'syncStatus',
              lower: [syncStatus],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'syncStatus',
              lower: [],
              upper: [syncStatus],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterWhereClause>
      syncStatusGreaterThan(
    SyncStatus syncStatus, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'syncStatus',
        lower: [syncStatus],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterWhereClause>
      syncStatusLessThan(
    SyncStatus syncStatus, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'syncStatus',
        lower: [],
        upper: [syncStatus],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterWhereClause>
      syncStatusBetween(
    SyncStatus lowerSyncStatus,
    SyncStatus upperSyncStatus, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'syncStatus',
        lower: [lowerSyncStatus],
        includeLower: includeLower,
        upper: [upperSyncStatus],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterWhereClause>
      createdAtEqualTo(DateTime createdAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'createdAt',
        value: [createdAt],
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterWhereClause>
      createdAtNotEqualTo(DateTime createdAt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'createdAt',
              lower: [],
              upper: [createdAt],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'createdAt',
              lower: [createdAt],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'createdAt',
              lower: [createdAt],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'createdAt',
              lower: [],
              upper: [createdAt],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterWhereClause>
      createdAtGreaterThan(
    DateTime createdAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'createdAt',
        lower: [createdAt],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterWhereClause>
      createdAtLessThan(
    DateTime createdAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'createdAt',
        lower: [],
        upper: [createdAt],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterWhereClause>
      createdAtBetween(
    DateTime lowerCreatedAt,
    DateTime upperCreatedAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'createdAt',
        lower: [lowerCreatedAt],
        includeLower: includeLower,
        upper: [upperCreatedAt],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterWhereClause>
      isDeletedEqualTo(bool isDeleted) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'isDeleted',
        value: [isDeleted],
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterWhereClause>
      isDeletedNotEqualTo(bool isDeleted) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isDeleted',
              lower: [],
              upper: [isDeleted],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isDeleted',
              lower: [isDeleted],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isDeleted',
              lower: [isDeleted],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isDeleted',
              lower: [],
              upper: [isDeleted],
              includeUpper: false,
            ));
      }
    });
  }
}

extension OfflineExpenseQueryFilter
    on QueryBuilder<OfflineExpense, OfflineExpense, QFilterCondition> {
  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      amountEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'amount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      amountGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'amount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      amountLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'amount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      amountBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'amount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      amountCentsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'amountCents',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      amountCentsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'amountCents',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      amountCentsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'amountCents',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      amountCentsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'amountCents',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      categoryIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'category',
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      categoryIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'category',
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      categoryEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      categoryGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      categoryLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      categoryBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'category',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      categoryStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      categoryEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      categoryContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      categoryMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'category',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      categoryIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'category',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      categoryIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'category',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      currencyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'currency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      currencyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'currency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      currencyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'currency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      currencyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'currency',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      currencyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'currency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      currencyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'currency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      currencyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'currency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      currencyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'currency',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      currencyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'currency',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      currencyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'currency',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      descriptionEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      descriptionGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      descriptionLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      descriptionBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'description',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      descriptionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      descriptionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      descriptionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      descriptionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'description',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      descriptionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      descriptionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      entryModeEqualTo(ExpenseEntryMode value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'entryMode',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      entryModeGreaterThan(
    ExpenseEntryMode value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'entryMode',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      entryModeLessThan(
    ExpenseEntryMode value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'entryMode',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      entryModeBetween(
    ExpenseEntryMode lower,
    ExpenseEntryMode upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'entryMode',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      errorMessageIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'errorMessage',
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      errorMessageIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'errorMessage',
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      errorMessageEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'errorMessage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      errorMessageGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'errorMessage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      errorMessageLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'errorMessage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      errorMessageBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'errorMessage',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      errorMessageStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'errorMessage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      errorMessageEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'errorMessage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      errorMessageContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'errorMessage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      errorMessageMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'errorMessage',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      errorMessageIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'errorMessage',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      errorMessageIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'errorMessage',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      expenseDateEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'expenseDate',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      expenseDateGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'expenseDate',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      expenseDateLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'expenseDate',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      expenseDateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'expenseDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      formattedAmountEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'formattedAmount',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      formattedAmountGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'formattedAmount',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      formattedAmountLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'formattedAmount',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      formattedAmountBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'formattedAmount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      formattedAmountStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'formattedAmount',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      formattedAmountEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'formattedAmount',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      formattedAmountContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'formattedAmount',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      formattedAmountMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'formattedAmount',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      formattedAmountIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'formattedAmount',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      formattedAmountIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'formattedAmount',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      isDeletedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isDeleted',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      localIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'localId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      localIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'localId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      localIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'localId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      localIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'localId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      localIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'localId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      localIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'localId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      localIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'localId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      localIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'localId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      localIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'localId',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      localIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'localId',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      localVersionEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'localVersion',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      localVersionGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'localVersion',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      localVersionLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'localVersion',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      localVersionBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'localVersion',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      merchantIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'merchant',
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      merchantIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'merchant',
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      merchantEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'merchant',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      merchantGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'merchant',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      merchantLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'merchant',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      merchantBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'merchant',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      merchantStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'merchant',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      merchantEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'merchant',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      merchantContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'merchant',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      merchantMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'merchant',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      merchantIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'merchant',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      merchantIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'merchant',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      notesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'notes',
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      notesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'notes',
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      notesEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      notesGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      notesLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      notesBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'notes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      notesStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      notesEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      notesContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      notesMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'notes',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      notesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notes',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      notesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'notes',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      receiptLocalPathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'receiptLocalPath',
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      receiptLocalPathIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'receiptLocalPath',
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      receiptLocalPathEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'receiptLocalPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      receiptLocalPathGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'receiptLocalPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      receiptLocalPathLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'receiptLocalPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      receiptLocalPathBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'receiptLocalPath',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      receiptLocalPathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'receiptLocalPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      receiptLocalPathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'receiptLocalPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      receiptLocalPathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'receiptLocalPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      receiptLocalPathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'receiptLocalPath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      receiptLocalPathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'receiptLocalPath',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      receiptLocalPathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'receiptLocalPath',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      receiptUrlIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'receiptUrl',
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      receiptUrlIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'receiptUrl',
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      receiptUrlEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'receiptUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      receiptUrlGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'receiptUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      receiptUrlLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'receiptUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      receiptUrlBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'receiptUrl',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      receiptUrlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'receiptUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      receiptUrlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'receiptUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      receiptUrlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'receiptUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      receiptUrlMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'receiptUrl',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      receiptUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'receiptUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      receiptUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'receiptUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      retryCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'retryCount',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      retryCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'retryCount',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      retryCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'retryCount',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      retryCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'retryCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      serverIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'serverId',
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      serverIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'serverId',
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      serverIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'serverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      serverIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'serverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      serverIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'serverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      serverIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'serverId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      serverIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'serverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      serverIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'serverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      serverIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'serverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      serverIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'serverId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      serverIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'serverId',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      serverIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'serverId',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      serverVersionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'serverVersion',
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      serverVersionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'serverVersion',
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      serverVersionEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'serverVersion',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      serverVersionGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'serverVersion',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      serverVersionLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'serverVersion',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      serverVersionBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'serverVersion',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      shouldRetryEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'shouldRetry',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      sourceMessageLocalIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'sourceMessageLocalId',
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      sourceMessageLocalIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'sourceMessageLocalId',
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      sourceMessageLocalIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sourceMessageLocalId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      sourceMessageLocalIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sourceMessageLocalId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      sourceMessageLocalIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sourceMessageLocalId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      sourceMessageLocalIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sourceMessageLocalId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      sourceMessageLocalIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'sourceMessageLocalId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      sourceMessageLocalIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'sourceMessageLocalId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      sourceMessageLocalIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'sourceMessageLocalId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      sourceMessageLocalIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'sourceMessageLocalId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      sourceMessageLocalIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sourceMessageLocalId',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      sourceMessageLocalIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'sourceMessageLocalId',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      syncStatusEqualTo(SyncStatus value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'syncStatus',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      syncStatusGreaterThan(
    SyncStatus value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'syncStatus',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      syncStatusLessThan(
    SyncStatus value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'syncStatus',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      syncStatusBetween(
    SyncStatus lower,
    SyncStatus upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'syncStatus',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      syncedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'syncedAt',
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      syncedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'syncedAt',
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      syncedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'syncedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      syncedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'syncedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      syncedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'syncedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      syncedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'syncedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      tagsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      tagsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'tags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      tagsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'tags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      tagsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'tags',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      tagsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'tags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      tagsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'tags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      tagsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'tags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      tagsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'tags',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      tagsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tags',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      tagsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'tags',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      tagsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'tags',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      tagsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'tags',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      tagsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'tags',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      tagsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'tags',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      tagsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'tags',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      tagsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'tags',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      tagsStringIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'tagsString',
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      tagsStringIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'tagsString',
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      tagsStringEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tagsString',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      tagsStringGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'tagsString',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      tagsStringLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'tagsString',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      tagsStringBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'tagsString',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      tagsStringStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'tagsString',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      tagsStringEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'tagsString',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      tagsStringContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'tagsString',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      tagsStringMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'tagsString',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      tagsStringIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tagsString',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      tagsStringIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'tagsString',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      tripIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'tripId',
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      tripIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'tripId',
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      tripIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tripId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      tripIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'tripId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      tripIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'tripId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      tripIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'tripId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      tripIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'tripId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      tripIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'tripId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      tripIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'tripId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      tripIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'tripId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      tripIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tripId',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      tripIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'tripId',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      updatedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      updatedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      updatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'updatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      userIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      userIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      userIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      userIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'userId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      userIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      userIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      userIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      userIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'userId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      userIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userId',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterFilterCondition>
      userIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'userId',
        value: '',
      ));
    });
  }
}

extension OfflineExpenseQueryObject
    on QueryBuilder<OfflineExpense, OfflineExpense, QFilterCondition> {}

extension OfflineExpenseQueryLinks
    on QueryBuilder<OfflineExpense, OfflineExpense, QFilterCondition> {}

extension OfflineExpenseQuerySortBy
    on QueryBuilder<OfflineExpense, OfflineExpense, QSortBy> {
  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy> sortByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.asc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      sortByAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.desc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      sortByAmountCents() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amountCents', Sort.asc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      sortByAmountCentsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amountCents', Sort.desc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy> sortByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.asc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      sortByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.desc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy> sortByCurrency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currency', Sort.asc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      sortByCurrencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currency', Sort.desc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      sortByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      sortByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy> sortByEntryMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entryMode', Sort.asc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      sortByEntryModeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entryMode', Sort.desc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      sortByErrorMessage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorMessage', Sort.asc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      sortByErrorMessageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorMessage', Sort.desc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      sortByExpenseDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expenseDate', Sort.asc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      sortByExpenseDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expenseDate', Sort.desc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      sortByFormattedAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'formattedAmount', Sort.asc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      sortByFormattedAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'formattedAmount', Sort.desc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy> sortByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.asc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      sortByIsDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.desc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy> sortByLocalId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localId', Sort.asc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      sortByLocalIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localId', Sort.desc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      sortByLocalVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localVersion', Sort.asc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      sortByLocalVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localVersion', Sort.desc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy> sortByMerchant() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'merchant', Sort.asc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      sortByMerchantDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'merchant', Sort.desc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy> sortByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy> sortByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      sortByReceiptLocalPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receiptLocalPath', Sort.asc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      sortByReceiptLocalPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receiptLocalPath', Sort.desc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      sortByReceiptUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receiptUrl', Sort.asc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      sortByReceiptUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receiptUrl', Sort.desc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      sortByRetryCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'retryCount', Sort.asc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      sortByRetryCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'retryCount', Sort.desc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy> sortByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.asc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      sortByServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.desc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      sortByServerVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverVersion', Sort.asc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      sortByServerVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverVersion', Sort.desc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      sortByShouldRetry() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shouldRetry', Sort.asc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      sortByShouldRetryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shouldRetry', Sort.desc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      sortBySourceMessageLocalId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceMessageLocalId', Sort.asc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      sortBySourceMessageLocalIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceMessageLocalId', Sort.desc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      sortBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.asc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      sortBySyncStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.desc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy> sortBySyncedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncedAt', Sort.asc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      sortBySyncedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncedAt', Sort.desc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      sortByTagsString() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tagsString', Sort.asc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      sortByTagsStringDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tagsString', Sort.desc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy> sortByTripId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tripId', Sort.asc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      sortByTripIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tripId', Sort.desc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy> sortByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      sortByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }
}

extension OfflineExpenseQuerySortThenBy
    on QueryBuilder<OfflineExpense, OfflineExpense, QSortThenBy> {
  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy> thenByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.asc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      thenByAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.desc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      thenByAmountCents() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amountCents', Sort.asc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      thenByAmountCentsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amountCents', Sort.desc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy> thenByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.asc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      thenByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.desc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy> thenByCurrency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currency', Sort.asc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      thenByCurrencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currency', Sort.desc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      thenByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      thenByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy> thenByEntryMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entryMode', Sort.asc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      thenByEntryModeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entryMode', Sort.desc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      thenByErrorMessage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorMessage', Sort.asc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      thenByErrorMessageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorMessage', Sort.desc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      thenByExpenseDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expenseDate', Sort.asc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      thenByExpenseDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expenseDate', Sort.desc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      thenByFormattedAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'formattedAmount', Sort.asc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      thenByFormattedAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'formattedAmount', Sort.desc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy> thenByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.asc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      thenByIsDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.desc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy> thenByLocalId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localId', Sort.asc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      thenByLocalIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localId', Sort.desc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      thenByLocalVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localVersion', Sort.asc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      thenByLocalVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localVersion', Sort.desc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy> thenByMerchant() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'merchant', Sort.asc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      thenByMerchantDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'merchant', Sort.desc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy> thenByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy> thenByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      thenByReceiptLocalPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receiptLocalPath', Sort.asc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      thenByReceiptLocalPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receiptLocalPath', Sort.desc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      thenByReceiptUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receiptUrl', Sort.asc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      thenByReceiptUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receiptUrl', Sort.desc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      thenByRetryCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'retryCount', Sort.asc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      thenByRetryCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'retryCount', Sort.desc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy> thenByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.asc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      thenByServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.desc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      thenByServerVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverVersion', Sort.asc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      thenByServerVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverVersion', Sort.desc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      thenByShouldRetry() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shouldRetry', Sort.asc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      thenByShouldRetryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shouldRetry', Sort.desc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      thenBySourceMessageLocalId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceMessageLocalId', Sort.asc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      thenBySourceMessageLocalIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceMessageLocalId', Sort.desc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      thenBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.asc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      thenBySyncStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.desc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy> thenBySyncedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncedAt', Sort.asc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      thenBySyncedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncedAt', Sort.desc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      thenByTagsString() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tagsString', Sort.asc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      thenByTagsStringDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tagsString', Sort.desc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy> thenByTripId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tripId', Sort.asc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      thenByTripIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tripId', Sort.desc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy> thenByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QAfterSortBy>
      thenByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }
}

extension OfflineExpenseQueryWhereDistinct
    on QueryBuilder<OfflineExpense, OfflineExpense, QDistinct> {
  QueryBuilder<OfflineExpense, OfflineExpense, QDistinct> distinctByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'amount');
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QDistinct>
      distinctByAmountCents() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'amountCents');
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QDistinct> distinctByCategory(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'category', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QDistinct> distinctByCurrency(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'currency', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QDistinct> distinctByDescription(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'description', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QDistinct>
      distinctByEntryMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'entryMode');
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QDistinct>
      distinctByErrorMessage({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'errorMessage', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QDistinct>
      distinctByExpenseDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'expenseDate');
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QDistinct>
      distinctByFormattedAmount({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'formattedAmount',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QDistinct>
      distinctByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isDeleted');
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QDistinct> distinctByLocalId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'localId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QDistinct>
      distinctByLocalVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'localVersion');
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QDistinct> distinctByMerchant(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'merchant', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QDistinct> distinctByNotes(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'notes', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QDistinct>
      distinctByReceiptLocalPath({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'receiptLocalPath',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QDistinct> distinctByReceiptUrl(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'receiptUrl', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QDistinct>
      distinctByRetryCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'retryCount');
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QDistinct> distinctByServerId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'serverId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QDistinct>
      distinctByServerVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'serverVersion');
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QDistinct>
      distinctByShouldRetry() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'shouldRetry');
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QDistinct>
      distinctBySourceMessageLocalId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sourceMessageLocalId',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QDistinct>
      distinctBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'syncStatus');
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QDistinct> distinctBySyncedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'syncedAt');
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QDistinct> distinctByTags() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tags');
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QDistinct> distinctByTagsString(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tagsString', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QDistinct> distinctByTripId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tripId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QDistinct>
      distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }

  QueryBuilder<OfflineExpense, OfflineExpense, QDistinct> distinctByUserId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'userId', caseSensitive: caseSensitive);
    });
  }
}

extension OfflineExpenseQueryProperty
    on QueryBuilder<OfflineExpense, OfflineExpense, QQueryProperty> {
  QueryBuilder<OfflineExpense, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<OfflineExpense, double, QQueryOperations> amountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'amount');
    });
  }

  QueryBuilder<OfflineExpense, int, QQueryOperations> amountCentsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'amountCents');
    });
  }

  QueryBuilder<OfflineExpense, String?, QQueryOperations> categoryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'category');
    });
  }

  QueryBuilder<OfflineExpense, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<OfflineExpense, String, QQueryOperations> currencyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'currency');
    });
  }

  QueryBuilder<OfflineExpense, String, QQueryOperations> descriptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'description');
    });
  }

  QueryBuilder<OfflineExpense, ExpenseEntryMode, QQueryOperations>
      entryModeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'entryMode');
    });
  }

  QueryBuilder<OfflineExpense, String?, QQueryOperations>
      errorMessageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'errorMessage');
    });
  }

  QueryBuilder<OfflineExpense, DateTime, QQueryOperations>
      expenseDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'expenseDate');
    });
  }

  QueryBuilder<OfflineExpense, String, QQueryOperations>
      formattedAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'formattedAmount');
    });
  }

  QueryBuilder<OfflineExpense, bool, QQueryOperations> isDeletedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isDeleted');
    });
  }

  QueryBuilder<OfflineExpense, String, QQueryOperations> localIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'localId');
    });
  }

  QueryBuilder<OfflineExpense, int, QQueryOperations> localVersionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'localVersion');
    });
  }

  QueryBuilder<OfflineExpense, String?, QQueryOperations> merchantProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'merchant');
    });
  }

  QueryBuilder<OfflineExpense, String?, QQueryOperations> notesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'notes');
    });
  }

  QueryBuilder<OfflineExpense, String?, QQueryOperations>
      receiptLocalPathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'receiptLocalPath');
    });
  }

  QueryBuilder<OfflineExpense, String?, QQueryOperations> receiptUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'receiptUrl');
    });
  }

  QueryBuilder<OfflineExpense, int, QQueryOperations> retryCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'retryCount');
    });
  }

  QueryBuilder<OfflineExpense, String?, QQueryOperations> serverIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'serverId');
    });
  }

  QueryBuilder<OfflineExpense, int?, QQueryOperations> serverVersionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'serverVersion');
    });
  }

  QueryBuilder<OfflineExpense, bool, QQueryOperations> shouldRetryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'shouldRetry');
    });
  }

  QueryBuilder<OfflineExpense, String?, QQueryOperations>
      sourceMessageLocalIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sourceMessageLocalId');
    });
  }

  QueryBuilder<OfflineExpense, SyncStatus, QQueryOperations>
      syncStatusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'syncStatus');
    });
  }

  QueryBuilder<OfflineExpense, DateTime?, QQueryOperations> syncedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'syncedAt');
    });
  }

  QueryBuilder<OfflineExpense, List<String>, QQueryOperations> tagsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tags');
    });
  }

  QueryBuilder<OfflineExpense, String?, QQueryOperations> tagsStringProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tagsString');
    });
  }

  QueryBuilder<OfflineExpense, String?, QQueryOperations> tripIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tripId');
    });
  }

  QueryBuilder<OfflineExpense, DateTime, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }

  QueryBuilder<OfflineExpense, String, QQueryOperations> userIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'userId');
    });
  }
}
