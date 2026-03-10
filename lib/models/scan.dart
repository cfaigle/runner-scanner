import 'package:hive/hive.dart';

part 'scan.g.dart';

@HiveType(typeId: 1)
class Scan extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String runnerId;

  @HiveField(2)
  String runnerName;

  @HiveField(3)
  DateTime timestamp;

  @HiveField(4)
  String? sessionId;

  Scan({
    required this.id,
    required this.runnerId,
    required this.runnerName,
    required this.timestamp,
    this.sessionId,
  });
  
  factory Scan.fromJson(Map<String, dynamic> json) {
    return Scan(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      runnerId: json['runner_guid'] ?? json['runner_id'] ?? '',
      runnerName: json['runner_name'] ?? 'Unknown',
      timestamp: json['scanned_at'] != null 
          ? DateTime.parse(json['scanned_at'])
          : DateTime.now(),
      sessionId: json['session_id'],
    );
  }

  String toExportString() {
    return '$runnerName,$timestamp';
  }

  @override
  String toString() {
    return 'Scan(id: $id, runnerId: $runnerId, runnerName: $runnerName, timestamp: $timestamp)';
  }
}
