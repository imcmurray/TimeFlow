/// Domain model for a cron job imported from CSV.
class CronJob {
  final String id;
  final String host;
  final String command;
  final DateTime startTime;
  final DateTime? endTime;
  final String user;
  final String category;
  final int duration;
  final String? schedule;
  final String os;
  final String importBatchId;
  final DateTime importedAt;

  const CronJob({
    required this.id,
    required this.host,
    required this.command,
    required this.startTime,
    this.endTime,
    required this.user,
    this.category = 'uncategorized',
    this.duration = 0,
    this.schedule,
    this.os = 'linux',
    required this.importBatchId,
    required this.importedAt,
  });

  /// Returns [endTime] if set, otherwise [startTime] + [duration] seconds.
  /// If both are zero/null, returns [startTime].
  DateTime get effectiveEndTime {
    if (endTime != null) return endTime!;
    if (duration > 0) return startTime.add(Duration(seconds: duration));
    return startTime;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'host': host,
    'command': command,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'user': user,
    'category': category,
    'duration': duration,
    'schedule': schedule,
    'os': os,
    'importBatchId': importBatchId,
    'importedAt': importedAt.toIso8601String(),
  };

  factory CronJob.fromJson(Map<String, dynamic> json) => CronJob(
    id: json['id'] as String,
    host: json['host'] as String,
    command: json['command'] as String,
    startTime: DateTime.parse(json['startTime'] as String),
    endTime: json['endTime'] != null
        ? DateTime.parse(json['endTime'] as String)
        : null,
    user: json['user'] as String,
    category: json['category'] as String? ?? 'uncategorized',
    duration: json['duration'] as int? ?? 0,
    schedule: json['schedule'] as String?,
    os: json['os'] as String? ?? 'linux',
    importBatchId: json['importBatchId'] as String,
    importedAt: DateTime.parse(json['importedAt'] as String),
  );

  CronJob copyWith({
    String? id,
    String? host,
    String? command,
    DateTime? startTime,
    DateTime? endTime,
    String? user,
    String? category,
    int? duration,
    String? schedule,
    String? os,
    String? importBatchId,
    DateTime? importedAt,
  }) {
    return CronJob(
      id: id ?? this.id,
      host: host ?? this.host,
      command: command ?? this.command,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      user: user ?? this.user,
      category: category ?? this.category,
      duration: duration ?? this.duration,
      schedule: schedule ?? this.schedule,
      os: os ?? this.os,
      importBatchId: importBatchId ?? this.importBatchId,
      importedAt: importedAt ?? this.importedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CronJob && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'CronJob(id: $id, host: $host, command: $command, startTime: $startTime)';
}
