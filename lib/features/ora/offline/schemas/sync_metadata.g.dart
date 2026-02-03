// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_metadata.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetSyncMetadataCollection on Isar {
  IsarCollection<SyncMetadata> get syncMetadatas => this.collection();
}

const SyncMetadataSchema = CollectionSchema(
  name: r'SyncMetadata',
  id: 1560148770299903314,
  properties: {
    r'conflictCount': PropertySchema(
      id: 0,
      name: r'conflictCount',
      type: IsarType.long,
    ),
    r'currentBatchSynced': PropertySchema(
      id: 1,
      name: r'currentBatchSynced',
      type: IsarType.long,
    ),
    r'currentBatchTotal': PropertySchema(
      id: 2,
      name: r'currentBatchTotal',
      type: IsarType.long,
    ),
    r'currentError': PropertySchema(
      id: 3,
      name: r'currentError',
      type: IsarType.string,
    ),
    r'failedCount': PropertySchema(
      id: 4,
      name: r'failedCount',
      type: IsarType.long,
    ),
    r'isOnline': PropertySchema(
      id: 5,
      name: r'isOnline',
      type: IsarType.bool,
    ),
    r'lastFullSync': PropertySchema(
      id: 6,
      name: r'lastFullSync',
      type: IsarType.dateTime,
    ),
    r'lastSyncAttempt': PropertySchema(
      id: 7,
      name: r'lastSyncAttempt',
      type: IsarType.dateTime,
    ),
    r'pauseReason': PropertySchema(
      id: 8,
      name: r'pauseReason',
      type: IsarType.string,
    ),
    r'pendingCount': PropertySchema(
      id: 9,
      name: r'pendingCount',
      type: IsarType.long,
    ),
    r'progressPercent': PropertySchema(
      id: 10,
      name: r'progressPercent',
      type: IsarType.long,
    ),
    r'state': PropertySchema(
      id: 11,
      name: r'state',
      type: IsarType.byte,
      enumMap: _SyncMetadatastateEnumValueMap,
    ),
    r'statusText': PropertySchema(
      id: 12,
      name: r'statusText',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 13,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _syncMetadataEstimateSize,
  serialize: _syncMetadataSerialize,
  deserialize: _syncMetadataDeserialize,
  deserializeProp: _syncMetadataDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _syncMetadataGetId,
  getLinks: _syncMetadataGetLinks,
  attach: _syncMetadataAttach,
  version: '3.1.0+1',
);

int _syncMetadataEstimateSize(
  SyncMetadata object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.currentError;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.pauseReason;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.statusText.length * 3;
  return bytesCount;
}

void _syncMetadataSerialize(
  SyncMetadata object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.conflictCount);
  writer.writeLong(offsets[1], object.currentBatchSynced);
  writer.writeLong(offsets[2], object.currentBatchTotal);
  writer.writeString(offsets[3], object.currentError);
  writer.writeLong(offsets[4], object.failedCount);
  writer.writeBool(offsets[5], object.isOnline);
  writer.writeDateTime(offsets[6], object.lastFullSync);
  writer.writeDateTime(offsets[7], object.lastSyncAttempt);
  writer.writeString(offsets[8], object.pauseReason);
  writer.writeLong(offsets[9], object.pendingCount);
  writer.writeLong(offsets[10], object.progressPercent);
  writer.writeByte(offsets[11], object.state.index);
  writer.writeString(offsets[12], object.statusText);
  writer.writeDateTime(offsets[13], object.updatedAt);
}

SyncMetadata _syncMetadataDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = SyncMetadata();
  object.conflictCount = reader.readLong(offsets[0]);
  object.currentBatchSynced = reader.readLong(offsets[1]);
  object.currentBatchTotal = reader.readLong(offsets[2]);
  object.currentError = reader.readStringOrNull(offsets[3]);
  object.failedCount = reader.readLong(offsets[4]);
  object.id = id;
  object.isOnline = reader.readBool(offsets[5]);
  object.lastFullSync = reader.readDateTimeOrNull(offsets[6]);
  object.lastSyncAttempt = reader.readDateTimeOrNull(offsets[7]);
  object.pauseReason = reader.readStringOrNull(offsets[8]);
  object.pendingCount = reader.readLong(offsets[9]);
  object.progressPercent = reader.readLong(offsets[10]);
  object.state =
      _SyncMetadatastateValueEnumMap[reader.readByteOrNull(offsets[11])] ??
          SyncState.idle;
  object.updatedAt = reader.readDateTime(offsets[13]);
  return object;
}

P _syncMetadataDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (reader.readBool(offset)) as P;
    case 6:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 7:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readLong(offset)) as P;
    case 10:
      return (reader.readLong(offset)) as P;
    case 11:
      return (_SyncMetadatastateValueEnumMap[reader.readByteOrNull(offset)] ??
          SyncState.idle) as P;
    case 12:
      return (reader.readString(offset)) as P;
    case 13:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _SyncMetadatastateEnumValueMap = {
  'idle': 0,
  'syncing': 1,
  'paused': 2,
  'error': 3,
  'offline': 4,
};
const _SyncMetadatastateValueEnumMap = {
  0: SyncState.idle,
  1: SyncState.syncing,
  2: SyncState.paused,
  3: SyncState.error,
  4: SyncState.offline,
};

Id _syncMetadataGetId(SyncMetadata object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _syncMetadataGetLinks(SyncMetadata object) {
  return [];
}

void _syncMetadataAttach(
    IsarCollection<dynamic> col, Id id, SyncMetadata object) {
  object.id = id;
}

extension SyncMetadataQueryWhereSort
    on QueryBuilder<SyncMetadata, SyncMetadata, QWhere> {
  QueryBuilder<SyncMetadata, SyncMetadata, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension SyncMetadataQueryWhere
    on QueryBuilder<SyncMetadata, SyncMetadata, QWhereClause> {
  QueryBuilder<SyncMetadata, SyncMetadata, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterWhereClause> idNotEqualTo(
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

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterWhereClause> idBetween(
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
}

extension SyncMetadataQueryFilter
    on QueryBuilder<SyncMetadata, SyncMetadata, QFilterCondition> {
  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition>
      conflictCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'conflictCount',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition>
      conflictCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'conflictCount',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition>
      conflictCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'conflictCount',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition>
      conflictCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'conflictCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition>
      currentBatchSyncedEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'currentBatchSynced',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition>
      currentBatchSyncedGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'currentBatchSynced',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition>
      currentBatchSyncedLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'currentBatchSynced',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition>
      currentBatchSyncedBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'currentBatchSynced',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition>
      currentBatchTotalEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'currentBatchTotal',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition>
      currentBatchTotalGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'currentBatchTotal',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition>
      currentBatchTotalLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'currentBatchTotal',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition>
      currentBatchTotalBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'currentBatchTotal',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition>
      currentErrorIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'currentError',
      ));
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition>
      currentErrorIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'currentError',
      ));
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition>
      currentErrorEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'currentError',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition>
      currentErrorGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'currentError',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition>
      currentErrorLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'currentError',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition>
      currentErrorBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'currentError',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition>
      currentErrorStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'currentError',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition>
      currentErrorEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'currentError',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition>
      currentErrorContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'currentError',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition>
      currentErrorMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'currentError',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition>
      currentErrorIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'currentError',
        value: '',
      ));
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition>
      currentErrorIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'currentError',
        value: '',
      ));
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition>
      failedCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'failedCount',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition>
      failedCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'failedCount',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition>
      failedCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'failedCount',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition>
      failedCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'failedCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition> idBetween(
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

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition>
      isOnlineEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isOnline',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition>
      lastFullSyncIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastFullSync',
      ));
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition>
      lastFullSyncIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastFullSync',
      ));
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition>
      lastFullSyncEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastFullSync',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition>
      lastFullSyncGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastFullSync',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition>
      lastFullSyncLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastFullSync',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition>
      lastFullSyncBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastFullSync',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition>
      lastSyncAttemptIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastSyncAttempt',
      ));
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition>
      lastSyncAttemptIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastSyncAttempt',
      ));
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition>
      lastSyncAttemptEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastSyncAttempt',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition>
      lastSyncAttemptGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastSyncAttempt',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition>
      lastSyncAttemptLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastSyncAttempt',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition>
      lastSyncAttemptBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastSyncAttempt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition>
      pauseReasonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'pauseReason',
      ));
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition>
      pauseReasonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'pauseReason',
      ));
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition>
      pauseReasonEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'pauseReason',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition>
      pauseReasonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'pauseReason',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition>
      pauseReasonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'pauseReason',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition>
      pauseReasonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'pauseReason',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition>
      pauseReasonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'pauseReason',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition>
      pauseReasonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'pauseReason',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition>
      pauseReasonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'pauseReason',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition>
      pauseReasonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'pauseReason',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition>
      pauseReasonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'pauseReason',
        value: '',
      ));
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition>
      pauseReasonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'pauseReason',
        value: '',
      ));
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition>
      pendingCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'pendingCount',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition>
      pendingCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'pendingCount',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition>
      pendingCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'pendingCount',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition>
      pendingCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'pendingCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition>
      progressPercentEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'progressPercent',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition>
      progressPercentGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'progressPercent',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition>
      progressPercentLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'progressPercent',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition>
      progressPercentBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'progressPercent',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition> stateEqualTo(
      SyncState value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'state',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition>
      stateGreaterThan(
    SyncState value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'state',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition> stateLessThan(
    SyncState value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'state',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition> stateBetween(
    SyncState lower,
    SyncState upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'state',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition>
      statusTextEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'statusText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition>
      statusTextGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'statusText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition>
      statusTextLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'statusText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition>
      statusTextBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'statusText',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition>
      statusTextStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'statusText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition>
      statusTextEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'statusText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition>
      statusTextContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'statusText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition>
      statusTextMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'statusText',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition>
      statusTextIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'statusText',
        value: '',
      ));
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition>
      statusTextIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'statusText',
        value: '',
      ));
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition>
      updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition>
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

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition>
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

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterFilterCondition>
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
}

extension SyncMetadataQueryObject
    on QueryBuilder<SyncMetadata, SyncMetadata, QFilterCondition> {}

extension SyncMetadataQueryLinks
    on QueryBuilder<SyncMetadata, SyncMetadata, QFilterCondition> {}

extension SyncMetadataQuerySortBy
    on QueryBuilder<SyncMetadata, SyncMetadata, QSortBy> {
  QueryBuilder<SyncMetadata, SyncMetadata, QAfterSortBy> sortByConflictCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'conflictCount', Sort.asc);
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterSortBy>
      sortByConflictCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'conflictCount', Sort.desc);
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterSortBy>
      sortByCurrentBatchSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentBatchSynced', Sort.asc);
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterSortBy>
      sortByCurrentBatchSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentBatchSynced', Sort.desc);
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterSortBy>
      sortByCurrentBatchTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentBatchTotal', Sort.asc);
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterSortBy>
      sortByCurrentBatchTotalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentBatchTotal', Sort.desc);
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterSortBy> sortByCurrentError() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentError', Sort.asc);
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterSortBy>
      sortByCurrentErrorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentError', Sort.desc);
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterSortBy> sortByFailedCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'failedCount', Sort.asc);
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterSortBy>
      sortByFailedCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'failedCount', Sort.desc);
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterSortBy> sortByIsOnline() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isOnline', Sort.asc);
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterSortBy> sortByIsOnlineDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isOnline', Sort.desc);
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterSortBy> sortByLastFullSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastFullSync', Sort.asc);
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterSortBy>
      sortByLastFullSyncDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastFullSync', Sort.desc);
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterSortBy>
      sortByLastSyncAttempt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncAttempt', Sort.asc);
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterSortBy>
      sortByLastSyncAttemptDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncAttempt', Sort.desc);
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterSortBy> sortByPauseReason() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pauseReason', Sort.asc);
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterSortBy>
      sortByPauseReasonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pauseReason', Sort.desc);
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterSortBy> sortByPendingCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingCount', Sort.asc);
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterSortBy>
      sortByPendingCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingCount', Sort.desc);
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterSortBy>
      sortByProgressPercent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'progressPercent', Sort.asc);
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterSortBy>
      sortByProgressPercentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'progressPercent', Sort.desc);
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterSortBy> sortByState() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'state', Sort.asc);
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterSortBy> sortByStateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'state', Sort.desc);
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterSortBy> sortByStatusText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'statusText', Sort.asc);
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterSortBy>
      sortByStatusTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'statusText', Sort.desc);
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterSortBy> sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension SyncMetadataQuerySortThenBy
    on QueryBuilder<SyncMetadata, SyncMetadata, QSortThenBy> {
  QueryBuilder<SyncMetadata, SyncMetadata, QAfterSortBy> thenByConflictCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'conflictCount', Sort.asc);
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterSortBy>
      thenByConflictCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'conflictCount', Sort.desc);
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterSortBy>
      thenByCurrentBatchSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentBatchSynced', Sort.asc);
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterSortBy>
      thenByCurrentBatchSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentBatchSynced', Sort.desc);
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterSortBy>
      thenByCurrentBatchTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentBatchTotal', Sort.asc);
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterSortBy>
      thenByCurrentBatchTotalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentBatchTotal', Sort.desc);
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterSortBy> thenByCurrentError() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentError', Sort.asc);
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterSortBy>
      thenByCurrentErrorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentError', Sort.desc);
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterSortBy> thenByFailedCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'failedCount', Sort.asc);
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterSortBy>
      thenByFailedCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'failedCount', Sort.desc);
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterSortBy> thenByIsOnline() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isOnline', Sort.asc);
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterSortBy> thenByIsOnlineDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isOnline', Sort.desc);
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterSortBy> thenByLastFullSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastFullSync', Sort.asc);
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterSortBy>
      thenByLastFullSyncDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastFullSync', Sort.desc);
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterSortBy>
      thenByLastSyncAttempt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncAttempt', Sort.asc);
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterSortBy>
      thenByLastSyncAttemptDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncAttempt', Sort.desc);
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterSortBy> thenByPauseReason() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pauseReason', Sort.asc);
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterSortBy>
      thenByPauseReasonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pauseReason', Sort.desc);
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterSortBy> thenByPendingCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingCount', Sort.asc);
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterSortBy>
      thenByPendingCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingCount', Sort.desc);
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterSortBy>
      thenByProgressPercent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'progressPercent', Sort.asc);
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterSortBy>
      thenByProgressPercentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'progressPercent', Sort.desc);
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterSortBy> thenByState() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'state', Sort.asc);
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterSortBy> thenByStateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'state', Sort.desc);
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterSortBy> thenByStatusText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'statusText', Sort.asc);
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterSortBy>
      thenByStatusTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'statusText', Sort.desc);
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QAfterSortBy> thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension SyncMetadataQueryWhereDistinct
    on QueryBuilder<SyncMetadata, SyncMetadata, QDistinct> {
  QueryBuilder<SyncMetadata, SyncMetadata, QDistinct>
      distinctByConflictCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'conflictCount');
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QDistinct>
      distinctByCurrentBatchSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'currentBatchSynced');
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QDistinct>
      distinctByCurrentBatchTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'currentBatchTotal');
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QDistinct> distinctByCurrentError(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'currentError', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QDistinct> distinctByFailedCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'failedCount');
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QDistinct> distinctByIsOnline() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isOnline');
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QDistinct> distinctByLastFullSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastFullSync');
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QDistinct>
      distinctByLastSyncAttempt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastSyncAttempt');
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QDistinct> distinctByPauseReason(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pauseReason', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QDistinct> distinctByPendingCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pendingCount');
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QDistinct>
      distinctByProgressPercent() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'progressPercent');
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QDistinct> distinctByState() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'state');
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QDistinct> distinctByStatusText(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'statusText', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SyncMetadata, SyncMetadata, QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension SyncMetadataQueryProperty
    on QueryBuilder<SyncMetadata, SyncMetadata, QQueryProperty> {
  QueryBuilder<SyncMetadata, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<SyncMetadata, int, QQueryOperations> conflictCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'conflictCount');
    });
  }

  QueryBuilder<SyncMetadata, int, QQueryOperations>
      currentBatchSyncedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'currentBatchSynced');
    });
  }

  QueryBuilder<SyncMetadata, int, QQueryOperations>
      currentBatchTotalProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'currentBatchTotal');
    });
  }

  QueryBuilder<SyncMetadata, String?, QQueryOperations> currentErrorProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'currentError');
    });
  }

  QueryBuilder<SyncMetadata, int, QQueryOperations> failedCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'failedCount');
    });
  }

  QueryBuilder<SyncMetadata, bool, QQueryOperations> isOnlineProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isOnline');
    });
  }

  QueryBuilder<SyncMetadata, DateTime?, QQueryOperations>
      lastFullSyncProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastFullSync');
    });
  }

  QueryBuilder<SyncMetadata, DateTime?, QQueryOperations>
      lastSyncAttemptProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastSyncAttempt');
    });
  }

  QueryBuilder<SyncMetadata, String?, QQueryOperations> pauseReasonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pauseReason');
    });
  }

  QueryBuilder<SyncMetadata, int, QQueryOperations> pendingCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pendingCount');
    });
  }

  QueryBuilder<SyncMetadata, int, QQueryOperations> progressPercentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'progressPercent');
    });
  }

  QueryBuilder<SyncMetadata, SyncState, QQueryOperations> stateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'state');
    });
  }

  QueryBuilder<SyncMetadata, String, QQueryOperations> statusTextProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'statusText');
    });
  }

  QueryBuilder<SyncMetadata, DateTime, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
