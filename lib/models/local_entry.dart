import 'package:hive_flutter/hive_flutter.dart';

part 'local_entry.g.dart';

@HiveType(typeId: 5)
class LocalEntry extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String raceId;

  @HiveField(2)
  String runnerName;

  @HiveField(3)
  String runnerGuid;

  @HiveField(4)
  String? sex;

  @HiveField(5)
  DateTime? dateOfBirth;

  @HiveField(6)
  int? bibNumber;

  @HiveField(7)
  DateTime createdAt;

  LocalEntry({
    required this.id,
    required this.raceId,
    required this.runnerName,
    required this.runnerGuid,
    this.sex,
    this.dateOfBirth,
    this.bibNumber,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get runnerGuidShort {
    if (runnerGuid.length <= 8) return runnerGuid;
    return runnerGuid.substring(0, 8);
  }

  LocalEntry copyWith({
    String? id,
    String? raceId,
    String? runnerName,
    String? runnerGuid,
    String? sex,
    DateTime? dateOfBirth,
    int? bibNumber,
    DateTime? createdAt,
  }) {
    return LocalEntry(
      id: id ?? this.id,
      raceId: raceId ?? this.raceId,
      runnerName: runnerName ?? this.runnerName,
      runnerGuid: runnerGuid ?? this.runnerGuid,
      sex: sex ?? this.sex,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      bibNumber: bibNumber ?? this.bibNumber,
      createdAt: createdAt ?? DateTime.now(),
    );
  }
}
