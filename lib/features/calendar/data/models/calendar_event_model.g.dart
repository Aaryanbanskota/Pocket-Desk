// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar_event_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCalendarEventModelCollection on Isar {
  IsarCollection<CalendarEventModel> get calendarEventModels =>
      this.collection();
}

const CalendarEventModelSchema = CollectionSchema(
  name: r'CalendarEventModel',
  id: 15124112474898114,
  properties: {
    r'attachmentPaths': PropertySchema(
      id: 0,
      name: r'attachmentPaths',
      type: IsarType.stringList,
    ),
    r'category': PropertySchema(
      id: 1,
      name: r'category',
      type: IsarType.string,
    ),
    r'colorHex': PropertySchema(
      id: 2,
      name: r'colorHex',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 3,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'description': PropertySchema(
      id: 4,
      name: r'description',
      type: IsarType.string,
    ),
    r'endTime': PropertySchema(
      id: 5,
      name: r'endTime',
      type: IsarType.dateTime,
    ),
    r'isAllDay': PropertySchema(
      id: 6,
      name: r'isAllDay',
      type: IsarType.bool,
    ),
    r'isSynced': PropertySchema(
      id: 7,
      name: r'isSynced',
      type: IsarType.bool,
    ),
    r'location': PropertySchema(
      id: 8,
      name: r'location',
      type: IsarType.string,
    ),
    r'recurrenceRule': PropertySchema(
      id: 9,
      name: r'recurrenceRule',
      type: IsarType.string,
    ),
    r'recurrenceType': PropertySchema(
      id: 10,
      name: r'recurrenceType',
      type: IsarType.byte,
      enumMap: _CalendarEventModelrecurrenceTypeEnumValueMap,
    ),
    r'reminderMinutes': PropertySchema(
      id: 11,
      name: r'reminderMinutes',
      type: IsarType.longList,
    ),
    r'startTime': PropertySchema(
      id: 12,
      name: r'startTime',
      type: IsarType.dateTime,
    ),
    r'timeZone': PropertySchema(
      id: 13,
      name: r'timeZone',
      type: IsarType.string,
    ),
    r'title': PropertySchema(
      id: 14,
      name: r'title',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 15,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
    r'userId': PropertySchema(
      id: 16,
      name: r'userId',
      type: IsarType.long,
    )
  },
  estimateSize: _calendarEventModelEstimateSize,
  serialize: _calendarEventModelSerialize,
  deserialize: _calendarEventModelDeserialize,
  deserializeProp: _calendarEventModelDeserializeProp,
  idName: r'id',
  indexes: {
    r'userId': IndexSchema(
      id: -2005826577402374815,
      name: r'userId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'userId',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'startTime': IndexSchema(
      id: -3870335341264752872,
      name: r'startTime',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'startTime',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'endTime': IndexSchema(
      id: 6854976694250177488,
      name: r'endTime',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'endTime',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _calendarEventModelGetId,
  getLinks: _calendarEventModelGetLinks,
  attach: _calendarEventModelAttach,
  version: '3.1.0+1',
);

int _calendarEventModelEstimateSize(
  CalendarEventModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.attachmentPaths.length * 3;
  {
    for (var i = 0; i < object.attachmentPaths.length; i++) {
      final value = object.attachmentPaths[i];
      bytesCount += value.length * 3;
    }
  }
  {
    final value = object.category;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.colorHex;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.description;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.location;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.recurrenceRule;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.reminderMinutes.length * 8;
  bytesCount += 3 + object.timeZone.length * 3;
  bytesCount += 3 + object.title.length * 3;
  return bytesCount;
}

void _calendarEventModelSerialize(
  CalendarEventModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeStringList(offsets[0], object.attachmentPaths);
  writer.writeString(offsets[1], object.category);
  writer.writeString(offsets[2], object.colorHex);
  writer.writeDateTime(offsets[3], object.createdAt);
  writer.writeString(offsets[4], object.description);
  writer.writeDateTime(offsets[5], object.endTime);
  writer.writeBool(offsets[6], object.isAllDay);
  writer.writeBool(offsets[7], object.isSynced);
  writer.writeString(offsets[8], object.location);
  writer.writeString(offsets[9], object.recurrenceRule);
  writer.writeByte(offsets[10], object.recurrenceType.index);
  writer.writeLongList(offsets[11], object.reminderMinutes);
  writer.writeDateTime(offsets[12], object.startTime);
  writer.writeString(offsets[13], object.timeZone);
  writer.writeString(offsets[14], object.title);
  writer.writeDateTime(offsets[15], object.updatedAt);
  writer.writeLong(offsets[16], object.userId);
}

CalendarEventModel _calendarEventModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CalendarEventModel();
  object.attachmentPaths = reader.readStringList(offsets[0]) ?? [];
  object.category = reader.readStringOrNull(offsets[1]);
  object.colorHex = reader.readStringOrNull(offsets[2]);
  object.createdAt = reader.readDateTime(offsets[3]);
  object.description = reader.readStringOrNull(offsets[4]);
  object.endTime = reader.readDateTime(offsets[5]);
  object.id = id;
  object.isAllDay = reader.readBool(offsets[6]);
  object.isSynced = reader.readBool(offsets[7]);
  object.location = reader.readStringOrNull(offsets[8]);
  object.recurrenceRule = reader.readStringOrNull(offsets[9]);
  object.recurrenceType = _CalendarEventModelrecurrenceTypeValueEnumMap[
          reader.readByteOrNull(offsets[10])] ??
      RecurrenceType.none;
  object.reminderMinutes = reader.readLongList(offsets[11]) ?? [];
  object.startTime = reader.readDateTime(offsets[12]);
  object.timeZone = reader.readString(offsets[13]);
  object.title = reader.readString(offsets[14]);
  object.updatedAt = reader.readDateTime(offsets[15]);
  object.userId = reader.readLong(offsets[16]);
  return object;
}

P _calendarEventModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringList(offset) ?? []) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readDateTime(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readDateTime(offset)) as P;
    case 6:
      return (reader.readBool(offset)) as P;
    case 7:
      return (reader.readBool(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readStringOrNull(offset)) as P;
    case 10:
      return (_CalendarEventModelrecurrenceTypeValueEnumMap[
              reader.readByteOrNull(offset)] ??
          RecurrenceType.none) as P;
    case 11:
      return (reader.readLongList(offset) ?? []) as P;
    case 12:
      return (reader.readDateTime(offset)) as P;
    case 13:
      return (reader.readString(offset)) as P;
    case 14:
      return (reader.readString(offset)) as P;
    case 15:
      return (reader.readDateTime(offset)) as P;
    case 16:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _CalendarEventModelrecurrenceTypeEnumValueMap = {
  'none': 0,
  'daily': 1,
  'weekly': 2,
  'monthly': 3,
  'yearly': 4,
  'custom': 5,
};
const _CalendarEventModelrecurrenceTypeValueEnumMap = {
  0: RecurrenceType.none,
  1: RecurrenceType.daily,
  2: RecurrenceType.weekly,
  3: RecurrenceType.monthly,
  4: RecurrenceType.yearly,
  5: RecurrenceType.custom,
};

Id _calendarEventModelGetId(CalendarEventModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _calendarEventModelGetLinks(
    CalendarEventModel object) {
  return [];
}

void _calendarEventModelAttach(
    IsarCollection<dynamic> col, Id id, CalendarEventModel object) {
  object.id = id;
}

extension CalendarEventModelQueryWhereSort
    on QueryBuilder<CalendarEventModel, CalendarEventModel, QWhere> {
  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterWhere>
      anyUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'userId'),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterWhere>
      anyStartTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'startTime'),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterWhere>
      anyEndTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'endTime'),
      );
    });
  }
}

extension CalendarEventModelQueryWhere
    on QueryBuilder<CalendarEventModel, CalendarEventModel, QWhereClause> {
  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterWhereClause>
      idNotEqualTo(Id id) {
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

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterWhereClause>
      idBetween(
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

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterWhereClause>
      userIdEqualTo(int userId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'userId',
        value: [userId],
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterWhereClause>
      userIdNotEqualTo(int userId) {
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

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterWhereClause>
      userIdGreaterThan(
    int userId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'userId',
        lower: [userId],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterWhereClause>
      userIdLessThan(
    int userId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'userId',
        lower: [],
        upper: [userId],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterWhereClause>
      userIdBetween(
    int lowerUserId,
    int upperUserId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'userId',
        lower: [lowerUserId],
        includeLower: includeLower,
        upper: [upperUserId],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterWhereClause>
      startTimeEqualTo(DateTime startTime) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'startTime',
        value: [startTime],
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterWhereClause>
      startTimeNotEqualTo(DateTime startTime) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'startTime',
              lower: [],
              upper: [startTime],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'startTime',
              lower: [startTime],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'startTime',
              lower: [startTime],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'startTime',
              lower: [],
              upper: [startTime],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterWhereClause>
      startTimeGreaterThan(
    DateTime startTime, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'startTime',
        lower: [startTime],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterWhereClause>
      startTimeLessThan(
    DateTime startTime, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'startTime',
        lower: [],
        upper: [startTime],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterWhereClause>
      startTimeBetween(
    DateTime lowerStartTime,
    DateTime upperStartTime, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'startTime',
        lower: [lowerStartTime],
        includeLower: includeLower,
        upper: [upperStartTime],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterWhereClause>
      endTimeEqualTo(DateTime endTime) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'endTime',
        value: [endTime],
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterWhereClause>
      endTimeNotEqualTo(DateTime endTime) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'endTime',
              lower: [],
              upper: [endTime],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'endTime',
              lower: [endTime],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'endTime',
              lower: [endTime],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'endTime',
              lower: [],
              upper: [endTime],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterWhereClause>
      endTimeGreaterThan(
    DateTime endTime, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'endTime',
        lower: [endTime],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterWhereClause>
      endTimeLessThan(
    DateTime endTime, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'endTime',
        lower: [],
        upper: [endTime],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterWhereClause>
      endTimeBetween(
    DateTime lowerEndTime,
    DateTime upperEndTime, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'endTime',
        lower: [lowerEndTime],
        includeLower: includeLower,
        upper: [upperEndTime],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension CalendarEventModelQueryFilter
    on QueryBuilder<CalendarEventModel, CalendarEventModel, QFilterCondition> {
  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      attachmentPathsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'attachmentPaths',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      attachmentPathsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'attachmentPaths',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      attachmentPathsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'attachmentPaths',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      attachmentPathsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'attachmentPaths',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      attachmentPathsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'attachmentPaths',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      attachmentPathsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'attachmentPaths',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      attachmentPathsElementContains(String value,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'attachmentPaths',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      attachmentPathsElementMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'attachmentPaths',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      attachmentPathsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'attachmentPaths',
        value: '',
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      attachmentPathsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'attachmentPaths',
        value: '',
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      attachmentPathsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'attachmentPaths',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      attachmentPathsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'attachmentPaths',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      attachmentPathsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'attachmentPaths',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      attachmentPathsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'attachmentPaths',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      attachmentPathsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'attachmentPaths',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      attachmentPathsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'attachmentPaths',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      categoryIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'category',
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      categoryIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'category',
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
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

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
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

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
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

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
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

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
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

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
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

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      categoryContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      categoryMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'category',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      categoryIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'category',
        value: '',
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      categoryIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'category',
        value: '',
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      colorHexIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'colorHex',
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      colorHexIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'colorHex',
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      colorHexEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'colorHex',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      colorHexGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'colorHex',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      colorHexLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'colorHex',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      colorHexBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'colorHex',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      colorHexStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'colorHex',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      colorHexEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'colorHex',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      colorHexContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'colorHex',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      colorHexMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'colorHex',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      colorHexIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'colorHex',
        value: '',
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      colorHexIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'colorHex',
        value: '',
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
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

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
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

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
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

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      descriptionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'description',
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      descriptionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'description',
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      descriptionEqualTo(
    String? value, {
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

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      descriptionGreaterThan(
    String? value, {
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

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      descriptionLessThan(
    String? value, {
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

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      descriptionBetween(
    String? lower,
    String? upper, {
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

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
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

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
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

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      descriptionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      descriptionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'description',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      descriptionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      descriptionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      endTimeEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'endTime',
        value: value,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      endTimeGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'endTime',
        value: value,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      endTimeLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'endTime',
        value: value,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      endTimeBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'endTime',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
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

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
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

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      idBetween(
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

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      isAllDayEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isAllDay',
        value: value,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      isSyncedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isSynced',
        value: value,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      locationIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'location',
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      locationIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'location',
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      locationEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'location',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      locationGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'location',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      locationLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'location',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      locationBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'location',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      locationStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'location',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      locationEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'location',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      locationContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'location',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      locationMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'location',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      locationIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'location',
        value: '',
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      locationIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'location',
        value: '',
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      recurrenceRuleIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'recurrenceRule',
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      recurrenceRuleIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'recurrenceRule',
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      recurrenceRuleEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'recurrenceRule',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      recurrenceRuleGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'recurrenceRule',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      recurrenceRuleLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'recurrenceRule',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      recurrenceRuleBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'recurrenceRule',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      recurrenceRuleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'recurrenceRule',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      recurrenceRuleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'recurrenceRule',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      recurrenceRuleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'recurrenceRule',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      recurrenceRuleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'recurrenceRule',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      recurrenceRuleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'recurrenceRule',
        value: '',
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      recurrenceRuleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'recurrenceRule',
        value: '',
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      recurrenceTypeEqualTo(RecurrenceType value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'recurrenceType',
        value: value,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      recurrenceTypeGreaterThan(
    RecurrenceType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'recurrenceType',
        value: value,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      recurrenceTypeLessThan(
    RecurrenceType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'recurrenceType',
        value: value,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      recurrenceTypeBetween(
    RecurrenceType lower,
    RecurrenceType upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'recurrenceType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      reminderMinutesElementEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'reminderMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      reminderMinutesElementGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'reminderMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      reminderMinutesElementLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'reminderMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      reminderMinutesElementBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'reminderMinutes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      reminderMinutesLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'reminderMinutes',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      reminderMinutesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'reminderMinutes',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      reminderMinutesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'reminderMinutes',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      reminderMinutesLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'reminderMinutes',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      reminderMinutesLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'reminderMinutes',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      reminderMinutesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'reminderMinutes',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      startTimeEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'startTime',
        value: value,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      startTimeGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'startTime',
        value: value,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      startTimeLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'startTime',
        value: value,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      startTimeBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'startTime',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      timeZoneEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'timeZone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      timeZoneGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'timeZone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      timeZoneLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'timeZone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      timeZoneBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'timeZone',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      timeZoneStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'timeZone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      timeZoneEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'timeZone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      timeZoneContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'timeZone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      timeZoneMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'timeZone',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      timeZoneIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'timeZone',
        value: '',
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      timeZoneIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'timeZone',
        value: '',
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      titleEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      titleGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      titleLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      titleBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'title',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      titleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      titleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      titleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      titleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'title',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
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

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
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

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
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

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      userIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userId',
        value: value,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      userIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'userId',
        value: value,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      userIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'userId',
        value: value,
      ));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
      userIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'userId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension CalendarEventModelQueryObject
    on QueryBuilder<CalendarEventModel, CalendarEventModel, QFilterCondition> {}

extension CalendarEventModelQueryLinks
    on QueryBuilder<CalendarEventModel, CalendarEventModel, QFilterCondition> {}

extension CalendarEventModelQuerySortBy
    on QueryBuilder<CalendarEventModel, CalendarEventModel, QSortBy> {
  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
      sortByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.asc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
      sortByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.desc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
      sortByColorHex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorHex', Sort.asc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
      sortByColorHexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorHex', Sort.desc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
      sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
      sortByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
      sortByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
      sortByEndTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endTime', Sort.asc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
      sortByEndTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endTime', Sort.desc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
      sortByIsAllDay() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isAllDay', Sort.asc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
      sortByIsAllDayDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isAllDay', Sort.desc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
      sortByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
      sortByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
      sortByLocation() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'location', Sort.asc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
      sortByLocationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'location', Sort.desc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
      sortByRecurrenceRule() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recurrenceRule', Sort.asc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
      sortByRecurrenceRuleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recurrenceRule', Sort.desc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
      sortByRecurrenceType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recurrenceType', Sort.asc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
      sortByRecurrenceTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recurrenceType', Sort.desc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
      sortByStartTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startTime', Sort.asc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
      sortByStartTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startTime', Sort.desc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
      sortByTimeZone() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timeZone', Sort.asc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
      sortByTimeZoneDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timeZone', Sort.desc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
      sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
      sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
      sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
      sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
      sortByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
      sortByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }
}

extension CalendarEventModelQuerySortThenBy
    on QueryBuilder<CalendarEventModel, CalendarEventModel, QSortThenBy> {
  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
      thenByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.asc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
      thenByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.desc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
      thenByColorHex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorHex', Sort.asc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
      thenByColorHexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorHex', Sort.desc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
      thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
      thenByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
      thenByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
      thenByEndTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endTime', Sort.asc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
      thenByEndTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endTime', Sort.desc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
      thenByIsAllDay() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isAllDay', Sort.asc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
      thenByIsAllDayDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isAllDay', Sort.desc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
      thenByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
      thenByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
      thenByLocation() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'location', Sort.asc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
      thenByLocationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'location', Sort.desc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
      thenByRecurrenceRule() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recurrenceRule', Sort.asc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
      thenByRecurrenceRuleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recurrenceRule', Sort.desc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
      thenByRecurrenceType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recurrenceType', Sort.asc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
      thenByRecurrenceTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recurrenceType', Sort.desc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
      thenByStartTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startTime', Sort.asc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
      thenByStartTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startTime', Sort.desc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
      thenByTimeZone() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timeZone', Sort.asc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
      thenByTimeZoneDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timeZone', Sort.desc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
      thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
      thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
      thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
      thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
      thenByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
      thenByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }
}

extension CalendarEventModelQueryWhereDistinct
    on QueryBuilder<CalendarEventModel, CalendarEventModel, QDistinct> {
  QueryBuilder<CalendarEventModel, CalendarEventModel, QDistinct>
      distinctByAttachmentPaths() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'attachmentPaths');
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QDistinct>
      distinctByCategory({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'category', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QDistinct>
      distinctByColorHex({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'colorHex', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QDistinct>
      distinctByDescription({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'description', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QDistinct>
      distinctByEndTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'endTime');
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QDistinct>
      distinctByIsAllDay() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isAllDay');
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QDistinct>
      distinctByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isSynced');
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QDistinct>
      distinctByLocation({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'location', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QDistinct>
      distinctByRecurrenceRule({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'recurrenceRule',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QDistinct>
      distinctByRecurrenceType() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'recurrenceType');
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QDistinct>
      distinctByReminderMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'reminderMinutes');
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QDistinct>
      distinctByStartTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'startTime');
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QDistinct>
      distinctByTimeZone({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'timeZone', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QDistinct>
      distinctByTitle({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QDistinct>
      distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QDistinct>
      distinctByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'userId');
    });
  }
}

extension CalendarEventModelQueryProperty
    on QueryBuilder<CalendarEventModel, CalendarEventModel, QQueryProperty> {
  QueryBuilder<CalendarEventModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<CalendarEventModel, List<String>, QQueryOperations>
      attachmentPathsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'attachmentPaths');
    });
  }

  QueryBuilder<CalendarEventModel, String?, QQueryOperations>
      categoryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'category');
    });
  }

  QueryBuilder<CalendarEventModel, String?, QQueryOperations>
      colorHexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'colorHex');
    });
  }

  QueryBuilder<CalendarEventModel, DateTime, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<CalendarEventModel, String?, QQueryOperations>
      descriptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'description');
    });
  }

  QueryBuilder<CalendarEventModel, DateTime, QQueryOperations>
      endTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'endTime');
    });
  }

  QueryBuilder<CalendarEventModel, bool, QQueryOperations> isAllDayProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isAllDay');
    });
  }

  QueryBuilder<CalendarEventModel, bool, QQueryOperations> isSyncedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isSynced');
    });
  }

  QueryBuilder<CalendarEventModel, String?, QQueryOperations>
      locationProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'location');
    });
  }

  QueryBuilder<CalendarEventModel, String?, QQueryOperations>
      recurrenceRuleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'recurrenceRule');
    });
  }

  QueryBuilder<CalendarEventModel, RecurrenceType, QQueryOperations>
      recurrenceTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'recurrenceType');
    });
  }

  QueryBuilder<CalendarEventModel, List<int>, QQueryOperations>
      reminderMinutesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'reminderMinutes');
    });
  }

  QueryBuilder<CalendarEventModel, DateTime, QQueryOperations>
      startTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'startTime');
    });
  }

  QueryBuilder<CalendarEventModel, String, QQueryOperations>
      timeZoneProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'timeZone');
    });
  }

  QueryBuilder<CalendarEventModel, String, QQueryOperations> titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }

  QueryBuilder<CalendarEventModel, DateTime, QQueryOperations>
      updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }

  QueryBuilder<CalendarEventModel, int, QQueryOperations> userIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'userId');
    });
  }
}
