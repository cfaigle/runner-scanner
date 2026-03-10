import 'package:hive_flutter/hive_flutter.dart';

part 'local_race.g.dart';

@HiveType(typeId: 4)
class LocalRace extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? description;

  @HiveField(3)
  DateTime raceDate;

  @HiveField(4)
  String status; // draft, active, completed

  @HiveField(5)
  DateTime? startTime;

  @HiveField(6)
  DateTime? endTime;

  @HiveField(7)
  int entryCount;

  @HiveField(8)
  int scanCount;

  @HiveField(9)
  DateTime createdAt;

  @HiveField(10)
  DateTime updatedAt;

  LocalRace({
    required this.id,
    required this.name,
    this.description,
    required this.raceDate,
    this.status = 'draft',
    this.startTime,
    this.endTime,
    this.entryCount = 0,
    this.scanCount = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  bool get isDraft => status == 'draft';
  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';

  Duration? get raceDuration {
    if (startTime == null || endTime == null) return null;
    return endTime!.difference(startTime!);
  }

  LocalRace copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? raceDate,
    String? status,
    DateTime? startTime,
    DateTime? endTime,
    int? entryCount,
    int? scanCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LocalRace(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      raceDate: raceDate ?? this.raceDate,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      entryCount: entryCount ?? this.entryCount,
      scanCount: scanCount ?? this.scanCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'race_date': raceDate.toIso8601String(),
      'status': status,
      'start_time': startTime?.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'entry_count': entryCount,
      'scan_count': scanCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory LocalRace.fromJson(Map<String, dynamic> json) {
    return LocalRace(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      raceDate: DateTime.parse(json['race_date']),
      status: json['status'] ?? 'draft',
      startTime: json['start_time'] != null ? DateTime.parse(json['start_time']) : null,
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      entryCount: json['entry_count'] ?? 0,
      scanCount: json['scan_count'] ?? 0,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
    );
  }
}
