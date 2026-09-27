// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_settings_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetAISettingsModelCollection on Isar {
  IsarCollection<AISettingsModel> get aISettingsModels => this.collection();
}

const AISettingsModelSchema = CollectionSchema(
  name: r'AISettingsModel',
  id: 1675267832554544509,
  properties: {
    r'allowAttachmentsAccess': PropertySchema(
      id: 0,
      name: r'allowAttachmentsAccess',
      type: IsarType.bool,
    ),
    r'allowMoneyAccess': PropertySchema(
      id: 1,
      name: r'allowMoneyAccess',
      type: IsarType.bool,
    ),
    r'allowNotesAccess': PropertySchema(
      id: 2,
      name: r'allowNotesAccess',
      type: IsarType.bool,
    ),
    r'allowPostsAccess': PropertySchema(
      id: 3,
      name: r'allowPostsAccess',
      type: IsarType.bool,
    ),
    r'apiKey': PropertySchema(
      id: 4,
      name: r'apiKey',
      type: IsarType.string,
    ),
    r'isEnabled': PropertySchema(
      id: 5,
      name: r'isEnabled',
      type: IsarType.bool,
    ),
    r'moneyAnalysisEnabled': PropertySchema(
      id: 6,
      name: r'moneyAnalysisEnabled',
      type: IsarType.bool,
    ),
    r'noteAssistanceEnabled': PropertySchema(
      id: 7,
      name: r'noteAssistanceEnabled',
      type: IsarType.bool,
    ),
    r'postReactionsEnabled': PropertySchema(
      id: 8,
      name: r'postReactionsEnabled',
      type: IsarType.bool,
    ),
    r'provider': PropertySchema(
      id: 9,
      name: r'provider',
      type: IsarType.string,
    ),
    r'selectedModel': PropertySchema(
      id: 10,
      name: r'selectedModel',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 11,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
    r'userId': PropertySchema(
      id: 12,
      name: r'userId',
      type: IsarType.long,
    )
  },
  estimateSize: _aISettingsModelEstimateSize,
  serialize: _aISettingsModelSerialize,
  deserialize: _aISettingsModelDeserialize,
  deserializeProp: _aISettingsModelDeserializeProp,
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
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _aISettingsModelGetId,
  getLinks: _aISettingsModelGetLinks,
  attach: _aISettingsModelAttach,
  version: '3.1.0+1',
);

int _aISettingsModelEstimateSize(
  AISettingsModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.apiKey.length * 3;
  bytesCount += 3 + object.provider.length * 3;
  bytesCount += 3 + object.selectedModel.length * 3;
  return bytesCount;
}

void _aISettingsModelSerialize(
  AISettingsModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.allowAttachmentsAccess);
  writer.writeBool(offsets[1], object.allowMoneyAccess);
  writer.writeBool(offsets[2], object.allowNotesAccess);
  writer.writeBool(offsets[3], object.allowPostsAccess);
  writer.writeString(offsets[4], object.apiKey);
  writer.writeBool(offsets[5], object.isEnabled);
  writer.writeBool(offsets[6], object.moneyAnalysisEnabled);
  writer.writeBool(offsets[7], object.noteAssistanceEnabled);
  writer.writeBool(offsets[8], object.postReactionsEnabled);
  writer.writeString(offsets[9], object.provider);
  writer.writeString(offsets[10], object.selectedModel);
  writer.writeDateTime(offsets[11], object.updatedAt);
  writer.writeLong(offsets[12], object.userId);
}

AISettingsModel _aISettingsModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = AISettingsModel();
  object.allowAttachmentsAccess = reader.readBool(offsets[0]);
  object.allowMoneyAccess = reader.readBool(offsets[1]);
  object.allowNotesAccess = reader.readBool(offsets[2]);
  object.allowPostsAccess = reader.readBool(offsets[3]);
  object.apiKey = reader.readString(offsets[4]);
  object.id = id;
  object.isEnabled = reader.readBool(offsets[5]);
  object.moneyAnalysisEnabled = reader.readBool(offsets[6]);
  object.noteAssistanceEnabled = reader.readBool(offsets[7]);
  object.postReactionsEnabled = reader.readBool(offsets[8]);
  object.provider = reader.readString(offsets[9]);
  object.selectedModel = reader.readString(offsets[10]);
  object.updatedAt = reader.readDateTime(offsets[11]);
  object.userId = reader.readLong(offsets[12]);
  return object;
}

P _aISettingsModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readBool(offset)) as P;
    case 1:
      return (reader.readBool(offset)) as P;
    case 2:
      return (reader.readBool(offset)) as P;
    case 3:
      return (reader.readBool(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readBool(offset)) as P;
    case 6:
      return (reader.readBool(offset)) as P;
    case 7:
      return (reader.readBool(offset)) as P;
    case 8:
      return (reader.readBool(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readString(offset)) as P;
    case 11:
      return (reader.readDateTime(offset)) as P;
    case 12:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _aISettingsModelGetId(AISettingsModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _aISettingsModelGetLinks(AISettingsModel object) {
  return [];
}

void _aISettingsModelAttach(
    IsarCollection<dynamic> col, Id id, AISettingsModel object) {
  object.id = id;
}

extension AISettingsModelQueryWhereSort
    on QueryBuilder<AISettingsModel, AISettingsModel, QWhere> {
  QueryBuilder<AISettingsModel, AISettingsModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterWhere> anyUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'userId'),
      );
    });
  }
}

extension AISettingsModelQueryWhere
    on QueryBuilder<AISettingsModel, AISettingsModel, QWhereClause> {
  QueryBuilder<AISettingsModel, AISettingsModel, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterWhereClause>
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

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterWhereClause> idBetween(
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

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterWhereClause>
      userIdEqualTo(int userId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'userId',
        value: [userId],
      ));
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterWhereClause>
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

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterWhereClause>
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

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterWhereClause>
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

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterWhereClause>
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
}

extension AISettingsModelQueryFilter
    on QueryBuilder<AISettingsModel, AISettingsModel, QFilterCondition> {
  QueryBuilder<AISettingsModel, AISettingsModel, QAfterFilterCondition>
      allowAttachmentsAccessEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'allowAttachmentsAccess',
        value: value,
      ));
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterFilterCondition>
      allowMoneyAccessEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'allowMoneyAccess',
        value: value,
      ));
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterFilterCondition>
      allowNotesAccessEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'allowNotesAccess',
        value: value,
      ));
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterFilterCondition>
      allowPostsAccessEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'allowPostsAccess',
        value: value,
      ));
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterFilterCondition>
      apiKeyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'apiKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterFilterCondition>
      apiKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'apiKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterFilterCondition>
      apiKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'apiKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterFilterCondition>
      apiKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'apiKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterFilterCondition>
      apiKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'apiKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterFilterCondition>
      apiKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'apiKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterFilterCondition>
      apiKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'apiKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterFilterCondition>
      apiKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'apiKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterFilterCondition>
      apiKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'apiKey',
        value: '',
      ));
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterFilterCondition>
      apiKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'apiKey',
        value: '',
      ));
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterFilterCondition>
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

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterFilterCondition>
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

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterFilterCondition>
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

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterFilterCondition>
      isEnabledEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isEnabled',
        value: value,
      ));
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterFilterCondition>
      moneyAnalysisEnabledEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'moneyAnalysisEnabled',
        value: value,
      ));
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterFilterCondition>
      noteAssistanceEnabledEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'noteAssistanceEnabled',
        value: value,
      ));
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterFilterCondition>
      postReactionsEnabledEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'postReactionsEnabled',
        value: value,
      ));
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterFilterCondition>
      providerEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'provider',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterFilterCondition>
      providerGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'provider',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterFilterCondition>
      providerLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'provider',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterFilterCondition>
      providerBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'provider',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterFilterCondition>
      providerStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'provider',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterFilterCondition>
      providerEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'provider',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterFilterCondition>
      providerContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'provider',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterFilterCondition>
      providerMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'provider',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterFilterCondition>
      providerIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'provider',
        value: '',
      ));
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterFilterCondition>
      providerIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'provider',
        value: '',
      ));
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterFilterCondition>
      selectedModelEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'selectedModel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterFilterCondition>
      selectedModelGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'selectedModel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterFilterCondition>
      selectedModelLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'selectedModel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterFilterCondition>
      selectedModelBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'selectedModel',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterFilterCondition>
      selectedModelStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'selectedModel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterFilterCondition>
      selectedModelEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'selectedModel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterFilterCondition>
      selectedModelContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'selectedModel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterFilterCondition>
      selectedModelMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'selectedModel',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterFilterCondition>
      selectedModelIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'selectedModel',
        value: '',
      ));
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterFilterCondition>
      selectedModelIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'selectedModel',
        value: '',
      ));
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterFilterCondition>
      updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterFilterCondition>
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

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterFilterCondition>
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

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterFilterCondition>
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

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterFilterCondition>
      userIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userId',
        value: value,
      ));
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterFilterCondition>
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

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterFilterCondition>
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

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterFilterCondition>
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

extension AISettingsModelQueryObject
    on QueryBuilder<AISettingsModel, AISettingsModel, QFilterCondition> {}

extension AISettingsModelQueryLinks
    on QueryBuilder<AISettingsModel, AISettingsModel, QFilterCondition> {}

extension AISettingsModelQuerySortBy
    on QueryBuilder<AISettingsModel, AISettingsModel, QSortBy> {
  QueryBuilder<AISettingsModel, AISettingsModel, QAfterSortBy>
      sortByAllowAttachmentsAccess() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'allowAttachmentsAccess', Sort.asc);
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterSortBy>
      sortByAllowAttachmentsAccessDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'allowAttachmentsAccess', Sort.desc);
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterSortBy>
      sortByAllowMoneyAccess() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'allowMoneyAccess', Sort.asc);
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterSortBy>
      sortByAllowMoneyAccessDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'allowMoneyAccess', Sort.desc);
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterSortBy>
      sortByAllowNotesAccess() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'allowNotesAccess', Sort.asc);
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterSortBy>
      sortByAllowNotesAccessDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'allowNotesAccess', Sort.desc);
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterSortBy>
      sortByAllowPostsAccess() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'allowPostsAccess', Sort.asc);
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterSortBy>
      sortByAllowPostsAccessDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'allowPostsAccess', Sort.desc);
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterSortBy> sortByApiKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'apiKey', Sort.asc);
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterSortBy>
      sortByApiKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'apiKey', Sort.desc);
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterSortBy>
      sortByIsEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isEnabled', Sort.asc);
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterSortBy>
      sortByIsEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isEnabled', Sort.desc);
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterSortBy>
      sortByMoneyAnalysisEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'moneyAnalysisEnabled', Sort.asc);
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterSortBy>
      sortByMoneyAnalysisEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'moneyAnalysisEnabled', Sort.desc);
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterSortBy>
      sortByNoteAssistanceEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'noteAssistanceEnabled', Sort.asc);
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterSortBy>
      sortByNoteAssistanceEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'noteAssistanceEnabled', Sort.desc);
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterSortBy>
      sortByPostReactionsEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'postReactionsEnabled', Sort.asc);
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterSortBy>
      sortByPostReactionsEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'postReactionsEnabled', Sort.desc);
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterSortBy>
      sortByProvider() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'provider', Sort.asc);
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterSortBy>
      sortByProviderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'provider', Sort.desc);
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterSortBy>
      sortBySelectedModel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'selectedModel', Sort.asc);
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterSortBy>
      sortBySelectedModelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'selectedModel', Sort.desc);
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterSortBy>
      sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterSortBy>
      sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterSortBy> sortByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterSortBy>
      sortByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }
}

extension AISettingsModelQuerySortThenBy
    on QueryBuilder<AISettingsModel, AISettingsModel, QSortThenBy> {
  QueryBuilder<AISettingsModel, AISettingsModel, QAfterSortBy>
      thenByAllowAttachmentsAccess() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'allowAttachmentsAccess', Sort.asc);
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterSortBy>
      thenByAllowAttachmentsAccessDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'allowAttachmentsAccess', Sort.desc);
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterSortBy>
      thenByAllowMoneyAccess() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'allowMoneyAccess', Sort.asc);
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterSortBy>
      thenByAllowMoneyAccessDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'allowMoneyAccess', Sort.desc);
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterSortBy>
      thenByAllowNotesAccess() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'allowNotesAccess', Sort.asc);
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterSortBy>
      thenByAllowNotesAccessDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'allowNotesAccess', Sort.desc);
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterSortBy>
      thenByAllowPostsAccess() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'allowPostsAccess', Sort.asc);
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterSortBy>
      thenByAllowPostsAccessDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'allowPostsAccess', Sort.desc);
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterSortBy> thenByApiKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'apiKey', Sort.asc);
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterSortBy>
      thenByApiKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'apiKey', Sort.desc);
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterSortBy>
      thenByIsEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isEnabled', Sort.asc);
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterSortBy>
      thenByIsEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isEnabled', Sort.desc);
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterSortBy>
      thenByMoneyAnalysisEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'moneyAnalysisEnabled', Sort.asc);
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterSortBy>
      thenByMoneyAnalysisEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'moneyAnalysisEnabled', Sort.desc);
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterSortBy>
      thenByNoteAssistanceEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'noteAssistanceEnabled', Sort.asc);
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterSortBy>
      thenByNoteAssistanceEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'noteAssistanceEnabled', Sort.desc);
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterSortBy>
      thenByPostReactionsEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'postReactionsEnabled', Sort.asc);
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterSortBy>
      thenByPostReactionsEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'postReactionsEnabled', Sort.desc);
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterSortBy>
      thenByProvider() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'provider', Sort.asc);
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterSortBy>
      thenByProviderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'provider', Sort.desc);
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterSortBy>
      thenBySelectedModel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'selectedModel', Sort.asc);
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterSortBy>
      thenBySelectedModelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'selectedModel', Sort.desc);
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterSortBy>
      thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterSortBy>
      thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterSortBy> thenByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QAfterSortBy>
      thenByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }
}

extension AISettingsModelQueryWhereDistinct
    on QueryBuilder<AISettingsModel, AISettingsModel, QDistinct> {
  QueryBuilder<AISettingsModel, AISettingsModel, QDistinct>
      distinctByAllowAttachmentsAccess() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'allowAttachmentsAccess');
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QDistinct>
      distinctByAllowMoneyAccess() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'allowMoneyAccess');
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QDistinct>
      distinctByAllowNotesAccess() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'allowNotesAccess');
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QDistinct>
      distinctByAllowPostsAccess() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'allowPostsAccess');
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QDistinct> distinctByApiKey(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'apiKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QDistinct>
      distinctByIsEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isEnabled');
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QDistinct>
      distinctByMoneyAnalysisEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'moneyAnalysisEnabled');
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QDistinct>
      distinctByNoteAssistanceEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'noteAssistanceEnabled');
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QDistinct>
      distinctByPostReactionsEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'postReactionsEnabled');
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QDistinct> distinctByProvider(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'provider', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QDistinct>
      distinctBySelectedModel({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'selectedModel',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QDistinct>
      distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }

  QueryBuilder<AISettingsModel, AISettingsModel, QDistinct> distinctByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'userId');
    });
  }
}

extension AISettingsModelQueryProperty
    on QueryBuilder<AISettingsModel, AISettingsModel, QQueryProperty> {
  QueryBuilder<AISettingsModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<AISettingsModel, bool, QQueryOperations>
      allowAttachmentsAccessProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'allowAttachmentsAccess');
    });
  }

  QueryBuilder<AISettingsModel, bool, QQueryOperations>
      allowMoneyAccessProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'allowMoneyAccess');
    });
  }

  QueryBuilder<AISettingsModel, bool, QQueryOperations>
      allowNotesAccessProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'allowNotesAccess');
    });
  }

  QueryBuilder<AISettingsModel, bool, QQueryOperations>
      allowPostsAccessProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'allowPostsAccess');
    });
  }

  QueryBuilder<AISettingsModel, String, QQueryOperations> apiKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'apiKey');
    });
  }

  QueryBuilder<AISettingsModel, bool, QQueryOperations> isEnabledProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isEnabled');
    });
  }

  QueryBuilder<AISettingsModel, bool, QQueryOperations>
      moneyAnalysisEnabledProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'moneyAnalysisEnabled');
    });
  }

  QueryBuilder<AISettingsModel, bool, QQueryOperations>
      noteAssistanceEnabledProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'noteAssistanceEnabled');
    });
  }

  QueryBuilder<AISettingsModel, bool, QQueryOperations>
      postReactionsEnabledProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'postReactionsEnabled');
    });
  }

  QueryBuilder<AISettingsModel, String, QQueryOperations> providerProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'provider');
    });
  }

  QueryBuilder<AISettingsModel, String, QQueryOperations>
      selectedModelProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'selectedModel');
    });
  }

  QueryBuilder<AISettingsModel, DateTime, QQueryOperations>
      updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }

  QueryBuilder<AISettingsModel, int, QQueryOperations> userIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'userId');
    });
  }
}
