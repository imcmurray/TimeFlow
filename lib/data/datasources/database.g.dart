// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $TasksTable extends Tasks with TableInfo<$TasksTable, Task> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _startTimeMeta =
      const VerificationMeta('startTime');
  @override
  late final GeneratedColumn<DateTime> startTime = GeneratedColumn<DateTime>(
      'start_time', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _endTimeMeta =
      const VerificationMeta('endTime');
  @override
  late final GeneratedColumn<DateTime> endTime = GeneratedColumn<DateTime>(
      'end_time', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _isImportantMeta =
      const VerificationMeta('isImportant');
  @override
  late final GeneratedColumn<bool> isImportant = GeneratedColumn<bool>(
      'is_important', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_important" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isCompletedMeta =
      const VerificationMeta('isCompleted');
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
      'is_completed', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_completed" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _reminderMinutesMeta =
      const VerificationMeta('reminderMinutes');
  @override
  late final GeneratedColumn<int> reminderMinutes = GeneratedColumn<int>(
      'reminder_minutes', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _recurringPatternMeta =
      const VerificationMeta('recurringPattern');
  @override
  late final GeneratedColumn<String> recurringPattern = GeneratedColumn<String>(
      'recurring_pattern', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _recurringTemplateIdMeta =
      const VerificationMeta('recurringTemplateId');
  @override
  late final GeneratedColumn<String> recurringTemplateId =
      GeneratedColumn<String>('recurring_template_id', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _attachmentPathMeta =
      const VerificationMeta('attachmentPath');
  @override
  late final GeneratedColumn<String> attachmentPath = GeneratedColumn<String>(
      'attachment_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
      'color', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        title,
        description,
        startTime,
        endTime,
        isImportant,
        isCompleted,
        reminderMinutes,
        recurringPattern,
        recurringTemplateId,
        notes,
        attachmentPath,
        color,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks';
  @override
  VerificationContext validateIntegrity(Insertable<Task> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('start_time')) {
      context.handle(_startTimeMeta,
          startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta));
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('end_time')) {
      context.handle(_endTimeMeta,
          endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta));
    } else if (isInserting) {
      context.missing(_endTimeMeta);
    }
    if (data.containsKey('is_important')) {
      context.handle(
          _isImportantMeta,
          isImportant.isAcceptableOrUnknown(
              data['is_important']!, _isImportantMeta));
    }
    if (data.containsKey('is_completed')) {
      context.handle(
          _isCompletedMeta,
          isCompleted.isAcceptableOrUnknown(
              data['is_completed']!, _isCompletedMeta));
    }
    if (data.containsKey('reminder_minutes')) {
      context.handle(
          _reminderMinutesMeta,
          reminderMinutes.isAcceptableOrUnknown(
              data['reminder_minutes']!, _reminderMinutesMeta));
    }
    if (data.containsKey('recurring_pattern')) {
      context.handle(
          _recurringPatternMeta,
          recurringPattern.isAcceptableOrUnknown(
              data['recurring_pattern']!, _recurringPatternMeta));
    }
    if (data.containsKey('recurring_template_id')) {
      context.handle(
          _recurringTemplateIdMeta,
          recurringTemplateId.isAcceptableOrUnknown(
              data['recurring_template_id']!, _recurringTemplateIdMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('attachment_path')) {
      context.handle(
          _attachmentPathMeta,
          attachmentPath.isAcceptableOrUnknown(
              data['attachment_path']!, _attachmentPathMeta));
    }
    if (data.containsKey('color')) {
      context.handle(
          _colorMeta, color.isAcceptableOrUnknown(data['color']!, _colorMeta));
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Task map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Task(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      startTime: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}start_time'])!,
      endTime: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}end_time'])!,
      isImportant: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_important'])!,
      isCompleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_completed'])!,
      reminderMinutes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}reminder_minutes']),
      recurringPattern: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}recurring_pattern']),
      recurringTemplateId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}recurring_template_id']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      attachmentPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}attachment_path']),
      color: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}color']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $TasksTable createAlias(String alias) {
    return $TasksTable(attachedDatabase, alias);
  }
}

class Task extends DataClass implements Insertable<Task> {
  final String id;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final bool isImportant;
  final bool isCompleted;
  final int? reminderMinutes;
  final String? recurringPattern;
  final String? recurringTemplateId;
  final String? notes;
  final String? attachmentPath;
  final String? color;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Task(
      {required this.id,
      required this.title,
      this.description,
      required this.startTime,
      required this.endTime,
      required this.isImportant,
      required this.isCompleted,
      this.reminderMinutes,
      this.recurringPattern,
      this.recurringTemplateId,
      this.notes,
      this.attachmentPath,
      this.color,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['start_time'] = Variable<DateTime>(startTime);
    map['end_time'] = Variable<DateTime>(endTime);
    map['is_important'] = Variable<bool>(isImportant);
    map['is_completed'] = Variable<bool>(isCompleted);
    if (!nullToAbsent || reminderMinutes != null) {
      map['reminder_minutes'] = Variable<int>(reminderMinutes);
    }
    if (!nullToAbsent || recurringPattern != null) {
      map['recurring_pattern'] = Variable<String>(recurringPattern);
    }
    if (!nullToAbsent || recurringTemplateId != null) {
      map['recurring_template_id'] = Variable<String>(recurringTemplateId);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || attachmentPath != null) {
      map['attachment_path'] = Variable<String>(attachmentPath);
    }
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TasksCompanion toCompanion(bool nullToAbsent) {
    return TasksCompanion(
      id: Value(id),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      startTime: Value(startTime),
      endTime: Value(endTime),
      isImportant: Value(isImportant),
      isCompleted: Value(isCompleted),
      reminderMinutes: reminderMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderMinutes),
      recurringPattern: recurringPattern == null && nullToAbsent
          ? const Value.absent()
          : Value(recurringPattern),
      recurringTemplateId: recurringTemplateId == null && nullToAbsent
          ? const Value.absent()
          : Value(recurringTemplateId),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      attachmentPath: attachmentPath == null && nullToAbsent
          ? const Value.absent()
          : Value(attachmentPath),
      color:
          color == null && nullToAbsent ? const Value.absent() : Value(color),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Task.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Task(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      startTime: serializer.fromJson<DateTime>(json['startTime']),
      endTime: serializer.fromJson<DateTime>(json['endTime']),
      isImportant: serializer.fromJson<bool>(json['isImportant']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
      reminderMinutes: serializer.fromJson<int?>(json['reminderMinutes']),
      recurringPattern: serializer.fromJson<String?>(json['recurringPattern']),
      recurringTemplateId:
          serializer.fromJson<String?>(json['recurringTemplateId']),
      notes: serializer.fromJson<String?>(json['notes']),
      attachmentPath: serializer.fromJson<String?>(json['attachmentPath']),
      color: serializer.fromJson<String?>(json['color']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'startTime': serializer.toJson<DateTime>(startTime),
      'endTime': serializer.toJson<DateTime>(endTime),
      'isImportant': serializer.toJson<bool>(isImportant),
      'isCompleted': serializer.toJson<bool>(isCompleted),
      'reminderMinutes': serializer.toJson<int?>(reminderMinutes),
      'recurringPattern': serializer.toJson<String?>(recurringPattern),
      'recurringTemplateId': serializer.toJson<String?>(recurringTemplateId),
      'notes': serializer.toJson<String?>(notes),
      'attachmentPath': serializer.toJson<String?>(attachmentPath),
      'color': serializer.toJson<String?>(color),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Task copyWith(
          {String? id,
          String? title,
          Value<String?> description = const Value.absent(),
          DateTime? startTime,
          DateTime? endTime,
          bool? isImportant,
          bool? isCompleted,
          Value<int?> reminderMinutes = const Value.absent(),
          Value<String?> recurringPattern = const Value.absent(),
          Value<String?> recurringTemplateId = const Value.absent(),
          Value<String?> notes = const Value.absent(),
          Value<String?> attachmentPath = const Value.absent(),
          Value<String?> color = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      Task(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description.present ? description.value : this.description,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        isImportant: isImportant ?? this.isImportant,
        isCompleted: isCompleted ?? this.isCompleted,
        reminderMinutes: reminderMinutes.present
            ? reminderMinutes.value
            : this.reminderMinutes,
        recurringPattern: recurringPattern.present
            ? recurringPattern.value
            : this.recurringPattern,
        recurringTemplateId: recurringTemplateId.present
            ? recurringTemplateId.value
            : this.recurringTemplateId,
        notes: notes.present ? notes.value : this.notes,
        attachmentPath:
            attachmentPath.present ? attachmentPath.value : this.attachmentPath,
        color: color.present ? color.value : this.color,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Task copyWithCompanion(TasksCompanion data) {
    return Task(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      description:
          data.description.present ? data.description.value : this.description,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      isImportant:
          data.isImportant.present ? data.isImportant.value : this.isImportant,
      isCompleted:
          data.isCompleted.present ? data.isCompleted.value : this.isCompleted,
      reminderMinutes: data.reminderMinutes.present
          ? data.reminderMinutes.value
          : this.reminderMinutes,
      recurringPattern: data.recurringPattern.present
          ? data.recurringPattern.value
          : this.recurringPattern,
      recurringTemplateId: data.recurringTemplateId.present
          ? data.recurringTemplateId.value
          : this.recurringTemplateId,
      notes: data.notes.present ? data.notes.value : this.notes,
      attachmentPath: data.attachmentPath.present
          ? data.attachmentPath.value
          : this.attachmentPath,
      color: data.color.present ? data.color.value : this.color,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Task(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('isImportant: $isImportant, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('reminderMinutes: $reminderMinutes, ')
          ..write('recurringPattern: $recurringPattern, ')
          ..write('recurringTemplateId: $recurringTemplateId, ')
          ..write('notes: $notes, ')
          ..write('attachmentPath: $attachmentPath, ')
          ..write('color: $color, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      title,
      description,
      startTime,
      endTime,
      isImportant,
      isCompleted,
      reminderMinutes,
      recurringPattern,
      recurringTemplateId,
      notes,
      attachmentPath,
      color,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Task &&
          other.id == this.id &&
          other.title == this.title &&
          other.description == this.description &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.isImportant == this.isImportant &&
          other.isCompleted == this.isCompleted &&
          other.reminderMinutes == this.reminderMinutes &&
          other.recurringPattern == this.recurringPattern &&
          other.recurringTemplateId == this.recurringTemplateId &&
          other.notes == this.notes &&
          other.attachmentPath == this.attachmentPath &&
          other.color == this.color &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TasksCompanion extends UpdateCompanion<Task> {
  final Value<String> id;
  final Value<String> title;
  final Value<String?> description;
  final Value<DateTime> startTime;
  final Value<DateTime> endTime;
  final Value<bool> isImportant;
  final Value<bool> isCompleted;
  final Value<int?> reminderMinutes;
  final Value<String?> recurringPattern;
  final Value<String?> recurringTemplateId;
  final Value<String?> notes;
  final Value<String?> attachmentPath;
  final Value<String?> color;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const TasksCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.isImportant = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.reminderMinutes = const Value.absent(),
    this.recurringPattern = const Value.absent(),
    this.recurringTemplateId = const Value.absent(),
    this.notes = const Value.absent(),
    this.attachmentPath = const Value.absent(),
    this.color = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TasksCompanion.insert({
    required String id,
    required String title,
    this.description = const Value.absent(),
    required DateTime startTime,
    required DateTime endTime,
    this.isImportant = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.reminderMinutes = const Value.absent(),
    this.recurringPattern = const Value.absent(),
    this.recurringTemplateId = const Value.absent(),
    this.notes = const Value.absent(),
    this.attachmentPath = const Value.absent(),
    this.color = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        title = Value(title),
        startTime = Value(startTime),
        endTime = Value(endTime),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<Task> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? description,
    Expression<DateTime>? startTime,
    Expression<DateTime>? endTime,
    Expression<bool>? isImportant,
    Expression<bool>? isCompleted,
    Expression<int>? reminderMinutes,
    Expression<String>? recurringPattern,
    Expression<String>? recurringTemplateId,
    Expression<String>? notes,
    Expression<String>? attachmentPath,
    Expression<String>? color,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (isImportant != null) 'is_important': isImportant,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (reminderMinutes != null) 'reminder_minutes': reminderMinutes,
      if (recurringPattern != null) 'recurring_pattern': recurringPattern,
      if (recurringTemplateId != null)
        'recurring_template_id': recurringTemplateId,
      if (notes != null) 'notes': notes,
      if (attachmentPath != null) 'attachment_path': attachmentPath,
      if (color != null) 'color': color,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TasksCompanion copyWith(
      {Value<String>? id,
      Value<String>? title,
      Value<String?>? description,
      Value<DateTime>? startTime,
      Value<DateTime>? endTime,
      Value<bool>? isImportant,
      Value<bool>? isCompleted,
      Value<int?>? reminderMinutes,
      Value<String?>? recurringPattern,
      Value<String?>? recurringTemplateId,
      Value<String?>? notes,
      Value<String?>? attachmentPath,
      Value<String?>? color,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return TasksCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isImportant: isImportant ?? this.isImportant,
      isCompleted: isCompleted ?? this.isCompleted,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      recurringPattern: recurringPattern ?? this.recurringPattern,
      recurringTemplateId: recurringTemplateId ?? this.recurringTemplateId,
      notes: notes ?? this.notes,
      attachmentPath: attachmentPath ?? this.attachmentPath,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<DateTime>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<DateTime>(endTime.value);
    }
    if (isImportant.present) {
      map['is_important'] = Variable<bool>(isImportant.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (reminderMinutes.present) {
      map['reminder_minutes'] = Variable<int>(reminderMinutes.value);
    }
    if (recurringPattern.present) {
      map['recurring_pattern'] = Variable<String>(recurringPattern.value);
    }
    if (recurringTemplateId.present) {
      map['recurring_template_id'] =
          Variable<String>(recurringTemplateId.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (attachmentPath.present) {
      map['attachment_path'] = Variable<String>(attachmentPath.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TasksCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('isImportant: $isImportant, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('reminderMinutes: $reminderMinutes, ')
          ..write('recurringPattern: $recurringPattern, ')
          ..write('recurringTemplateId: $recurringTemplateId, ')
          ..write('notes: $notes, ')
          ..write('attachmentPath: $attachmentPath, ')
          ..write('color: $color, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TasksTable tasks = $TasksTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [tasks];
}

typedef $$TasksTableCreateCompanionBuilder = TasksCompanion Function({
  required String id,
  required String title,
  Value<String?> description,
  required DateTime startTime,
  required DateTime endTime,
  Value<bool> isImportant,
  Value<bool> isCompleted,
  Value<int?> reminderMinutes,
  Value<String?> recurringPattern,
  Value<String?> recurringTemplateId,
  Value<String?> notes,
  Value<String?> attachmentPath,
  Value<String?> color,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$TasksTableUpdateCompanionBuilder = TasksCompanion Function({
  Value<String> id,
  Value<String> title,
  Value<String?> description,
  Value<DateTime> startTime,
  Value<DateTime> endTime,
  Value<bool> isImportant,
  Value<bool> isCompleted,
  Value<int?> reminderMinutes,
  Value<String?> recurringPattern,
  Value<String?> recurringTemplateId,
  Value<String?> notes,
  Value<String?> attachmentPath,
  Value<String?> color,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$TasksTableFilterComposer extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get endTime => $composableBuilder(
      column: $table.endTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isImportant => $composableBuilder(
      column: $table.isImportant, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isCompleted => $composableBuilder(
      column: $table.isCompleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get reminderMinutes => $composableBuilder(
      column: $table.reminderMinutes,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get recurringPattern => $composableBuilder(
      column: $table.recurringPattern,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get recurringTemplateId => $composableBuilder(
      column: $table.recurringTemplateId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get attachmentPath => $composableBuilder(
      column: $table.attachmentPath,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$TasksTableOrderingComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get endTime => $composableBuilder(
      column: $table.endTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isImportant => $composableBuilder(
      column: $table.isImportant, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
      column: $table.isCompleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get reminderMinutes => $composableBuilder(
      column: $table.reminderMinutes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get recurringPattern => $composableBuilder(
      column: $table.recurringPattern,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get recurringTemplateId => $composableBuilder(
      column: $table.recurringTemplateId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get attachmentPath => $composableBuilder(
      column: $table.attachmentPath,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$TasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<DateTime> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<DateTime> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<bool> get isImportant => $composableBuilder(
      column: $table.isImportant, builder: (column) => column);

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
      column: $table.isCompleted, builder: (column) => column);

  GeneratedColumn<int> get reminderMinutes => $composableBuilder(
      column: $table.reminderMinutes, builder: (column) => column);

  GeneratedColumn<String> get recurringPattern => $composableBuilder(
      column: $table.recurringPattern, builder: (column) => column);

  GeneratedColumn<String> get recurringTemplateId => $composableBuilder(
      column: $table.recurringTemplateId, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get attachmentPath => $composableBuilder(
      column: $table.attachmentPath, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$TasksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TasksTable,
    Task,
    $$TasksTableFilterComposer,
    $$TasksTableOrderingComposer,
    $$TasksTableAnnotationComposer,
    $$TasksTableCreateCompanionBuilder,
    $$TasksTableUpdateCompanionBuilder,
    (Task, BaseReferences<_$AppDatabase, $TasksTable, Task>),
    Task,
    PrefetchHooks Function()> {
  $$TasksTableTableManager(_$AppDatabase db, $TasksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<DateTime> startTime = const Value.absent(),
            Value<DateTime> endTime = const Value.absent(),
            Value<bool> isImportant = const Value.absent(),
            Value<bool> isCompleted = const Value.absent(),
            Value<int?> reminderMinutes = const Value.absent(),
            Value<String?> recurringPattern = const Value.absent(),
            Value<String?> recurringTemplateId = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<String?> attachmentPath = const Value.absent(),
            Value<String?> color = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TasksCompanion(
            id: id,
            title: title,
            description: description,
            startTime: startTime,
            endTime: endTime,
            isImportant: isImportant,
            isCompleted: isCompleted,
            reminderMinutes: reminderMinutes,
            recurringPattern: recurringPattern,
            recurringTemplateId: recurringTemplateId,
            notes: notes,
            attachmentPath: attachmentPath,
            color: color,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String title,
            Value<String?> description = const Value.absent(),
            required DateTime startTime,
            required DateTime endTime,
            Value<bool> isImportant = const Value.absent(),
            Value<bool> isCompleted = const Value.absent(),
            Value<int?> reminderMinutes = const Value.absent(),
            Value<String?> recurringPattern = const Value.absent(),
            Value<String?> recurringTemplateId = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<String?> attachmentPath = const Value.absent(),
            Value<String?> color = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              TasksCompanion.insert(
            id: id,
            title: title,
            description: description,
            startTime: startTime,
            endTime: endTime,
            isImportant: isImportant,
            isCompleted: isCompleted,
            reminderMinutes: reminderMinutes,
            recurringPattern: recurringPattern,
            recurringTemplateId: recurringTemplateId,
            notes: notes,
            attachmentPath: attachmentPath,
            color: color,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TasksTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TasksTable,
    Task,
    $$TasksTableFilterComposer,
    $$TasksTableOrderingComposer,
    $$TasksTableAnnotationComposer,
    $$TasksTableCreateCompanionBuilder,
    $$TasksTableUpdateCompanionBuilder,
    (Task, BaseReferences<_$AppDatabase, $TasksTable, Task>),
    Task,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db, _db.tasks);
}
